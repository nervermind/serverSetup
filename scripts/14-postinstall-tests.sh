#!/usr/bin/env bash
#
# 14-postinstall-tests.sh - Post-installation verification tests
#

set -euo pipefail

readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0

log_pass() { echo -e "${GREEN}[✓]${NC} $*"; ((TESTS_PASSED++)); }
log_fail() { echo -e "${RED}[✗]${NC} $*"; ((TESTS_FAILED++)); }
log_info() { echo -e "${YELLOW}[i]${NC} $*"; }

test_ssh_service() {
    log_info "Testing SSH service..."
    if systemctl is-active --quiet ssh || systemctl is-active --quiet sshd; then
        log_pass "SSH service is running"
    else
        log_fail "SSH service is not running"
    fi
}

test_firewall() {
    log_info "Testing firewall..."
    if command -v ufw &> /dev/null && ufw status | grep -q "Status: active"; then
        log_pass "Firewall is active"
    else
        log_fail "Firewall is not active"
    fi
}

test_docker() {
    log_info "Testing Docker..."
    if command -v docker &> /dev/null && docker info &> /dev/null; then
        log_pass "Docker is running"
    else
        log_fail "Docker is not running"
    fi
}

test_fail2ban() {
    log_info "Testing fail2ban..."
    if systemctl is-active --quiet fail2ban; then
        log_pass "fail2ban is running"
    else
        log_fail "fail2ban is not running"
    fi
}

test_auditd() {
    log_info "Testing auditd..."
    if systemctl is-active --quiet auditd; then
        log_pass "auditd is running"
    else
        log_fail "auditd is not running"
    fi
}

test_user_account() {
    log_info "Testing admin user..."
    if id "${ADMIN_USERNAME:-admin}" &> /dev/null; then
        log_pass "Admin user exists"
    else
        log_fail "Admin user not found"
    fi
}

test_sudo_access() {
    log_info "Testing sudo configuration..."
    if [[ -f "/etc/sudoers.d/${ADMIN_USERNAME:-admin}" ]]; then
        log_pass "Sudo configuration exists"
    else
        log_fail "Sudo configuration missing"
    fi
}

test_ssh_hardening() {
    log_info "Testing SSH hardening..."
    if grep -q "PasswordAuthentication no" /etc/ssh/sshd_config* 2>/dev/null; then
        log_pass "Password authentication disabled"
    else
        log_fail "Password authentication not disabled"
    fi
}

test_docker_network() {
    log_info "Testing Docker network..."
    if docker network ls | grep -q "secure-network"; then
        log_pass "Secure Docker network exists"
    else
        log_fail "Secure Docker network not found"
    fi
}

generate_report() {
    echo ""
    echo "═══════════════════════════════════════════════════════"
    echo "  POST-INSTALLATION TEST REPORT"
    echo "═══════════════════════════════════════════════════════"
    echo ""
    echo "Tests Passed: $TESTS_PASSED"
    echo "Tests Failed: $TESTS_FAILED"
    echo ""

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}All tests passed!${NC}"
        echo ""
        echo "Your server is ready for production use."
    else
        echo -e "${RED}Some tests failed!${NC}"
        echo ""
        echo "Please review the failed tests above."
    fi

    echo ""
    echo "═══════════════════════════════════════════════════════"
}

main() {
    echo ""
    echo "Running post-installation tests..."
    echo ""

    test_ssh_service
    test_firewall
    test_docker
    test_fail2ban
    test_auditd
    test_user_account
    test_sudo_access
    test_ssh_hardening
    test_docker_network

    generate_report

    return 0
}

main "$@"
