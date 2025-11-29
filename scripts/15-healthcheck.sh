#!/usr/bin/env bash
#
# 15-healthcheck.sh - System health check
#

set -euo pipefail

readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

check_services() {
    echo "═══════════════════════════════════════════════════════"
    echo "  SERVICE STATUS"
    echo "═══════════════════════════════════════════════════════"

    services=("ssh" "sshd" "docker" "ufw" "fail2ban" "auditd")

    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            echo -e "${GREEN}[✓]${NC} $service"
        else
            echo -e "${RED}[✗]${NC} $service (not running)"
        fi
    done
}

check_disk_usage() {
    echo ""
    echo "═══════════════════════════════════════════════════════"
    echo "  DISK USAGE"
    echo "═══════════════════════════════════════════════════════"

    df -h / /var | tail -n +2 | while read -r line; do
        usage=$(echo "$line" | awk '{print $5}' | tr -d '%')
        if [[ $usage -gt 80 ]]; then
            echo -e "${RED}$line${NC}"
        elif [[ $usage -gt 60 ]]; then
            echo -e "${YELLOW}$line${NC}"
        else
            echo -e "${GREEN}$line${NC}"
        fi
    done
}

check_memory() {
    echo ""
    echo "═══════════════════════════════════════════════════════"
    echo "  MEMORY USAGE"
    echo "═══════════════════════════════════════════════════════"

    free -h
}

check_docker_containers() {
    echo ""
    echo "═══════════════════════════════════════════════════════"
    echo "  DOCKER CONTAINERS"
    echo "═══════════════════════════════════════════════════════"

    if command -v docker &> /dev/null; then
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    else
        echo "Docker not installed"
    fi
}

check_firewall() {
    echo ""
    echo "═══════════════════════════════════════════════════════"
    echo "  FIREWALL STATUS"
    echo "═══════════════════════════════════════════════════════"

    if command -v ufw &> /dev/null; then
        ufw status
    else
        echo "UFW not installed"
    fi
}

check_fail2ban() {
    echo ""
    echo "═══════════════════════════════════════════════════════"
    echo "  FAIL2BAN STATUS"
    echo "═══════════════════════════════════════════════════════"

    if command -v fail2ban-client &> /dev/null; then
        fail2ban-client status
    else
        echo "fail2ban not installed"
    fi
}

check_updates() {
    echo ""
    echo "═══════════════════════════════════════════════════════"
    echo "  SYSTEM UPDATES"
    echo "═══════════════════════════════════════════════════════"

    apt-get update -qq 2>/dev/null
    updates=$(apt-get -s upgrade | grep -P "^\d+ upgraded" || echo "0 upgraded")
    echo "$updates"
}

main() {
    echo ""
    echo "SERVER HEALTH CHECK"
    echo "$(date)"
    echo ""

    check_services
    check_disk_usage
    check_memory
    check_docker_containers
    check_firewall
    check_fail2ban
    check_updates

    echo ""
    echo "═══════════════════════════════════════════════════════"
    echo "Health check complete!"
    echo "═══════════════════════════════════════════════════════"
    echo ""

    return 0
}

main "$@"
