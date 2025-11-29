#!/usr/bin/env bash
#
# 05-docker-install.sh - Docker CE installation
#
# Installs Docker CE from official repositories
#

set -euo pipefail

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

log_info() { echo -e "${GREEN}[DOCKER]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[DOCKER]${NC} $*"; }
log_error() { echo -e "${RED}[DOCKER]${NC} $*"; }

ADMIN_USERNAME="${ADMIN_USERNAME:-admin}"

remove_old_docker() {
    log_info "Removing old Docker versions..."

    local old_packages=(
        "docker"
        "docker-engine"
        "docker.io"
        "containerd"
        "runc"
    )

    for pkg in "${old_packages[@]}"; do
        if dpkg -l | grep -q "^ii  $pkg "; then
            apt-get remove -y "$pkg" &>/dev/null || true
        fi
    done

    log_info "Old Docker packages removed"
}

install_dependencies() {
    log_info "Installing dependencies..."

    apt-get update -qq
    apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
        apt-transport-https \
        software-properties-common \
        &>/dev/null

    log_info "Dependencies installed"
}

add_docker_repository() {
    log_info "Adding Docker repository..."

    # Add Docker's official GPG key
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | \
        gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    # Add repository
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
        $(lsb_release -cs) stable" | \
        tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt-get update -qq

    log_info "Docker repository added"
}

install_docker() {
    log_info "Installing Docker CE..."

    apt-get install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin \
        &>/dev/null

    log_info "Docker CE installed"
}

start_docker() {
    log_info "Starting Docker service..."

    systemctl enable docker
    systemctl start docker

    # Wait for Docker to be ready
    local retries=0
    while ! docker info &>/dev/null; do
        ((retries++))
        if [[ $retries -gt 10 ]]; then
            log_error "Docker failed to start"
            return 1
        fi
        sleep 1
    done

    log_info "Docker service started"
}

add_user_to_docker_group() {
    log_info "Adding $ADMIN_USERNAME to docker group..."

    usermod -aG docker "$ADMIN_USERNAME"

    log_info "User added to docker group"
    log_warn "User must log out and back in for group changes to take effect"
}

verify_installation() {
    log_info "Verifying Docker installation..."

    local docker_version
    docker_version=$(docker --version)
    log_info "Docker version: $docker_version"

    local compose_version
    compose_version=$(docker compose version)
    log_info "Docker Compose version: $compose_version"

    # Run hello-world test
    if docker run --rm hello-world &>/dev/null; then
        log_info "Docker test successful"
    else
        log_error "Docker test failed"
        return 1
    fi

    return 0
}

main() {
    log_info "Starting Docker installation..."
    echo ""

    if command -v docker &> /dev/null; then
        log_warn "Docker is already installed"
        docker --version
        read -p "Reinstall? (yes/no): " -r
        if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
            log_info "Skipping Docker installation"
            return 0
        fi
    fi

    remove_old_docker
    install_dependencies
    add_docker_repository
    install_docker
    start_docker
    add_user_to_docker_group
    verify_installation

    echo ""
    log_info "Docker installation complete!"
    log_info "Docker will be hardened in the next step"

    return 0
}

main "$@"
