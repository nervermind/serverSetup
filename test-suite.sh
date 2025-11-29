#!/usr/bin/env bash
#
# test-suite.sh - Comprehensive testing suite
#
# Tests all components of the secure server setup
#

set -euo pipefail

readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

log_test() { echo -e "${BLUE}[TEST]${NC} $*"; ((TESTS_RUN++)); }
log_pass() { echo -e "${GREEN}[PASS]${NC} $*"; ((TESTS_PASSED++)); }
log_fail() { echo -e "${RED}[FAIL]${NC} $*"; ((TESTS_FAILED++)); }
log_skip() { echo -e "${YELLOW}[SKIP]${NC} $*"; ((TESTS_SKIPPED++)); }

# ============================================================================
# SSH TESTS
# ============================================================================

test_ssh_running() {
    log_test "SSH service is running"
    if systemctl is-active --quiet ssh || systemctl is-active --quiet sshd; then
        log_pass "SSH service is running"
        return 0
    else
        log_fail "SSH service is not running"
        return 1
    fi
}

test_ssh_password_disabled() {
    log_test "SSH password authentication is disabled"
    if grep -qr "^PasswordAuthentication no" /etc/ssh/; then
        log_pass "Password authentication disabled"
        return 0
    else
        log_fail "Password authentication not disabled"
        return 1
    fi
}

test_ssh_root_login() {
    log_test "SSH root login configuration"
    if grep -qr "^PermitRootLogin no\|^PermitRootLogin prohibit-password" /etc/ssh/; then
        log_pass "Root login properly configured"
        return 0
    else
        log_fail "Root login not properly secured"
        return 1
    fi
}

# ============================================================================
# FIREWALL TESTS
# ============================================================================

test_firewall_enabled() {
    log_test "Firewall is enabled"
    if command -v ufw &> /dev/null && ufw status | grep -q "Status: active"; then
        log_pass "UFW is active"
        return 0
    else
        log_fail "UFW is not active"
        return 1
    fi
}

test_firewall_rules() {
    log_test "Firewall rules are configured"
    if ufw status | grep -qE "(22|80|443)/tcp"; then
        log_pass "Essential firewall rules present"
        return 0
    else
        log_fail "Missing essential firewall rules"
        return 1
    fi
}

# ============================================================================
# DOCKER TESTS
# ============================================================================

test_docker_installed() {
    log_test "Docker is installed"
    if command -v docker &> /dev/null; then
        log_pass "Docker is installed"
        return 0
    else
        log_fail "Docker is not installed"
        return 1
    fi
}

test_docker_running() {
    log_test "Docker daemon is running"
    if docker info &> /dev/null; then
        log_pass "Docker daemon is running"
        return 0
    else
        log_fail "Docker daemon is not running"
        return 1
    fi
}

test_docker_compose() {
    log_test "Docker Compose is installed"
    if docker compose version &> /dev/null; then
        log_pass "Docker Compose is installed"
        return 0
    else
        log_fail "Docker Compose is not installed"
        return 1
    fi
}

test_docker_hardening() {
    log_test "Docker daemon hardening"
    if [[ -f /etc/docker/daemon.json ]]; then
        log_pass "Docker daemon.json exists"
        return 0
    else
        log_fail "Docker daemon.json missing"
        return 1
    fi
}

test_docker_networks() {
    log_test "Docker secure network"
    if docker network ls | grep -q "secure-network"; then
        log_pass "Secure network configured"
        return 0
    else
        log_fail "Secure network not found"
        return 1
    fi
}

# ============================================================================
# SECURITY TOOLS TESTS
# ============================================================================

test_fail2ban() {
    log_test "fail2ban is running"
    if systemctl is-active --quiet fail2ban; then
        log_pass "fail2ban is running"
        return 0
    else
        log_fail "fail2ban is not running"
        return 1
    fi
}

test_fail2ban_jails() {
    log_test "fail2ban jails configured"
    if fail2ban-client status | grep -q "sshd"; then
        log_pass "SSH jail is active"
        return 0
    else
        log_fail "SSH jail not active"
        return 1
    fi
}

test_auditd() {
    log_test "auditd is running"
    if systemctl is-active --quiet auditd; then
        log_pass "auditd is running"
        return 0
    else
        log_fail "auditd is not running"
        return 1
    fi
}

test_auditd_rules() {
    log_test "auditd rules configured"
    if [[ -f /etc/audit/rules.d/hardening.rules ]]; then
        log_pass "Audit rules configured"
        return 0
    else
        log_fail "Audit rules missing"
        return 1
    fi
}

# ============================================================================
# USER TESTS
# ============================================================================

