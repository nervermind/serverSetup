# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-01-26

### Added

#### Core Framework
- **curl-installable bootstrap script** (`setup.sh`)
  - One-line installation from GitHub
  - SHA256 checksum verification
  - Optional GPG signature verification
  - User confirmation prompts
  - Comprehensive logging
  - Idempotent execution

#### Security Hardening
- **SSH Hardening** (`02-ssh-hardening.sh`)
  - Strong cipher suites (ChaCha20-Poly1305, AES-256-GCM)
  - Key-only authentication
  - Ed25519 host key generation
  - Configurable SSH port
  - Optional root login disable
  - Automatic backup before changes

- **User Management** (`03-users.sh`)
  - Secure admin user creation
  - Passwordless sudo configuration
  - SSH key setup
  - PAM password quality enforcement
  - Login hardening (password aging, umask)

- **Firewall Configuration** (`04-firewall.sh`)
  - UFW installation and configuration
  - Default-deny incoming policy
  - SSH, HTTP, HTTPS rules
  - Docker-aware rules
  - Firewall management helper script

- **fail2ban** (`10-fail2ban.sh`)
  - SSH brute-force protection
  - Configurable ban times
  - Email notifications
  - Custom jail configurations

- **auditd** (`11-auditd.sh`)
  - System call monitoring
  - File integrity monitoring
  - Docker event auditing
  - User activity logging

#### Docker Stack
- **Docker CE Installation** (`05-docker-install.sh`)
  - Official Docker repository
  - Docker Compose v2
  - Docker Buildx plugin
  - User group configuration

- **Docker Hardening** (`06-docker-hardening.sh`)
  - Secure daemon configuration
  - Seccomp profiles
  - Log rotation limits
  - Network isolation (ICC disabled)
  - No new privileges flag
  - UFW-Docker integration

#### Reverse Proxy
- **Traefik** (`07-proxy-install-traefik.sh`)
  - Automatic HTTPS with Let's Encrypt
  - Docker label-based routing
  - TLS 1.2+ only
  - Secure dashboard access
  - HTTP to HTTPS redirection

- **Nginx** (`08-proxy-install-nginx.sh`)
  - Hardened nginx.conf
  - Certbot integration
  - Automatic certificate renewal
  - Modern TLS configuration

#### Optional Services
- **Portainer** (`09-portainer.sh`)
  - Docker GUI management
  - Secure deployment
  - Persistent data volume

#### Backup System
- **Backup Configuration** (`12-backups.sh`)
  - Automated daily backups
  - Docker volume backups
  - System configuration backups
  - Cron job setup
  - 7-day retention policy

- **Cloud Storage Integration** (`13-cloud-storage.sh`)
  - rclone installation
  - Multi-provider support:
    - AWS S3
    - Backblaze B2
    - DigitalOcean Spaces
    - S3-compatible storage
  - Sync script generation
  - Configuration templates

#### Utilities
- **Backup Script** (`backup.sh`)
  - Full system backup
  - Docker volumes and configs
  - Database dumps (MySQL, PostgreSQL)
  - User data backup
  - Cloud upload integration
  - Compression and encryption

- **Restore Script** (`restore.sh`)
  - Complete system restore
  - Selective restoration
  - Service restart management
  - Safety confirmations

- **Test Suite** (`test-suite.sh`)
  - 20+ automated tests
  - SSH security validation
  - Firewall rule verification
  - Docker configuration checks
  - Service health monitoring
  - Detailed test reports

- **Health Check** (`15-healthcheck.sh`)
  - Service status monitoring
  - Resource usage reporting
  - Docker container status
  - Firewall status
  - fail2ban status
  - System update check

#### Testing & Validation
- **Preflight Checks** (`01-preflight.sh`)
  - OS version verification
  - Architecture detection
  - Network connectivity test
  - Disk space validation
  - Memory check
  - Existing service detection

- **Post-Install Tests** (`14-postinstall-tests.sh`)
  - Component verification
  - Security configuration validation
  - Service status checks
  - Installation report generation

#### Documentation
- **Comprehensive README.md**
  - Quick start guide
  - Detailed installation instructions
  - Configuration reference
  - Security warnings
  - Troubleshooting guide
  - Architecture documentation

- **Configuration Template** (`.env.sample`)
  - All configurable options
  - Detailed comments
  - Multiple provider examples
  - Security best practices

- **This Changelog**
  - Complete feature list
  - Version history

#### Configuration & Deployment
- **Interactive Configuration**
  - User-friendly prompts
  - Sensible defaults
  - Validation checks
  - Configuration persistence

- **Non-Interactive Mode**
  - Environment variable support
  - CI/CD friendly
  - Automation ready

### Security Features

- SHA256 checksum verification for all downloaded scripts
- Optional GPG signature verification
- Secure secret handling (no plain-text storage)
- Comprehensive logging (but secrets excluded)
- Automatic configuration backups
- SSH lockout prevention measures
- Firewall-first approach
- Docker security profiles
- Audit logging for compliance

### Quality Features

- **Idempotent**: Safe to re-run multiple times
- **Modular**: Each component is a separate script
- **Tested**: Comprehensive test suite included
- **Logged**: Detailed logs for troubleshooting
- **Documented**: Inline comments and external docs
- **Colored Output**: Easy-to-read status messages
- **Error Handling**: Graceful failure with rollback options

### Supported Platforms

- Debian 13 (Trixie)
- x86_64 / amd64 architecture
- ARM64 architecture (tested)

### Known Limitations

- Designed specifically for Debian 13
- Requires root access
- Assumes fresh installation (minimal conflicts)
- Some features require manual configuration (cloud storage credentials)

### Breaking Changes

N/A - Initial release

### Deprecated

N/A - Initial release

### Removed

N/A - Initial release

### Fixed

N/A - Initial release

### Security

- All scripts downloaded over HTTPS
- Checksum verification before execution
- No execution of untrusted code
- Secrets never logged or stored in plain text
- SSH hardening applied last to prevent lockout

## [Unreleased]

### Planned Features

- Ansible playbook for declarative configuration
- Additional proxy options (Caddy, HAProxy)
- Monitoring stack (Prometheus, Grafana)
- Log aggregation (ELK stack)
- Container scanning integration
- Vulnerability assessment tools
- IPv6 support
- SELinux profile support
- Automated testing in CI/CD
- Multi-server orchestration

### Under Consideration

- Support for other Debian versions
- Ubuntu LTS support
- Rocky Linux / AlmaLinux support
- Kubernetes integration
- Service mesh support
- GitOps workflow

---

## Release Notes

### Version 1.0.0 - Initial Release

This is the first stable release of the Secure Server Setup Framework. It provides a complete, production-ready solution for setting up and hardening Debian 13 servers with Docker, reverse proxy, and automated backups.

**Key Highlights:**

✅ One-line curl installation
✅ Comprehensive security hardening
✅ Docker with best-practice security
✅ Choice of reverse proxy (Traefik/Nginx)
✅ Automated backups to cloud storage
✅ Full test suite included
✅ Idempotent and safe to re-run
✅ Detailed documentation

**Installation:**

```bash
curl -fsSL https://raw.githubusercontent.com/USERNAME/REPO/main/setup.sh | sudo bash
```

**Tested On:**
- Debian 13 (Trixie)
- Fresh installations
- 1GB+ RAM
- 5GB+ disk space

**Contributors:**
- Initial framework development

**Special Thanks:**
- Docker community
- Traefik team
- Debian security team
- Beta testers

---

For more information, see the [README.md](README.md).
