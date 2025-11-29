#!/usr/bin/env bash
#
# 11-auditd.sh - auditd installation and configuration
#

set -euo pipefail

readonly GREEN='\033[0;32m'
readonly NC='\033[0m'

log_info() { echo -e "${GREEN}[AUDITD]${NC} $*"; }

install_auditd() {
    log_info "Installing auditd..."

    apt-get install -y auditd audispd-plugins &>/dev/null

    log_info "auditd installed"
}

configure_auditd() {
    log_info "Configuring auditd rules..."

    cat > /etc/audit/rules.d/hardening.rules << 'EOF'
# Audit rules for security monitoring

# Monitor authentication
-w /var/log/auth.log -p wa -k auth
-w /var/log/faillog -p wa -k logins
-w /var/log/lastlog -p wa -k logins

# Monitor user/group changes
-w /etc/group -p wa -k identity
-w /etc/passwd -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/security/opasswd -p wa -k identity

# Monitor sudo usage
-w /etc/sudoers -p wa -k actions
-w /etc/sudoers.d/ -p wa -k actions

# Monitor SSH
-w /etc/ssh/sshd_config -p wa -k sshd

# Monitor Docker
-w /usr/bin/docker -p wa -k docker
-w /var/lib/docker -p wa -k docker
-w /etc/docker -p wa -k docker

# Monitor system calls
-a always,exit -F arch=b64 -S execve -k exec
-a always,exit -F arch=b32 -S execve -k exec
EOF

    augenrules --load
    systemctl enable auditd
    systemctl restart auditd

    log_info "auditd configured"
}

main() {
    log_info "Setting up auditd..."
    echo ""

    install_auditd
    configure_auditd

    echo ""
    log_info "auditd setup complete!"
    log_info "View logs: ausearch -k docker"

    return 0
}

main "$@"
