#!/usr/bin/env bash
#
# 03-users.sh - User management and configuration
#
# Creates secure admin user with sudo privileges
#

set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

log_info() { echo -e "${GREEN}[USERS]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[USERS]${NC} $*"; }
log_error() { echo -e "${RED}[USERS]${NC} $*"; }

# Configuration
ADMIN_USERNAME="${ADMIN_USERNAME:-admin}"
ADMIN_SSH_KEY="${ADMIN_SSH_KEY:-}"

# ============================================================================
# USER CREATION
# ============================================================================

create_admin_user() {
    log_info "Creating admin user: $ADMIN_USERNAME"

    if id "$ADMIN_USERNAME" &>/dev/null; then
        log_warn "User $ADMIN_USERNAME already exists"
        return 0
    fi

    # Create user with home directory
    if ! useradd -m -s /bin/bash "$ADMIN_USERNAME"; then
        log_error "Failed to create user"
        return 1
    fi

    log_info "User $ADMIN_USERNAME created"
}

configure_sudo_access() {
    log_info "Configuring sudo access for $ADMIN_USERNAME..."

    # Add user to sudo group
    usermod -aG sudo "$ADMIN_USERNAME"

    # Create sudoers file for passwordless sudo (optional, but convenient for automation)
    local sudoers_file="/etc/sudoers.d/${ADMIN_USERNAME}"

    cat > "$sudoers_file" << EOF
# Sudo privileges for ${ADMIN_USERNAME}
# Created by Secure Server Setup Framework

${ADMIN_USERNAME} ALL=(ALL) NOPASSWD:ALL
EOF

    chmod 0440 "$sudoers_file"

    # Verify sudoers syntax
    if ! visudo -c -f "$sudoers_file"; then
        log_error "Sudoers file has syntax errors!"
        rm -f "$sudoers_file"
        return 1
    fi

    log_info "Sudo access configured"
}

setup_ssh_keys() {
    log_info "Setting up SSH keys for $ADMIN_USERNAME..."

    local ssh_dir="/home/${ADMIN_USERNAME}/.ssh"
    local authorized_keys="${ssh_dir}/authorized_keys"

    # Create .ssh directory
    mkdir -p "$ssh_dir"

    # Add SSH public key if provided
    if [[ -n "$ADMIN_SSH_KEY" ]]; then
        echo "$ADMIN_SSH_KEY" > "$authorized_keys"
        log_info "SSH public key added"
    else
        log_warn "No SSH key provided!"
        log_warn "You should add your SSH key manually to: $authorized_keys"

        # Create empty authorized_keys file
        touch "$authorized_keys"
    fi

    # Set correct permissions
    chown -R "${ADMIN_USERNAME}:${ADMIN_USERNAME}" "$ssh_dir"
    chmod 700 "$ssh_dir"
    chmod 600 "$authorized_keys"

    log_info "SSH key configuration complete"
}

configure_user_environment() {
    log_info "Configuring user environment..."

    local bashrc="/home/${ADMIN_USERNAME}/.bashrc"

    # Add useful aliases and settings
    cat >> "$bashrc" << 'EOF'

# Custom aliases and settings
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'

# Docker aliases
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias dlog='docker logs'
alias dex='docker exec -it'

# Safety aliases
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# History settings
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoredups:erasedups

# Colorful prompt
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

EOF

    chown "${ADMIN_USERNAME}:${ADMIN_USERNAME}" "$bashrc"

    log_info "User environment configured"
}

lockdown_root_account() {
    log_info "Locking down root account..."

    # Disable root password (SSH key only)
    passwd -l root 2>/dev/null || true

    log_info "Root password disabled (SSH key only)"
}

configure_user_limits() {
    log_info "Configuring user limits..."

    local limits_file="/etc/security/limits.d/99-user-limits.conf"

    cat > "$limits_file" << EOF
# User limits configuration
# Secure Server Setup Framework

# Increase file descriptor limits
* soft nofile 65536
* hard nofile 65536

# Increase process limits
* soft nproc 32768
* hard nproc 32768

# Core dumps
* soft core 0
* hard core 0
EOF

    log_info "User limits configured"
}

