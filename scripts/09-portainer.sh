#!/usr/bin/env bash
#
# 09-portainer.sh - Portainer installation
#

set -euo pipefail

readonly GREEN='\033[0;32m'
readonly NC='\033[0m'

log_info() { echo -e "${GREEN}[PORTAINER]${NC} $*"; }

main() {
    log_info "Installing Portainer..."

    docker volume create portainer_data

    docker run -d \
        --name portainer \
        --restart unless-stopped \
        -p 9443:9443 \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v portainer_data:/data \
        portainer/portainer-ce:latest

    sleep 5

    log_info "Portainer installed!"
    log_info "Access at: https://$(hostname -I | awk '{print $1}'):9443"

    return 0
}

main "$@"
