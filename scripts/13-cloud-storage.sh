#!/usr/bin/env bash
#
# 13-cloud-storage.sh - Cloud storage integration
#

set -euo pipefail

readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

log_info() { echo -e "${GREEN}[CLOUD]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[CLOUD]${NC} $*"; }

BACKUP_PROVIDER="${BACKUP_PROVIDER:-s3}"

install_rclone() {
    log_info "Installing rclone..."

    if ! command -v rclone &> /dev/null; then
        curl https://rclone.org/install.sh | bash
    fi

    log_info "rclone installed"
}

create_rclone_config_template() {
    log_info "Creating rclone configuration template..."

    mkdir -p /root/.config/rclone

    cat > /root/rclone-setup.txt << 'EOF'
To configure rclone for cloud backups:

1. Run: rclone config
2. Follow the prompts to add your cloud storage provider
3. Common providers:
   - Amazon S3
   - Backblaze B2
   - DigitalOcean Spaces
   - Google Drive
   - Microsoft OneDrive

4. Test connection: rclone lsd remote:

5. Update backup script at /usr/local/bin/server-backup
   to include: rclone sync /opt/backups remote:backups

For detailed setup: https://rclone.org/docs/
EOF

    log_info "Configuration guide created at /root/rclone-setup.txt"
}

create_sync_script() {
    log_info "Creating cloud sync script..."

    cat > /usr/local/bin/backup-to-cloud << 'EOF'
#!/bin/bash
set -euo pipefail

# Configure your rclone remote name
REMOTE_NAME="remote"
LOCAL_BACKUP="/opt/backups"
REMOTE_PATH="${REMOTE_NAME}:server-backups"

echo "Syncing backups to cloud..."

if ! command -v rclone &> /dev/null; then
    echo "Error: rclone not installed"
    exit 1
fi

# Check if remote is configured
if ! rclone listremotes | grep -q "^${REMOTE_NAME}:$"; then
    echo "Error: Remote '$REMOTE_NAME' not configured"
    echo "Run: rclone config"
    exit 1
fi

# Sync to cloud
rclone sync "$LOCAL_BACKUP" "$REMOTE_PATH" \
    --transfers 4 \
    --checkers 8 \
    --contimeout 60s \
    --timeout 300s \
    --retries 3 \
    --low-level-retries 10 \
    --stats 1s

echo "Cloud sync complete"
EOF

    chmod +x /usr/local/bin/backup-to-cloud

    log_info "Cloud sync script created"
}

main() {
    log_info "Setting up cloud storage integration..."
    echo ""

    if [[ "${ENABLE_BACKUPS}" != "yes" ]]; then
        log_warn "Backups not enabled, skipping cloud storage setup"
        return 0
    fi

    install_rclone
    create_rclone_config_template
    create_sync_script

    echo ""
    log_info "Cloud storage setup complete!"
    log_warn "Manual configuration required - see /root/rclone-setup.txt"

    return 0
}

main "$@"
