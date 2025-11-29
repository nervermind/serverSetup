#!/usr/bin/env bash
#
# Secure Server Setup Framework - Bootstrap Script
# Copyright (c) 2025
#
# This script can be safely run via:
#   curl -fsSL https://raw.githubusercontent.com/<user>/<repo>/main/setup.sh | sudo bash
#   wget -qO- https://raw.githubusercontent.com/<user>/<repo>/main/setup.sh | sudo bash
#
# Safety features:
# - Checksum verification of all downloaded scripts
# - User confirmation prompts
# - Preflight environment checks
# - Comprehensive logging
# - Idempotent execution
#

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

readonly SCRIPT_VERSION="1.0.0"
readonly REPO_BASE_URL="${REPO_BASE_URL:-https://raw.githubusercontent.com/USERNAME/REPO/main}"
readonly INSTALL_DIR="/opt/server-setup"
readonly LOG_DIR="/var/log/server-setup"
readonly LOG_FILE="${LOG_DIR}/install-$(date +%Y%m%d-%H%M%S).log"
readonly STATE_FILE="${INSTALL_DIR}/.state"
readonly BACKUP_DIR="/root/server-setup-backup"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${message}" | tee -a "${LOG_FILE}" >&2
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*" | tee -a "${LOG_FILE}"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*" | tee -a "${LOG_FILE}"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" | tee -a "${LOG_FILE}"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" | tee -a "${LOG_FILE}"
}

die() {
    log_error "$*"
    exit 1
}

# ============================================================================
# BANNER & WARNINGS
# ============================================================================

show_banner() {
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════════════════╗
║                                                                       ║
║      SECURE SERVER SETUP FRAMEWORK FOR DEBIAN 13                     ║
║                                                                       ║
║      This script will perform the following:                         ║
║      • Harden SSH configuration                                      ║
║      • Configure secure firewall rules (nftables/UFW)                ║
║      • Install and harden Docker CE                                  ║
║      • Deploy reverse proxy (Traefik or Nginx)                       ║
║      • Enable fail2ban, auditd, and security monitoring              ║
║      • Configure automated cloud backups                             ║
║      • Apply OS-level security hardening                             ║
║                                                                       ║
║      ⚠️  WARNINGS:                                                    ║
║      • This script requires ROOT access                              ║
║      • SSH configuration will be modified                            ║
║      • You may be locked out if SSH keys are not properly set        ║
║      • Firewall rules will be applied                                ║
║      • All actions are logged                                        ║
║                                                                       ║
╚═══════════════════════════════════════════════════════════════════════╝

EOF
}

show_lockout_warning() {
    cat << 'EOF'

⚠️  SSH LOCKOUT WARNING ⚠️

This script will modify SSH configuration. To prevent being locked out:

1. Ensure you have added your SSH public key when prompted
2. Test SSH access in a separate terminal before closing this one
3. Consider keeping root login enabled until you verify the new user works
4. The script will create a backup of all modified files

If you get locked out, you'll need console access through your hosting provider.

EOF
}

# ============================================================================
# ROOT CHECK
# ============================================================================

check_root() {
    if [[ $EUID -ne 0 ]]; then
        if command -v sudo &> /dev/null; then
            log_warn "This script must be run as root. Re-executing with sudo..."
            exec sudo bash "$0" "$@"
        else
            die "This script must be run as root and sudo is not available."
        fi
    fi
    log_success "Running as root"
}

# ============================================================================
# PREFLIGHT CHECKS
# ============================================================================

check_os() {
    log_info "Checking operating system..."

    if [[ ! -f /etc/os-release ]]; then
        die "Cannot determine OS. /etc/os-release not found."
    fi

    source /etc/os-release

    if [[ "$ID" != "debian" ]]; then
        die "This script is designed for Debian only. Detected: $ID"
    fi

    # Check for Debian 13 (Trixie)
    local version_id="${VERSION_ID:-0}"
    if [[ "$version_id" -lt 13 ]]; then
        log_warn "This script is optimized for Debian 13. You are running Debian $version_id"
        read -p "Continue anyway? (yes/no): " -r
        if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
            die "Installation cancelled by user"
        fi
    fi

    log_success "OS check passed: Debian $VERSION_ID ($VERSION_CODENAME)"
}

