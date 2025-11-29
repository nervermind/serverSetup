#!/usr/bin/env bash
#
# backup.sh - Comprehensive backup utility
#
# Creates full system backup including:
# - Docker volumes and containers
# - System configurations
# - Application data
#

set -euo pipefail

readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

log_info() { echo -e "${GREEN}[BACKUP]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[BACKUP]${NC} $*"; }
log_error() { echo -e "${RED}[BACKUP]${NC} $*"; }

BACKUP_DIR="${BACKUP_DIR:-/opt/backups}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_NAME="backup-${TIMESTAMP}"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"

create_backup_dir() {
    log_info "Creating backup directory: $BACKUP_PATH"
    mkdir -p "$BACKUP_PATH"
}

backup_docker_volumes() {
    log_info "Backing up Docker volumes..."

    if ! command -v docker &> /dev/null; then
        log_warn "Docker not installed, skipping"
        return 0
    fi

    mkdir -p "${BACKUP_PATH}/docker"

    # Get list of all volumes
    volumes=$(docker volume ls -q)

    for volume in $volumes; do
        log_info "Backing up volume: $volume"
        docker run --rm \
            -v "${volume}:/volume:ro" \
            -v "${BACKUP_PATH}/docker:/backup" \
            alpine \
            tar czf "/backup/${volume}.tar.gz" -C /volume .
    done

    log_info "Docker volumes backed up"
}

backup_docker_configs() {
    log_info "Backing up Docker configurations..."

    mkdir -p "${BACKUP_PATH}/docker-config"

    # Backup docker configs
    if [[ -d /etc/docker ]]; then
        tar czf "${BACKUP_PATH}/docker-config/etc-docker.tar.gz" -C /etc docker
    fi

    # Backup compose files
    find /opt -name "docker-compose.yml" -o -name "docker-compose.yaml" | \
        tar czf "${BACKUP_PATH}/docker-config/compose-files.tar.gz" -T - 2>/dev/null || true

    log_info "Docker configurations backed up"
}

backup_system_configs() {
    log_info "Backing up system configurations..."

    mkdir -p "${BACKUP_PATH}/system"

    # List of important system configs
    local configs=(
        "/etc/ssh"
        "/etc/nginx"
        "/etc/fail2ban"
        "/etc/audit"
        "/opt/traefik"
    )

    for config in "${configs[@]}"; do
        if [[ -d "$config" ]]; then
            local name=$(basename "$config")
            tar czf "${BACKUP_PATH}/system/${name}.tar.gz" -C "$(dirname "$config")" "$name" 2>/dev/null || true
        fi
    done

    log_info "System configurations backed up"
}

backup_user_data() {
    log_info "Backing up user data..."

    mkdir -p "${BACKUP_PATH}/users"

    # Backup admin user home
    if [[ -n "${ADMIN_USERNAME:-}" ]] && [[ -d "/home/${ADMIN_USERNAME}" ]]; then
        tar czf "${BACKUP_PATH}/users/${ADMIN_USERNAME}.tar.gz" \
            -C "/home" "${ADMIN_USERNAME}" 2>/dev/null || true
    fi

    # Backup root home (selective)
    tar czf "${BACKUP_PATH}/users/root-selective.tar.gz" \
        -C /root \
        .ssh \
        .bashrc \
        .profile \
        2>/dev/null || true

    log_info "User data backed up"
}

backup_databases() {
    log_info "Backing up databases..."

    mkdir -p "${BACKUP_PATH}/databases"

    # Check for running database containers
    if docker ps --format '{{.Names}}' | grep -qE '(mysql|postgres|mongo)'; then
        log_info "Database containers found, creating dumps..."

        # MySQL/MariaDB
        for container in $(docker ps --format '{{.Names}}' | grep -i mysql); do
            docker exec "$container" \
                sh -c 'mysqldump --all-databases -u root -p"$MYSQL_ROOT_PASSWORD"' \
                > "${BACKUP_PATH}/databases/${container}.sql" 2>/dev/null || \
                log_warn "Failed to backup MySQL container: $container"
        done

        # PostgreSQL
        for container in $(docker ps --format '{{.Names}}' | grep -i postgres); do
            docker exec "$container" \
                sh -c 'pg_dumpall -U postgres' \
                > "${BACKUP_PATH}/databases/${container}.sql" 2>/dev/null || \
                log_warn "Failed to backup PostgreSQL container: $container"
        done
    fi

    log_info "Database backups complete"
}

create_backup_manifest() {
    log_info "Creating backup manifest..."

    cat > "${BACKUP_PATH}/manifest.txt" << EOF
Backup Manifest
===============

Backup Name: ${BACKUP_NAME}
Created: $(date)
Hostname: $(hostname)
IP Address: $(hostname -I | awk '{print $1}')

Contents:
---------
$(find "$BACKUP_PATH" -type f -exec ls -lh {} \; | awk '{print $9, $5}')

Total Size: $(du -sh "$BACKUP_PATH" | awk '{print $1}')
EOF

    log_info "Manifest created"
}

compress_backup() {
    log_info "Compressing backup..."

    cd "$BACKUP_DIR"
    tar czf "${BACKUP_NAME}.tar.gz" "$BACKUP_NAME"

    # Remove uncompressed backup
    rm -rf "$BACKUP_NAME"

    log_info "Backup compressed: ${BACKUP_NAME}.tar.gz"
}

upload_to_cloud() {
    if command -v rclone &> /dev/null; then
        log_info "Uploading to cloud storage..."

        if rclone listremotes | grep -q "remote:"; then
            rclone copy "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" remote:server-backups/ || \
                log_warn "Cloud upload failed"
        else
            log_warn "No rclone remote configured, skipping cloud upload"
        fi
    fi
}

cleanup_old_backups() {
    log_info "Cleaning up old backups (keeping last 7 days)..."

    find "$BACKUP_DIR" -name "backup-*.tar.gz" -mtime +7 -delete

    log_info "Cleanup complete"
}

main() {
    echo ""
    log_info "═══════════════════════════════════════════════════════"
    log_info "  STARTING BACKUP: $BACKUP_NAME"
    log_info "═══════════════════════════════════════════════════════"
    echo ""

    create_backup_dir
    backup_docker_volumes
    backup_docker_configs
    backup_system_configs
    backup_user_data
    backup_databases
    create_backup_manifest
    compress_backup
    upload_to_cloud
    cleanup_old_backups

    echo ""
    log_info "═══════════════════════════════════════════════════════"
    log_info "  BACKUP COMPLETE!"
    log_info "═══════════════════════════════════════════════════════"
    echo ""
    log_info "Backup saved to: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
    log_info "Size: $(du -h "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" | awk '{print $1}')"
    echo ""

    return 0
}

main "$@"
