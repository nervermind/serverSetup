#!/usr/bin/env bash
#
# 10-fail2ban.sh - fail2ban installation and configuration
#

set -euo pipefail

readonly GREEN='\033[0;32m'
readonly NC='\033[0m'

log_info() { echo -e "${GREEN}[FAIL2BAN]${NC} $*"; }

SSH_PORT="${SSH_PORT:-22}"

install_fail2ban() {
    log_info "Installing fail2ban..."

    apt-get install -y fail2ban &>/dev/null

    log_info "fail2ban installed"
}

configure_fail2ban() {
    log_info "Configuring fail2ban..."

    cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
destemail = root@localhost
sendername = Fail2Ban
action = %(action_mwl)s

[sshd]
enabled = true
port = ${SSH_PORT}
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 86400
EOF

    systemctl enable fail2ban
    systemctl restart fail2ban

    log_info "fail2ban configured"
}

main() {
    log_info "Setting up fail2ban..."
    echo ""

    install_fail2ban
    configure_fail2ban

    echo ""
    log_info "fail2ban setup complete!"
    log_info "Check status: fail2ban-client status sshd"

    return 0
}

main "$@"