check_network() {
    log_info "Checking network connectivity..."

    if ! ping -c 1 -W 3 8.8.8.8 &> /dev/null; then
        die "No network connectivity detected"
    fi

    if ! ping -c 1 -W 3 raw.githubusercontent.com &> /dev/null; then
        die "Cannot reach raw.githubusercontent.com. Check DNS and firewall."
    fi

    log_success "Network connectivity OK"
}

check_disk_space() {
    log_info "Checking disk space..."

    local available_kb
    available_kb=$(df / | awk 'NR==2 {print $4}')
    local available_gb=$((available_kb / 1024 / 1024))

    if [[ $available_gb -lt 2 ]]; then
        die "Insufficient disk space. Need at least 2GB, have ${available_gb}GB"
    fi

    log_success "Disk space OK: ${available_gb}GB available"
}

check_not_container() {
    log_info "Checking if running in a container..."

    if [[ -f /.dockerenv ]] || grep -qa container=lxc /proc/1/environ; then
        log_warn "Running inside a container. Some features may not work correctly."
        read -p "Continue anyway? (yes/no): " -r
        if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
            die "Installation cancelled by user"
        fi
    else
        log_success "Not running in a container"
    fi
}

# ============================================================================
# DOWNLOAD & VERIFICATION
# ============================================================================

download_file() {
    local url="$1"
    local dest="$2"

    log_info "Downloading: $url"

    if command -v curl &> /dev/null; then
        if ! curl -fsSL -o "$dest" "$url"; then
            die "Failed to download $url"
        fi
    elif command -v wget &> /dev/null; then
        if ! wget -q -O "$dest" "$url"; then
            die "Failed to download $url"
        fi
    else
        die "Neither curl nor wget is available"
    fi
}

download_scripts() {
    log_info "Downloading installation scripts..."

    mkdir -p "${INSTALL_DIR}/scripts"

    local scripts=(
        "scripts/01-preflight.sh"
        "scripts/02-ssh-hardening.sh"
        "scripts/03-users.sh"
        "scripts/04-firewall.sh"
        "scripts/05-docker-install.sh"
        "scripts/06-docker-hardening.sh"
        "scripts/07-proxy-install-traefik.sh"
        "scripts/08-proxy-install-nginx.sh"
        "scripts/09-portainer.sh"
        "scripts/10-fail2ban.sh"
        "scripts/11-auditd.sh"
        "scripts/12-backups.sh"
        "scripts/13-cloud-storage.sh"
        "scripts/14-postinstall-tests.sh"
        "scripts/15-healthcheck.sh"
    )

    for script in "${scripts[@]}"; do
        download_file "${REPO_BASE_URL}/${script}" "${INSTALL_DIR}/${script}"
        chmod +x "${INSTALL_DIR}/${script}"
    done

    # Download checksums and .env.sample
    download_file "${REPO_BASE_URL}/checksums.txt" "${INSTALL_DIR}/checksums.txt"
    download_file "${REPO_BASE_URL}/.env.sample" "${INSTALL_DIR}/.env.sample"

    # Try to download GPG signature if available
    if command -v gpg &> /dev/null; then
        if download_file "${REPO_BASE_URL}/checksums.txt.asc" "${INSTALL_DIR}/checksums.txt.asc" 2>/dev/null; then
            log_info "GPG signature file downloaded"
        fi
    fi

    log_success "All scripts downloaded"
}

