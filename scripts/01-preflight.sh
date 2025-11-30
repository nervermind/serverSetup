#!/usr/bin/env bash
#
# 01-preflight.sh - Pre-installation system checks
#
# Performs comprehensive system checks before proceeding with installation
#

set -euo pipefail

# Source common functions if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

log_info() { echo -e "${GREEN}[PREFLIGHT]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[PREFLIGHT]${NC} $*"; }
log_error() { echo -e "${RED}[PREFLIGHT]${NC} $*"; }

# ============================================================================
# SYSTEM CHECKS
# ============================================================================

check_debian_version() {
    log_info "Verifying Debian version..."

    if [[ ! -f /etc/os-release ]]; then
        log_error "/etc/os-release not found"
        return 1
    fi

    source /etc/os-release

    if [[ "$ID" != "debian" ]]; then
        log_error "Not running Debian (detected: $ID)"
        return 1
    fi

    log_info "Debian ${VERSION_ID} (${VERSION_CODENAME}) detected"
    return 0
}

check_architecture() {
    log_info "Checking system architecture..."

    local arch
    arch=$(uname -m)

    case "$arch" in
        x86_64|amd64)
            log_info "Architecture: $arch (supported)"
            return 0
            ;;
        aarch64|arm64)
            log_info "Architecture: $arch (supported)"
            return 0
            ;;
        *)
            log_warn "Architecture: $arch (may not be fully supported)"
            return 0
            ;;
    esac
}

check_systemd() {
    log_info "Checking for systemd..."

    if ! command -v systemctl &> /dev/null; then
        log_error "systemd not found or not running"
        return 1
    fi

    if ! systemctl is-system-running --quiet 2>/dev/null; then
        log_warn "systemd is not in running state, but continuing..."
    fi

    log_info "systemd is available"
    return 0
}

check_package_manager() {
    log_info "Checking package manager..."

    if ! command -v apt-get &> /dev/null; then
        log_error "apt-get not found"
        return 1
    fi

    log_info "apt package manager available"
    return 0
}

check_network_tools() {
    log_info "Checking for required network tools..."

    local missing_tools=()

    if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
        missing_tools+=("curl or wget")
    fi

    if ! command -v ip &> /dev/null; then
        missing_tools+=("ip (iproute2)")
    fi

    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_warn "Missing tools: ${missing_tools[*]}"
        log_info "Will install during setup..."
    else
        log_info "All required network tools available"
    fi

    return 0
}

check_memory() {
    log_info "Checking system memory..."

    local total_mem_kb
    total_mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local total_mem_gb=$((total_mem_kb / 1024 / 1024))

    if [[ $total_mem_gb -lt 1 ]]; then
        log_warn "Low memory: ${total_mem_gb}GB (minimum 1GB recommended)"
    else
        log_info "Memory: ${total_mem_gb}GB"
    fi

    return 0
}

check_disk_space() {
    log_info "Checking disk space..."

    local root_available
    root_available=$(df / | awk 'NR==2 {print $4}')
    local root_gb=$((root_available / 1024 / 1024))

    if [[ $root_gb -lt 5 ]]; then
        log_warn "Low disk space on /: ${root_gb}GB"
    else
        log_info "Disk space on /: ${root_gb}GB"
    fi

    # Check /var separately if it's a different mount
    if mountpoint -q /var 2>/dev/null; then
        local var_available
        var_available=$(df /var | awk 'NR==2 {print $4}')
        local var_gb=$((var_available / 1024 / 1024))
        log_info "Disk space on /var: ${var_gb}GB"
    fi

    return 0
}

check_existing_docker() {
    log_info "Checking for existing Docker installation..."

    if command -v docker &> /dev/null; then
        local docker_version
        docker_version=$(docker --version 2>/dev/null || echo "unknown")
        log_warn "Docker already installed: $docker_version"
        log_warn "Existing Docker installation will be reconfigured"
    else
        log_info "No existing Docker installation found"
    fi

    return 0
}

check_existing_firewall() {
    log_info "Checking for existing firewall configuration..."

    local firewall_active=""

    if command -v ufw &> /dev/null; then
        if ufw status 2>/dev/null | grep -q "Status: active"; then
            firewall_active="ufw"
        fi
    fi

    if command -v nft &> /dev/null; then
        if nft list ruleset 2>/dev/null | grep -q "chain"; then
            firewall_active="${firewall_active:+$firewall_active, }nftables"
        fi
    fi

    if iptables -L -n 2>/dev/null | grep -q "Chain"; then
        firewall_active="${firewall_active:+$firewall_active, }iptables"
    fi

    if [[ -n "$firewall_active" ]]; then
        log_warn "Active firewall(s) detected: $firewall_active"
        log_info "Existing firewall rules will be preserved and extended"
    else
        log_info "No active firewall detected"
    fi

    return 0
}

