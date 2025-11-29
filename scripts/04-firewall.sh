#!/usr/bin/env bash
#
# 04-firewall.sh - Firewall configuration with UFW
#
# Configures secure firewall rules using UFW (Uncomplicated Firewall)
#

set -euo pipefail

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

log_info() { echo -e "${GREEN}[FIREWALL]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[FIREWALL]${NC} $*"; }
log_error() { echo -e "${RED}[FIREWALL]${NC} $*"; }

SSH_PORT="${SSH_PORT:-22}"
PROXY_TYPE="${PROXY_TYPE:-traefik}"

install_ufw() {
    log_info "Installing UFW..."

    if command -v ufw &> /dev/null; then
        log_info "UFW already installed"
        return 0
    fi

    apt-get install -y ufw &>/dev/null
    log_info "UFW installed"
}

configure_ufw_defaults() {
    log_info "Configuring UFW defaults..."

    # Set default policies
    ufw --force default deny incoming
    ufw --force default allow outgoing
    ufw --force default deny routed

    log_info "Default policies configured"
}

configure_ssh_rule() {
    log_info "Allowing SSH on port ${SSH_PORT}..."

    ufw allow "${SSH_PORT}/tcp" comment "SSH"

    log_info "SSH rule added"
}

configure_http_rules() {
    if [[ "$PROXY_TYPE" != "none" ]]; then
        log_info "Allowing HTTP/HTTPS traffic..."

        ufw allow 80/tcp comment "HTTP"
        ufw allow 443/tcp comment "HTTPS"

        log_info "HTTP/HTTPS rules added"
    fi
}

configure_docker_rules() {
    log_info "Configuring Docker-specific rules..."

    # Allow Docker containers to communicate
    # UFW will be configured to work with Docker in docker-hardening.sh

    log_info "Docker rules will be configured during Docker setup"
}

enable_logging() {
    log_info "Enabling firewall logging..."

    ufw logging medium

    log_info "Firewall logging enabled"
}

enable_ufw() {
    log_info "Enabling UFW..."

    # Enable UFW
    echo "y" | ufw enable

    log_info "UFW enabled"
}

show_firewall_status() {
    log_info "Current firewall status:"
    echo ""
    ufw status verbose
    echo ""
}

create_firewall_management_script() {
    log_info "Creating firewall management helper script..."

    cat > /usr/local/bin/fw-manage << 'EOF'
#!/bin/bash
# Firewall management helper script

case "${1:-}" in
    status)
        ufw status verbose
        ;;
    list)
        ufw status numbered
        ;;
    allow)
        if [[ -z "${2:-}" ]]; then
            echo "Usage: fw-manage allow <port>[/protocol] [comment]"
            exit 1
        fi
        if [[ -n "${3:-}" ]]; then
            ufw allow "$2" comment "$3"
        else
            ufw allow "$2"
        fi
        ;;
    deny)
        if [[ -z "${2:-}" ]]; then
            echo "Usage: fw-manage deny <port>[/protocol]"
            exit 1
        fi
        ufw deny "$2"
        ;;
    delete)
        if [[ -z "${2:-}" ]]; then
            echo "Usage: fw-manage delete <rule-number>"
            exit 1
        fi
        ufw delete "$2"
        ;;
    reset)
        echo "This will reset all firewall rules!"
        read -p "Are you sure? (yes/no): " confirm
        if [[ "$confirm" == "yes" ]]; then
            ufw --force reset
        fi
        ;;
    *)
        echo "Firewall Management Script"
        echo ""
        echo "Usage: fw-manage <command> [options]"
        echo ""
        echo "Commands:"
        echo "  status              Show firewall status"
        echo "  list                List all rules with numbers"
        echo "  allow <port>        Allow traffic on port"
        echo "  deny <port>         Deny traffic on port"
        echo "  delete <number>     Delete rule by number"
        echo "  reset               Reset all rules (dangerous!)"
        echo ""
        ;;
esac
EOF

    chmod +x /usr/local/bin/fw-manage
    log_info "Helper script created: fw-manage"
}

main() {
    log_info "Starting firewall configuration..."
    echo ""

    install_ufw
    configure_ufw_defaults
    configure_ssh_rule
    configure_http_rules
    configure_docker_rules
    enable_logging
    create_firewall_management_script
    enable_ufw

    echo ""
    show_firewall_status

    log_info "Firewall configuration complete!"
    log_info "Use 'fw-manage' command for easy firewall management"

    return 0
}

main "$@"