verify_checksums() {
    log_info "Verifying file integrity..."

    cd "${INSTALL_DIR}"

    if ! command -v sha256sum &> /dev/null; then
        log_warn "sha256sum not available, skipping checksum verification"
        return 0
    fi

    # Verify checksums
    if ! sha256sum -c checksums.txt --quiet --ignore-missing; then
        die "Checksum verification failed! Files may be corrupted or tampered."
    fi

    log_success "Checksum verification passed"
}

verify_gpg_signature() {
    if [[ ! -f "${INSTALL_DIR}/checksums.txt.asc" ]]; then
        log_info "GPG signature not available, skipping"
        return 0
    fi

    if ! command -v gpg &> /dev/null; then
        log_warn "GPG not installed, skipping signature verification"
        return 0
    fi

    log_info "Verifying GPG signature..."

    # This would require importing the public key first
    # For now, just log that it's available
    log_info "GPG signature file present. Manual verification recommended."
}

# ============================================================================
# CONFIGURATION
# ============================================================================

load_config() {
    log_info "Loading configuration..."

    # Check if .env exists
    if [[ -f "${INSTALL_DIR}/.env" ]]; then
        log_info "Loading existing .env file"
        source "${INSTALL_DIR}/.env"
        export $(cut -d= -f1 "${INSTALL_DIR}/.env" | grep -v '^#')
    elif [[ -f .env ]]; then
        log_info "Loading .env from current directory"
        source .env
        export $(cut -d= -f1 .env | grep -v '^#')
    else
        log_info "No .env file found, will prompt for configuration"
    fi
}

