#!/usr/bin/env bash
#
# 12-backups.sh - Backup system configuration
#

set -euo pipefail

readonly GREEN='\033[0;32m'
readonly NC='\033[0m'

log_info() { echo -e "${GREEN}[BACKUPS]${NC} $*"; }

BACKUP_DIR="${BACKUP_DIR:-/opt/backups}"

create_backup_structure() {
    log_info "Creating backup directory structure..."

    mkdir -p "$BACKUP_DIR"/{docker,system,databases}
    chmod 700 "$BACKUP_DIR"

    log_info "Backup directories created"
}

create_backup_script() {
    log_info "Creating backup script..."

    cat > /usr/local/bin/server-backup << 'EOFSCRIPT'
#!/bin/bash
set -euo pipefail

BACKUP_DIR="/opt/backups"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_NAME="backup-${TIMESTAMP}"

echo "Starting backup: $BACKUP_NAME"

# Backup Docker volumes
echo "Backing up Docker volumes..."
docker run --rm \
    -v /var/lib/docker/volumes:/volumes:ro \
    -v ${BACKUP_DIR}/docker:/backup \
    alpine tar czf /backup/${BACKUP_NAME}-docker-volumes.tar.gz -C /volumes .

# Backup system configs
echo "Backing up system configurations..."
tar czf ${BACKUP_DIR}/system/${BACKUP_NAME}-configs.tar.gz \
    /etc/ssh \
    /etc/nginx \
    /etc/docker \
    /opt/traefik \
    2>/dev/null || true

# Cleanup old backups (keep last 7 days)
find ${BACKUP_DIR} -type f -name "backup-*" -mtime +7 -delete

echo "Backup complete: $BACKUP_NAME"
EOFSCRIPT

    chmod +x /usr/local/bin/server-backup

    log_info "Backup script created"
}

create_cron_job() {
    log_info "Setting up automated backups..."

    # Daily backup at 2 AM
    (crontab -l 2>/dev/null || true; echo "0 2 * * * /usr/local/bin/server-backup >> /var/log/backups.log 2>&1") | crontab -

    log_info "Cron job created"
}

main() {
    log_info "Configuring backup system..."
    echo ""

    create_backup_structure
    create_backup_script
    create_cron_job

    echo ""
    log_info "Backup system configured!"
    log_info "Run manual backup: server-backup"

    return 0
}

main "$@"
