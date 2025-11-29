#!/usr/bin/env bash
#
# 07-proxy-install-traefik.sh - Traefik reverse proxy installation
#

set -euo pipefail

readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

log_info() { echo -e "${GREEN}[TRAEFIK]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[TRAEFIK]${NC} $*"; }

DOMAIN="${DOMAIN:-example.com}"
LETSENCRYPT_EMAIL="${LETSENCRYPT_EMAIL:-admin@example.com}"

create_traefik_dir() {
    log_info "Creating Traefik directory structure..."

    mkdir -p /opt/traefik/{config,certs}
    touch /opt/traefik/acme.json
    chmod 600 /opt/traefik/acme.json

    log_info "Directory structure created"
}

create_traefik_config() {
    log_info "Creating Traefik configuration..."

    cat > /opt/traefik/traefik.yml << EOF
# Traefik Configuration
global:
  checkNewVersion: false
  sendAnonymousUsage: false

api:
  dashboard: true
  insecure: false

entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: websecure
          scheme: https

  websecure:
    address: ":443"
    http:
      tls:
        certResolver: letsencrypt

certificatesResolvers:
  letsencrypt:
    acme:
      email: ${LETSENCRYPT_EMAIL}
      storage: /certs/acme.json
      tlsChallenge: {}

providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false
    network: traefik-net
  file:
    directory: /config
    watch: true

log:
  level: INFO
EOF

    log_info "Traefik configuration created"
}

create_docker_network() {
    log_info "Creating Traefik network..."

    if ! docker network ls | grep -q traefik-net; then
        docker network create traefik-net
    fi

    log_info "Traefik network created"
}

create_docker_compose() {
    log_info "Creating Docker Compose file..."

    cat > /opt/traefik/docker-compose.yml << EOF
version: '3.8'

services:
  traefik:
    image: traefik:v2.10
    container_name: traefik
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    networks:
      - traefik-net
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./traefik.yml:/traefik.yml:ro
      - ./config:/config:ro
      - ./certs:/certs
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.dashboard.rule=Host(\`${DOMAIN}\`) && (PathPrefix(\`/api\`) || PathPrefix(\`/dashboard\`))"
      - "traefik.http.routers.dashboard.service=api@internal"
      - "traefik.http.routers.dashboard.entrypoints=websecure"
      - "traefik.http.routers.dashboard.tls.certresolver=letsencrypt"

networks:
  traefik-net:
    external: true
EOF

    log_info "Docker Compose file created"
}

start_traefik() {
    log_info "Starting Traefik..."

    cd /opt/traefik
    docker compose up -d

    sleep 5

    if docker ps | grep -q traefik; then
        log_info "Traefik started successfully"
    else
        log_warn "Traefik may not have started correctly"
    fi
}

main() {
    log_info "Installing Traefik reverse proxy..."
    echo ""

    create_traefik_dir
    create_traefik_config
    create_docker_network
    create_docker_compose
    start_traefik

    echo ""
    log_info "Traefik installation complete!"
    log_info "Dashboard: https://${DOMAIN}/dashboard/"

    return 0
}

main "$@"