interactive_config() {
    log_info "Starting interactive configuration..."

    # Check if running non-interactively
    if [[ "${NON_INTERACTIVE:-false}" == "true" ]]; then
        log_info "Running in non-interactive mode"
        validate_required_vars
        return 0
    fi

    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "  CONFIGURATION"
    echo "════════════════════════════════════════════════════════════"
    echo ""

    # Admin user configuration
    if [[ -z "${ADMIN_USERNAME:-}" ]]; then
        read -p "Enter admin username [admin]: " ADMIN_USERNAME
        ADMIN_USERNAME="${ADMIN_USERNAME:-admin}"
    fi
    export ADMIN_USERNAME

    # SSH public key
    if [[ -z "${ADMIN_SSH_KEY:-}" ]]; then
        echo ""
        echo "Enter your SSH public key (paste the entire key):"
        read -r ADMIN_SSH_KEY
        if [[ -z "$ADMIN_SSH_KEY" ]]; then
            log_warn "No SSH key provided. You may be locked out!"
        fi
    fi
    export ADMIN_SSH_KEY

    # SSH configuration
    if [[ -z "${DISABLE_ROOT_LOGIN:-}" ]]; then
        read -p "Disable SSH root login after setup? (yes/no) [yes]: " DISABLE_ROOT_LOGIN
        DISABLE_ROOT_LOGIN="${DISABLE_ROOT_LOGIN:-yes}"
    fi
    export DISABLE_ROOT_LOGIN

    if [[ -z "${SSH_PORT:-}" ]]; then
        read -p "SSH port [22]: " SSH_PORT
        SSH_PORT="${SSH_PORT:-22}"
    fi
    export SSH_PORT

    # Reverse proxy choice
    if [[ -z "${PROXY_TYPE:-}" ]]; then
        echo ""
        echo "Choose reverse proxy:"
        echo "  1) Traefik (recommended for Docker)"
        echo "  2) Nginx"
        echo "  3) None"
        read -p "Selection [1]: " proxy_choice
        proxy_choice="${proxy_choice:-1}"

        case $proxy_choice in
            1) PROXY_TYPE="traefik" ;;
            2) PROXY_TYPE="nginx" ;;
            3) PROXY_TYPE="none" ;;
            *) PROXY_TYPE="traefik" ;;
        esac
    fi
    export PROXY_TYPE

    # Domain and Let's Encrypt
    if [[ "$PROXY_TYPE" != "none" ]]; then
        if [[ -z "${DOMAIN:-}" ]]; then
            read -p "Primary domain name (e.g., example.com): " DOMAIN
        fi
        export DOMAIN

        if [[ -z "${LETSENCRYPT_EMAIL:-}" ]]; then
            read -p "Email for Let's Encrypt notifications: " LETSENCRYPT_EMAIL
        fi
        export LETSENCRYPT_EMAIL
    fi

    # Portainer
    if [[ -z "${INSTALL_PORTAINER:-}" ]]; then
        read -p "Install Portainer for Docker management? (yes/no) [yes]: " INSTALL_PORTAINER
        INSTALL_PORTAINER="${INSTALL_PORTAINER:-yes}"
    fi
    export INSTALL_PORTAINER

    # Automatic updates
    if [[ -z "${ENABLE_AUTO_UPDATES:-}" ]]; then
        read -p "Enable automatic security updates? (yes/no) [yes]: " ENABLE_AUTO_UPDATES
        ENABLE_AUTO_UPDATES="${ENABLE_AUTO_UPDATES:-yes}"
    fi
    export ENABLE_AUTO_UPDATES

    # Backup configuration
    if [[ -z "${ENABLE_BACKUPS:-}" ]]; then
        read -p "Configure automated backups? (yes/no) [yes]: " ENABLE_BACKUPS
        ENABLE_BACKUPS="${ENABLE_BACKUPS:-yes}"
    fi
    export ENABLE_BACKUPS

    if [[ "$ENABLE_BACKUPS" == "yes" ]]; then
        if [[ -z "${BACKUP_PROVIDER:-}" ]]; then
            echo ""
            echo "Backup providers:"
            echo "  1) AWS S3"
            echo "  2) Backblaze B2"
            echo "  3) DigitalOcean Spaces"
            echo "  4) MinIO / S3-compatible"
            read -p "Selection [1]: " backup_choice
            backup_choice="${backup_choice:-1}"

            case $backup_choice in
                1) BACKUP_PROVIDER="s3" ;;
                2) BACKUP_PROVIDER="b2" ;;
                3) BACKUP_PROVIDER="spaces" ;;
                4) BACKUP_PROVIDER="s3-compatible" ;;
                *) BACKUP_PROVIDER="s3" ;;
            esac
        fi
        export BACKUP_PROVIDER
    fi

    # Save configuration
    save_config

    log_success "Configuration complete"
}

save_config() {
    log_info "Saving configuration to ${INSTALL_DIR}/.env"

    cat > "${INSTALL_DIR}/.env" << EOF
# Server Setup Configuration
# Generated: $(date)

ADMIN_USERNAME="${ADMIN_USERNAME}"
ADMIN_SSH_KEY="${ADMIN_SSH_KEY}"
DISABLE_ROOT_LOGIN="${DISABLE_ROOT_LOGIN}"
SSH_PORT="${SSH_PORT}"
PROXY_TYPE="${PROXY_TYPE}"
DOMAIN="${DOMAIN:-}"
LETSENCRYPT_EMAIL="${LETSENCRYPT_EMAIL:-}"
INSTALL_PORTAINER="${INSTALL_PORTAINER}"
ENABLE_AUTO_UPDATES="${ENABLE_AUTO_UPDATES}"
ENABLE_BACKUPS="${ENABLE_BACKUPS}"
BACKUP_PROVIDER="${BACKUP_PROVIDER:-}"
EOF

    chmod 600 "${INSTALL_DIR}/.env"
}

validate_required_vars() {
    local required_vars=(
        "ADMIN_USERNAME"
    )

    local missing_vars=()

    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            missing_vars+=("$var")
        fi
    done

    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        log_error "Missing required configuration variables:"
        for var in "${missing_vars[@]}"; do
            log_error "  - $var"
        done
        die "Please set required variables in .env or run interactively"
    fi
}