check_ssh_config() {
    log_info "Checking SSH configuration..."

    if [[ ! -f /etc/ssh/sshd_config ]]; then
        log_error "SSH server not installed"
        return 1
    fi

    # Backup original SSH config
    if [[ ! -f /etc/ssh/sshd_config.original ]]; then
        cp /etc/ssh/sshd_config /etc/ssh/sshd_config.original
        log_info "Backed up original SSH config"
    fi

    # Check current SSH port
    local current_port
    current_port=$(grep "^Port " /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}')
    if [[ -n "$current_port" ]]; then
        log_info "Current SSH port: $current_port"
    else
        log_info "SSH using default port 22"
    fi

    # Check root login status
    local root_login
    root_login=$(grep "^PermitRootLogin " /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}')
    if [[ -n "$root_login" ]]; then
        log_info "Current PermitRootLogin: $root_login"
    fi

    return 0
}

check_selinux() {
    log_info "Checking SELinux status..."

    if command -v getenforce &> /dev/null; then
        local selinux_status
        selinux_status=$(getenforce 2>/dev/null || echo "Not available")
        log_info "SELinux: $selinux_status"
    else
        log_info "SELinux not installed (normal for Debian)"
    fi

    return 0
}

check_existing_services() {
    log_info "Checking for service conflicts..."

    local services=(
        "apache2:80"
        "nginx:80,443"
        "traefik:80,443"
    )

    for service_port in "${services[@]}"; do
        local service="${service_port%:*}"
        local ports="${service_port#*:}"

        if systemctl is-active --quiet "$service" 2>/dev/null; then
            log_warn "$service is currently running on port(s): $ports"
            log_info "Service will be stopped during proxy installation"
        fi
    done

    return 0
}

check_timezone() {
    log_info "Checking timezone configuration..."

    if command -v timedatectl &> /dev/null; then
        local timezone
        timezone=$(timedatectl show -p Timezone --value 2>/dev/null || echo "unknown")
        log_info "Timezone: $timezone"

        # Check if NTP is enabled
        local ntp_status
        ntp_status=$(timedatectl show -p NTP --value 2>/dev/null || echo "unknown")
        if [[ "$ntp_status" == "yes" ]]; then
            log_info "NTP synchronization: enabled"
        else
            log_warn "NTP synchronization: disabled (will be enabled)"
        fi
    fi

    return 0
}

check_kernel_version() {
    log_info "Checking kernel version..."

    local kernel_version
    kernel_version=$(uname -r)
    log_info "Kernel: $kernel_version"

    # Check if kernel is reasonably recent (5.x or higher)
    local major_version
    major_version=$(echo "$kernel_version" | cut -d. -f1)

    if [[ $major_version -lt 5 ]]; then
        log_warn "Kernel version is older than 5.x (Docker may have issues)"
    fi

    return 0
}

update_package_cache() {
    log_info "Updating package cache..."

    if ! apt-get update -qq 2>&1 | grep -v "^Ign:" ; then
        log_error "Failed to update package cache"
        return 1
    fi

    log_info "Package cache updated"
    return 0
}

install_prerequisites() {
    log_info "Installing prerequisite packages..."

    local packages=(
        "curl"
        "wget"
        "ca-certificates"
        "gnupg"
        "lsb-release"
        "apt-transport-https"
        "software-properties-common"
    )

    for package in "${packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $package "; then
            log_info "Installing $package..."
            if ! apt-get install -y -qq "$package" &> /dev/null; then
                log_warn "Failed to install $package (will retry later)"
            fi
        fi
    done

    log_info "Prerequisites installed"
    return 0
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    log_info "Starting preflight checks..."
    echo ""

    local checks_passed=0
    local checks_failed=0
    local checks_warned=0

    # Run all checks
    local checks=(
        "check_debian_version"
        "check_architecture"
        "check_systemd"
        "check_package_manager"
        "check_kernel_version"
        "check_memory"
        "check_disk_space"
        "check_network_tools"
        "check_existing_docker"
        "check_existing_firewall"
        "check_ssh_config"
        "check_selinux"
        "check_existing_services"
        "check_timezone"
    )

    for check in "${checks[@]}"; do
        log_info "Running $check..."
        if $check; then
            ((checks_passed++))
        else
            ((checks_failed++))
        fi
    done

    echo ""
    log_info "═══════════════════════════════════════════════════════"
    log_info "Preflight checks: $checks_passed passed, $checks_failed failed"
    log_info "═══════════════════════════════════════════════════════"
    echo ""

    if [[ $checks_failed -gt 0 ]]; then
        log_error "Critical preflight checks failed!"
        return 1
    fi

    # Update package cache and install prerequisites
    update_package_cache
    install_prerequisites

    log_info "All preflight checks passed!"
    return 0
}

main "$@"