test_admin_user() {
    log_test "Admin user exists"
    if id "${ADMIN_USERNAME:-admin}" &> /dev/null; then
        log_pass "Admin user exists"
        return 0
    else
        log_fail "Admin user not found"
        return 1
    fi
}

test_sudo_access() {
    log_test "Sudo configuration"
    if [[ -f "/etc/sudoers.d/${ADMIN_USERNAME:-admin}" ]]; then
        log_pass "Sudo configuration exists"
        return 0
    else
        log_fail "Sudo configuration missing"
        return 1
    fi
}

test_ssh_keys() {
    log_test "SSH keys configured"
    if [[ -f "/home/${ADMIN_USERNAME:-admin}/.ssh/authorized_keys" ]]; then
        log_pass "SSH keys configured"
        return 0
    else
        log_fail "SSH keys not configured"
        return 1
    fi
}

# ============================================================================
# BACKUP TESTS
# ============================================================================

test_backup_script() {
    log_test "Backup script exists"
    if [[ -x /usr/local/bin/server-backup ]]; then
        log_pass "Backup script configured"
        return 0
    else
        log_fail "Backup script missing"
        return 1
    fi
}

test_backup_cron() {
    log_test "Backup cron job"
    if crontab -l | grep -q "server-backup"; then
        log_pass "Backup cron job configured"
        return 0
    else
        log_skip "Backup cron job not configured"
        return 1
    fi
}

# ============================================================================
# SYSTEM TESTS
# ============================================================================

test_disk_space() {
    log_test "Disk space availability"
    local usage
    usage=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
    if [[ $usage -lt 80 ]]; then
        log_pass "Disk space OK ($usage% used)"
        return 0
    else
        log_fail "Disk space critical ($usage% used)"
        return 1
    fi
}

test_memory() {
    log_test "Memory availability"
    local mem_available
    mem_available=$(free -m | awk 'NR==2 {print $7}')
    if [[ $mem_available -gt 100 ]]; then
        log_pass "Memory OK (${mem_available}MB available)"
        return 0
    else
        log_fail "Memory low (${mem_available}MB available)"
        return 1
    fi
}

# ============================================================================
# REPORT GENERATION
# ============================================================================

generate_report() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════════════"
    echo "  TEST SUITE REPORT"
    echo "═══════════════════════════════════════════════════════════════════════"
    echo ""
    echo "Tests Run:     $TESTS_RUN"
    echo "Tests Passed:  $TESTS_PASSED"
    echo "Tests Failed:  $TESTS_FAILED"
    echo "Tests Skipped: $TESTS_SKIPPED"
    echo ""

    local pass_rate=0
    if [[ $TESTS_RUN -gt 0 ]]; then
        pass_rate=$((TESTS_PASSED * 100 / TESTS_RUN))
    fi

    echo "Success Rate: $pass_rate%"
    echo ""

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}✓ All tests passed!${NC}"
        echo ""
        echo "Your server setup is secure and fully functional."
    else
        echo -e "${RED}✗ Some tests failed!${NC}"
        echo ""
        echo "Please review the failed tests above and fix the issues."
    fi

    echo ""
    echo "═══════════════════════════════════════════════════════════════════════"
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════════════"
    echo "  SECURE SERVER SETUP - TEST SUITE"
    echo "  $(date)"
    echo "═══════════════════════════════════════════════════════════════════════"
    echo ""

    # SSH Tests
    echo "Running SSH tests..."
    test_ssh_running || true
    test_ssh_password_disabled || true
    test_ssh_root_login || true
    echo ""

    # Firewall Tests
    echo "Running Firewall tests..."
    test_firewall_enabled || true
    test_firewall_rules || true
    echo ""

    # Docker Tests
    echo "Running Docker tests..."
    test_docker_installed || true
    test_docker_running || true
    test_docker_compose || true
    test_docker_hardening || true
    test_docker_networks || true
    echo ""

    # Security Tools Tests
    echo "Running Security Tools tests..."
    test_fail2ban || true
    test_fail2ban_jails || true
    test_auditd || true
    test_auditd_rules || true
    echo ""

    # User Tests
    echo "Running User tests..."
    test_admin_user || true
    test_sudo_access || true
    test_ssh_keys || true
    echo ""

    # Backup Tests
    echo "Running Backup tests..."
    test_backup_script || true
    test_backup_cron || true
    echo ""

    # System Tests
    echo "Running System tests..."
    test_disk_space || true
    test_memory || true
    echo ""

    # Generate report
    generate_report

    # Exit with appropriate code
    if [[ $TESTS_FAILED -eq 0 ]]; then
        exit 0
    else
        exit 1
    fi
}

main "$@"
