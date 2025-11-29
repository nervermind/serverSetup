#!/usr/bin/env bash
#
# restore.sh - System restoration utility
#
# Restores system from backup created by backup.sh
#

set -euo pipefail

readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

log_info() { echo -e "${GREEN}[RESTORE]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[RESTORE]${NC} $*"; }
log_error() { echo -e "${RED}[RESTORE]${NC} $*"; }

BACKUP_FILE="${1:-}"
RESTORE_DIR="/tmp/restore-$$"

show_usage() {
    cat << EOF
Usage: $0 <backup-file.tar.gz>

Restores system from a backup archive.

Example:
    $0 /opt/backups/backup-20250126-120000.tar.gz

Available backups:
EOF
    ls -lh /opt/backups/backup-*.tar.gz 2>/dev/null || echo "  No backups found"
}

validate_backup() {
    if [[ -z "$BACKUP_FILE" ]]; then
        log_error "No backup file specified"
        show_usage
        exit 1
    fi

    if [[ ! -f "$BACKUP_FILE" ]]; then
        log_error "Backup file not found: $BACKUP_FILE"
        exit 1
    fi

    log_info "Backup file: $BACKUP_FILE"
}

confirm_restore() {
    log_warn "═══════════════════════════════════════════════════════"
    log_warn "  WARNING: This will restore system from backup"
    log_warn "  Current configuration will be overwritten!"
    log_warn "═══════════════════════════════════════════════════════"
    echo ""

    read -p "Are you sure you want to continue? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        log_info "Restore cancelled"
        exit 0
    fi
}

extract_backup() {
    log_info "Extracting backup..."

    mkdir -p "$RESTORE_DIR"
    tar xzf "$BACKUP_FILE" -C "$RESTORE_DIR"

    # Find the backup directory
    BACKUP_NAME=$(basename "$BACKUP_FILE" .tar.gz)
    BACKUP_PATH="${RESTORE_DIR}/${BACKUP_NAME}"

    if [[ ! -d "$BACKUP_PATH" ]]; then
        log_error "Invalid backup structure"
        exit 1
    fi

    log_info "Backup extracted to: $RESTORE_DIR"
}

restore_system_configs() {
    log_info "Restoring system configurations..."

    if [[ -d "${BACKUP_PATH}/system" ]]; then
        for archive in "${BACKUP_PATH}/system"/*.tar.gz; do
            if [[ -f "$archive" ]]; then
                log_info "Restoring: $(basename "$archive")"
                tar xzf "$archive" -C /etc/ 2>/dev/null || log_warn "Failed to restore $(basename "$archive")"
            fi
        done
    fi

    log_info "System configurations restored"
}

restore_docker_volumes() {
    log_info "Restoring Docker volumes..."

    if [[ ! -d "${BACKUP_PATH}/docker" ]]; then
        log_warn "No Docker volumes found in backup"
        return 0
    fi

    for archive in "${BACKUP_PATH}/docker"/*.tar.gz; do
        if [[ -f "$archive" ]]; then
            volume_name=$(basename "$archive" .tar.gz)
            log_info "Restoring volume: $volume_name"

            # Create volume if it doesn't exist
            docker volume create "$volume_name" 2>/dev/null || true

            # Restore data
            docker run --rm \
                -v "${volume_name}:/volume" \
                -v "$(dirname "$archive"):/backup:ro" \
                alpine \
                sh -c "rm -rf /volume/* && tar xzf /backup/$(basename "$archive") -C /volume"
        fi
    done

    log_info "Docker volumes restored"
}

restore_docker_configs() {
    log_info "Restoring Docker configurations..."

    if [[ -d "${BACKUP_PATH}/docker-config" ]]; then
        if [[ -f "${BACKUP_PATH}/docker-config/etc-docker.tar.gz" ]]; then
            tar xzf "${BACKUP_PATH}/docker-config/etc-docker.tar.gz" -C /etc/
        fi
    fi

    log_info "Docker configurations restored"
}

restore_databases() {
    log_info "Restoring databases..."

    if [[ ! -d "${BACKUP_PATH}/databases" ]]; then
        log_warn "No database backups found"
        return 0
    fi

    for sql_file in "${BACKUP_PATH}/databases"/*.sql; do
        if [[ -f "$sql_file" ]]; then
            container_name=$(basename "$sql_file" .sql)
            log_info "Restoring database: $container_name"

            # MySQL
            if docker ps --format '{{.Names}}' | grep -q "$container_name"; then
                if docker exec "$container_name" env | grep -q MYSQL; then
                    docker exec -i "$container_name" \
                        sh -c 'mysql -u root -p"$MYSQL_ROOT_PASSWORD"' \
                        < "$sql_file" 2>/dev/null || \
                        log_warn "Failed to restore MySQL: $container_name"
                fi

                # PostgreSQL
                if docker exec "$container_name" env | grep -q POSTGRES; then
                    docker exec -i "$container_name" \
                        sh -c 'psql -U postgres' \
                        < "$sql_file" 2>/dev/null || \
                        log_warn "Failed to restore PostgreSQL: $container_name"
                fi
            else
                log_warn "Container not running: $container_name"
            fi
        fi
    done

    log_info "Database restore complete"
}

restart_services() {
    log_info "Restarting services..."

    systemctl restart docker || true
    systemctl restart ssh || systemctl restart sshd || true
    systemctl restart fail2ban || true

    log_info "Services restarted"
}

cleanup() {
    log_info "Cleaning up temporary files..."
    rm -rf "$RESTORE_DIR"
    log_info "Cleanup complete"
}

main() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi

    validate_backup
    confirm_restore

    echo ""
    log_info "═══════════════════════════════════════════════════════"
    log_info "  STARTING RESTORE"
    log_info "═══════════════════════════════════════════════════════"
    echo ""

    extract_backup
    restore_system_configs
    restore_docker_configs
    restore_docker_volumes
    restore_databases
    restart_services
    cleanup

    echo ""
    log_info "═══════════════════════════════════════════════════════"
    log_info "  RESTORE COMPLETE!"
    log_info "═══════════════════════════════════════════════════════"
    echo ""
    log_warn "Please verify all services are working correctly"
    log_info "Check health: /opt/server-setup/scripts/15-healthcheck.sh"
    echo ""

    return 0
}

main "$@"