configure_login_defs() {
    log_info "Hardening login.defs..."

    local login_defs="/etc/login.defs"

    # Backup original
    cp "$login_defs" "${login_defs}.backup"

    # Set secure password aging
    sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   90/' "$login_defs"
    sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS   1/' "$login_defs"
    sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE   7/' "$login_defs"

    # Set minimum password length
    if grep -q "^PASS_MIN_LEN" "$login_defs"; then
        sed -i 's/^PASS_MIN_LEN.*/PASS_MIN_LEN   12/' "$login_defs"
    else
        echo "PASS_MIN_LEN   12" >> "$login_defs"
    fi

    # Set umask for better security
    sed -i 's/^UMASK.*/UMASK           027/' "$login_defs"

    log_info "login.defs hardened"
}

configure_pam() {
    log_info "Configuring PAM for enhanced security..."

    # Install libpam-pwquality if not present
    if ! dpkg -l | grep -q libpam-pwquality; then
        apt-get install -y libpam-pwquality &>/dev/null
    fi

    # Configure password quality requirements
    local pwquality_conf="/etc/security/pwquality.conf"

    if [[ -f "$pwquality_conf" ]]; then
        cp "$pwquality_conf" "${pwquality_conf}.backup"

        cat >> "$pwquality_conf" << EOF

# Password quality requirements
# Secure Server Setup Framework

minlen = 12
minclass = 3
maxrepeat = 3
maxsequence = 3
gecoscheck = 1
dictcheck = 1
usercheck = 1
enforcing = 1
EOF
    fi

    log_info "PAM configuration complete"
}

create_user_info_file() {
    log_info "Creating user information file..."

    local info_file="/root/user-info.txt"

    cat > "$info_file" << EOF
════════════════════════════════════════════════════════════════════════
  USER CONFIGURATION
════════════════════════════════════════════════════════════════════════

Admin User: ${ADMIN_USERNAME}
Home Directory: /home/${ADMIN_USERNAME}
Shell: /bin/bash
Sudo Access: Yes (passwordless)
SSH Key: $([ -n "$ADMIN_SSH_KEY" ] && echo "Configured" || echo "NOT CONFIGURED")

IMPORTANT:
$([ -z "$ADMIN_SSH_KEY" ] && echo "⚠️  No SSH key was configured! You MUST add your SSH key manually:" || echo "✓ SSH key has been configured")
$([ -z "$ADMIN_SSH_KEY" ] && echo "   1. Create /home/${ADMIN_USERNAME}/.ssh/authorized_keys" || echo "")
$([ -z "$ADMIN_SSH_KEY" ] && echo "   2. Add your public key to that file" || echo "")
$([ -z "$ADMIN_SSH_KEY" ] && echo "   3. Set ownership: chown -R ${ADMIN_USERNAME}:${ADMIN_USERNAME} /home/${ADMIN_USERNAME}/.ssh" || echo "")
$([ -z "$ADMIN_SSH_KEY" ] && echo "   4. Set permissions: chmod 700 /home/${ADMIN_USERNAME}/.ssh && chmod 600 /home/${ADMIN_USERNAME}/.ssh/authorized_keys" || echo "")

To switch to admin user: sudo su - ${ADMIN_USERNAME}
To test SSH: ssh -p \${SSH_PORT} ${ADMIN_USERNAME}@\$(hostname -I | awk '{print \$1}')

════════════════════════════════════════════════════════════════════════
EOF

    log_info "User information saved to: $info_file"
    cat "$info_file"
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    log_info "Starting user configuration..."
    echo ""

    create_admin_user
    configure_sudo_access
    setup_ssh_keys
    configure_user_environment
    configure_user_limits
    configure_login_defs
    configure_pam
    lockdown_root_account

    create_user_info_file

    echo ""
    log_info "User configuration complete!"

    if [[ -z "$ADMIN_SSH_KEY" ]]; then
        log_warn "═══════════════════════════════════════════════════════"
        log_warn "  WARNING: No SSH key configured!"
        log_warn "  Add your SSH key before SSH hardening step!"
        log_warn "═══════════════════════════════════════════════════════"
    fi

    return 0
}

main "$@"