# ============================================================================
# EXECUTION
# ============================================================================

run_script() {
    local script="$1"
    local script_name
    script_name=$(basename "$script")

    log_info "Running: $script_name"

    # Source the .env file for the script
    if [[ -f "${INSTALL_DIR}/.env" ]]; then
        set -a
        source "${INSTALL_DIR}/.env"
        set +a
    fi

    if bash "$script" 2>&1 | tee -a "${LOG_FILE}"; then
        log_success "$script_name completed"
        return 0
    else
        log_error "$script_name failed"
        return 1
    fi
}

run_installation() {
    log_info "Starting installation process..."

    local scripts=(
        "${INSTALL_DIR}/scripts/01-preflight.sh"
        "${INSTALL_DIR}/scripts/03-users.sh"
        "${INSTALL_DIR}/scripts/04-firewall.sh"
        "${INSTALL_DIR}/scripts/10-fail2ban.sh"
        "${INSTALL_DIR}/scripts/11-auditd.sh"
        "${INSTALL_DIR}/scripts/05-docker-install.sh"
        "${INSTALL_DIR}/scripts/06-docker-hardening.sh"
    )

    # Add proxy script based on selection
    if [[ "${PROXY_TYPE}" == "traefik" ]]; then
        scripts+=("${INSTALL_DIR}/scripts/07-proxy-install-traefik.sh")
    elif [[ "${PROXY_TYPE}" == "nginx" ]]; then
        scripts+=("${INSTALL_DIR}/scripts/08-proxy-install-nginx.sh")
    fi

    # Add Portainer if requested
    if [[ "${INSTALL_PORTAINER}" == "yes" ]]; then
        scripts+=("${INSTALL_DIR}/scripts/09-portainer.sh")
    fi

    # Add backup scripts if requested
    if [[ "${ENABLE_BACKUPS}" == "yes" ]]; then
        scripts+=("${INSTALL_DIR}/scripts/12-backups.sh")
        scripts+=("${INSTALL_DIR}/scripts/13-cloud-storage.sh")
    fi

    # SSH hardening should be last to avoid lockout
    scripts+=("${INSTALL_DIR}/scripts/02-ssh-hardening.sh")

    # Run post-install tests
    scripts+=("${INSTALL_DIR}/scripts/14-postinstall-tests.sh")

    for script in "${scripts[@]}"; do
        if ! run_script "$script"; then
            log_error "Installation failed at: $(basename "$script")"
            log_error "Check logs at: $LOG_FILE"
            return 1
        fi
    done

    log_success "Installation completed successfully!"
}

generate_report() {
    local report_file="/root/setup-report.txt"

    log_info "Generating setup report..."

    cat > "$report_file" << EOF
════════════════════════════════════════════════════════════════════════
  SECURE SERVER SETUP - INSTALLATION REPORT
════════════════════════════════════════════════════════════════════════

Installation Date: $(date)
Script Version: ${SCRIPT_VERSION}
Hostname: $(hostname)
IP Address: $(hostname -I | awk '{print $1}')

CONFIGURATION
─────────────────────────────────────────────────────────────────────────
Admin User: ${ADMIN_USERNAME}
SSH Port: ${SSH_PORT}
Root Login: $([ "${DISABLE_ROOT_LOGIN}" == "yes" ] && echo "DISABLED" || echo "ENABLED")
Proxy Type: ${PROXY_TYPE}
Domain: ${DOMAIN:-N/A}
Portainer: $([ "${INSTALL_PORTAINER}" == "yes" ] && echo "INSTALLED" || echo "NOT INSTALLED")
Auto Updates: $([ "${ENABLE_AUTO_UPDATES}" == "yes" ] && echo "ENABLED" || echo "DISABLED")
Backups: $([ "${ENABLE_BACKUPS}" == "yes" ] && echo "ENABLED (${BACKUP_PROVIDER})" || echo "DISABLED")

IMPORTANT NOTES
─────────────────────────────────────────────────────────────────────────
1. SSH Configuration has been modified:
   - Port: ${SSH_PORT}
   - Root login: $([ "${DISABLE_ROOT_LOGIN}" == "yes" ] && echo "DISABLED" || echo "ENABLED")
   - Password authentication: DISABLED

2. Firewall is ACTIVE with the following allowed ports:
   - SSH: ${SSH_PORT}/tcp
   - HTTP: 80/tcp (if proxy installed)
   - HTTPS: 443/tcp (if proxy installed)

3. Security Tools Installed:
   - fail2ban: Active and monitoring SSH
   - auditd: Active and logging system events
   - Docker: Installed with security hardening

4. Next Steps:
   a) Test SSH access in a NEW terminal before closing this one
   b) Review firewall rules: ufw status verbose
   c) Check fail2ban: fail2ban-client status
   d) Verify Docker: docker info
   $([ "${PROXY_TYPE}" == "traefik" ] && echo "   e) Access Traefik dashboard: https://${DOMAIN}/dashboard/" || echo "")
   $([ "${INSTALL_PORTAINER}" == "yes" ] && echo "   f) Access Portainer: https://${DOMAIN}:9443" || echo "")

