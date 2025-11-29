#!/usr/bin/env bash
#
# 08-proxy-install-nginx.sh - Nginx reverse proxy installation
#

set -euo pipefail

readonly GREEN='\033[0;32m'
readonly NC='\033[0m'

log_info() { echo -e "${GREEN}[NGINX]${NC} $*"; }

DOMAIN="${DOMAIN:-example.com}"
LETSENCRYPT_EMAIL="${LETSENCRYPT_EMAIL:-admin@example.com}"

install_nginx() {
    log_info "Installing Nginx..."

    apt-get install -y nginx certbot python3-certbot-nginx &>/dev/null

    log_info "Nginx installed"
}

configure_nginx() {
    log_info "Configuring Nginx..."

    # Remove default site
    rm -f /etc/nginx/sites-enabled/default

    # Create hardened nginx.conf
    cat > /etc/nginx/nginx.conf << 'EOF'
user www-data;
worker_processes auto;
pid /run/nginx.pid;

events {
    worker_connections 1024;
    use epoll;
}

http {
    # Basic
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;

    # MIME
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # SSL
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;

    # Logging
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    # Gzip
    gzip on;
    gzip_vary on;
    gzip_types text/plain text/css text/xml text/javascript application/json application/javascript application/xml+rss;

    # Include configs
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
EOF

    systemctl restart nginx

    log_info "Nginx configured"
}

obtain_certificate() {
    log_info "Obtaining Let's Encrypt certificate..."

    certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m "$LETSENCRYPT_EMAIL" || log_warn "Certificate request may have failed"

    log_info "Certificate configuration complete"
}

setup_auto_renewal() {
    log_info "Setting up auto-renewal..."

    systemctl enable certbot.timer
    systemctl start certbot.timer

    log_info "Auto-renewal enabled"
}

main() {
    log_info "Installing Nginx reverse proxy..."
    echo ""

    install_nginx
    configure_nginx

    if [[ -n "$DOMAIN" ]] && [[ "$DOMAIN" != "example.com" ]]; then
        obtain_certificate
        setup_auto_renewal
    fi

    echo ""
    log_info "Nginx installation complete!"

    return 0
}

main "$@"