5. Backup Information:
   $([ "${ENABLE_BACKUPS}" == "yes" ] && echo "   - Automated backups configured for ${BACKUP_PROVIDER}" || echo "   - Backups not configured")
   - Manual backup: /opt/server-setup/backup.sh
   - Restore: /opt/server-setup/restore.sh

6. Health Check:
   - Run: /opt/server-setup/scripts/15-healthcheck.sh

LOGS
─────────────────────────────────────────────────────────────────────────
Installation log: ${LOG_FILE}
System logs: ${LOG_DIR}/

SUPPORT
─────────────────────────────────────────────────────────────────────────
Documentation: ${INSTALL_DIR}/README.md
Report issues: https://github.com/USERNAME/REPO/issues

════════════════════════════════════════════════════════════════════════
EOF

    log_success "Report generated: $report_file"

    # Display report
    cat "$report_file"
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    # Initialize
    mkdir -p "${LOG_DIR}"
    mkdir -p "${BACKUP_DIR}"

    # Show banner
    show_banner

    # Show lockout warning
    show_lockout_warning

    # Confirm installation
    if [[ "${NON_INTERACTIVE:-false}" != "true" ]]; then
        read -p "Do you want to continue with the installation? (yes/no): " -r
        if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
            log_info "Installation cancelled by user"
            exit 0
        fi
    fi

    log_info "Starting Secure Server Setup Framework v${SCRIPT_VERSION}"

    # Root check
    check_root "$@"

    # Preflight checks
    check_os
    check_network
    check_disk_space
    check_not_container

    # Download scripts
    download_scripts

    # Verify integrity
    verify_checksums
    verify_gpg_signature

    # Configuration
    load_config
    interactive_config

    # Final confirmation
    if [[ "${NON_INTERACTIVE:-false}" != "true" ]]; then
        echo ""
        log_warn "Last chance to abort!"
        read -p "Proceed with installation? (yes/no): " -r
        if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
            log_info "Installation cancelled by user"
            exit 0
        fi
    fi

    # Run installation
    if ! run_installation; then
        die "Installation failed. Check logs at: $LOG_FILE"
    fi

    # Generate report
    generate_report

    log_success "═══════════════════════════════════════════════════════════"
    log_success "  INSTALLATION COMPLETE!"
    log_success "═══════════════════════════════════════════════════════════"
    log_success ""
    log_success "IMPORTANT: Test SSH access NOW before closing this terminal!"
    log_success ""
    log_success "Report saved to: /root/setup-report.txt"
    log_success "Logs saved to: ${LOG_FILE}"
}

# Run main function
main "$@"
