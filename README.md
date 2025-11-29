# Secure Server Setup Framework for Debian 13

A comprehensive, production-ready, curl-installable framework for setting up and hardening Debian 13 servers with Docker, reverse proxy, and automated backups.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Debian](https://img.shields.io/badge/Debian-13-red.svg)](https://www.debian.org/)
[![Docker](https://img.shields.io/badge/Docker-ready-blue.svg)](https://www.docker.com/)

## 🚀 Quick Start

**One-line installation:**

```bash
curl -fsSL https://raw.githubusercontent.com/nervermind/serverSetup/main/setup.sh | sudo bash
```

Or with wget:

```bash
wget -qO- https://raw.githubusercontent.com/nervermind/serverSetup/main/setup.sh | sudo bash
```

⚠️ **Before running**, please read the [Security Warnings](#-security-warnings) section below.

## 📋 Table of Contents

- [Features](#-features)
- [What Gets Installed](#-what-gets-installed)
- [Prerequisites](#-prerequisites)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Security Warnings](#-security-warnings)
- [Usage](#-usage)
- [Backup & Restore](#-backup--restore)
- [Testing](#-testing)
- [Troubleshooting](#-troubleshooting)
- [Architecture](#-architecture)
- [Contributing](#-contributing)
- [License](#-license)

## ✨ Features

### 🔒 Security Hardening
- SSH hardening with strong ciphers and key-only authentication
- Firewall configuration (UFW) with sensible defaults
- fail2ban for intrusion prevention
- auditd for system monitoring
- Secure user management with sudo access
- Automated security updates (optional)

### 🐳 Docker Stack
- Docker CE with security best practices
- Docker daemon hardening (no-new-privileges, seccomp profiles)
- Isolated Docker networks
- Docker user namespace support
- Log rotation and limits

### 🌐 Reverse Proxy
- **Traefik** (recommended) - Automatic HTTPS, Docker-native
- **Nginx** - Traditional reverse proxy with certbot
- Automatic Let's Encrypt SSL certificates
- HTTP to HTTPS redirection

### 💾 Backup System
- Automated daily backups
- Cloud storage integration (S3, Backblaze B2, DigitalOcean Spaces)
- Docker volume backups
- Database dumps (MySQL, PostgreSQL)
- System configuration backups
- Restoration utilities

### 🎯 Additional Features
- Portainer for Docker management (optional)
- Health check and monitoring scripts
- Comprehensive test suite
- Idempotent execution (safe to re-run)
- Detailed logging
- Color-coded output

## 📦 What Gets Installed

### Core Components
- Docker CE (latest stable)
- Docker Compose v2
- UFW (Uncomplicated Firewall)
- fail2ban
- auditd
- rclone (for cloud backups)

### Optional Components
- Traefik v2.10 (if selected)
- Nginx + certbot (if selected)
- Portainer CE (if selected)

### Security Configurations
- SSH hardening (Ed25519 keys, strong ciphers)
- Firewall rules (SSH, HTTP, HTTPS)
- System-level security settings
- Docker security profiles
- Audit rules for compliance

## 🔧 Prerequisites

- **OS**: Debian 13 (Trixie) - fresh installation recommended
- **Access**: Root or sudo access
- **Network**: Internet connectivity
- **Resources**:
  - Minimum 1 GB RAM
  - Minimum 5 GB disk space
  - SSH access

## 📥 Installation

### Method 1: One-Line Install (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/USERNAME/REPO/main/setup.sh | sudo bash
```

The installer will:
1. Show warning banners
2. Perform preflight checks
3. Prompt for configuration
4. Download and verify all scripts
5. Execute installation in phases
6. Generate detailed report

### Method 2: With Configuration File

1. Download the configuration template:

```bash
curl -fsSL https://raw.githubusercontent.com/USERNAME/REPO/main/.env.sample -o .env
```

2. Edit `.env` with your settings:

```bash
nano .env
```

3. Run the installer:

```bash
curl -fsSL https://raw.githubusercontent.com/USERNAME/REPO/main/setup.sh | sudo bash
```

### Method 3: Clone and Run

```bash
git clone https://github.com/USERNAME/REPO.git
cd REPO
cp .env.sample .env
# Edit .env with your settings
sudo bash setup.sh
```

### Method 4: Non-Interactive Mode

For automation and CI/CD:

```bash
export NON_INTERACTIVE=true
export ADMIN_USERNAME=myuser
export ADMIN_SSH_KEY="ssh-ed25519 AAAAC3..."
export DISABLE_ROOT_LOGIN=yes
export PROXY_TYPE=traefik
export DOMAIN=example.com
export LETSENCRYPT_EMAIL=admin@example.com

curl -fsSL https://raw.githubusercontent.com/USERNAME/REPO/main/setup.sh | sudo bash
```

## ⚙️ Configuration

### Required Configuration

```bash
ADMIN_USERNAME=admin                    # Your admin username
ADMIN_SSH_KEY="ssh-ed25519 AAAAC3..."  # Your SSH public key
```

### SSH Configuration

```bash
SSH_PORT=22                  # SSH port (change for security)
DISABLE_ROOT_LOGIN=yes       # Disable root SSH after setup
```

### Proxy Configuration

```bash
PROXY_TYPE=traefik          # traefik, nginx, or none
DOMAIN=example.com          # Your domain name
LETSENCRYPT_EMAIL=you@example.com
```

### Backup Configuration

```bash
ENABLE_BACKUPS=yes
BACKUP_PROVIDER=s3          # s3, b2, spaces, or s3-compatible
AWS_ACCESS_KEY_ID=xxx
AWS_SECRET_ACCESS_KEY=xxx
AWS_S3_BUCKET=my-backups
```

See [.env.sample](.env.sample) for all available options.

## ⚠️ Security Warnings

### SSH Lockout Prevention

**CRITICAL**: Improper SSH configuration can lock you out of your server!

Before running this script:

1. ✅ **Have your SSH public key ready** - You'll need it to access the server after hardening
2. ✅ **Keep a backup access method** - Console access through your hosting provider
3. ✅ **Test SSH in a separate terminal** - After hardening, test SSH before closing your current session
4. ✅ **Consider keeping root login enabled initially** - Until you verify the admin user works

### What Changes Will Be Made

This script will modify:
- `/etc/ssh/sshd_config` - SSH server configuration
- `/etc/ufw/` - Firewall rules
- `/etc/docker/` - Docker configuration
- System users and groups
- Installed packages

All original configurations are backed up to `/root/server-setup-backup/`.

### Verification

Always verify the script before running:

```bash
curl -fsSL https://raw.githubusercontent.com/USERNAME/REPO/main/setup.sh -o setup.sh
less setup.sh  # Review the script
sudo bash setup.sh
```

## 💻 Usage

### Post-Installation

After installation, test your setup:

```bash
# Run health check
/opt/server-setup/scripts/15-healthcheck.sh

# Run full test suite
/opt/server-setup/test-suite.sh

# Check installation report
cat /root/setup-report.txt
```

### Managing the Firewall

```bash
# Show firewall status
fw-manage status

# Allow a new port
fw-manage allow 8080/tcp "My App"

# List all rules
fw-manage list

# Delete a rule
fw-manage delete 3
```

### Docker Management

```bash
# View Docker containers
docker ps

# Access Portainer (if installed)
https://YOUR_IP:9443

# View Docker logs
docker logs <container-name>
```

### SSH Access

After installation, connect using:

```bash
ssh -p ${SSH_PORT} ${ADMIN_USERNAME}@YOUR_SERVER_IP
```

If you changed the SSH port:

```bash
ssh -p 2222 admin@YOUR_SERVER_IP
```

## 💾 Backup & Restore

### Manual Backup

```bash
/opt/server-setup/backup.sh
```

This creates a complete backup including:
- Docker volumes
- Docker configurations
- System configurations
- User data
- Database dumps

### Automated Backups

Backups run automatically at 2 AM daily (if enabled during setup).

View backup logs:

```bash
tail -f /var/log/backups.log
```

### Cloud Sync

If cloud backups are configured:

```bash
/usr/local/bin/backup-to-cloud
```

### Restore from Backup

```bash
# List available backups
ls -lh /opt/backups/

# Restore from backup
/opt/server-setup/restore.sh /opt/backups/backup-20250126-120000.tar.gz
```

⚠️ **Warning**: Restore will overwrite current configurations!

## 🧪 Testing

### Run Full Test Suite

```bash
/opt/server-setup/test-suite.sh
```

Tests include:
- SSH configuration and security
- Firewall rules
- Docker installation and hardening
- Security tools (fail2ban, auditd)
- User configuration
- Backup system
- System resources

### Individual Component Tests

```bash
# SSH test
/opt/server-setup/scripts/14-postinstall-tests.sh

# Health check
/opt/server-setup/scripts/15-healthcheck.sh
```

## 🔍 Troubleshooting

### Locked Out of SSH

If you're locked out after SSH hardening:

1. Access server console through your hosting provider
2. Log in as root (if root login disabled, use recovery mode)
3. Restore SSH config:

```bash
cp /root/server-setup-backup/ssh/sshd_config.* /etc/ssh/sshd_config
systemctl restart sshd
```

4. Re-configure SSH carefully

### Docker Not Starting

```bash
# Check Docker status
systemctl status docker

# View Docker logs
journalctl -u docker

# Reset Docker daemon config
mv /etc/docker/daemon.json /etc/docker/daemon.json.backup
systemctl restart docker
```

### Firewall Blocking Access

```bash
# Disable firewall temporarily (console access required)
ufw disable

# Check firewall rules
ufw status numbered

# Allow your IP
ufw allow from YOUR_IP
```

### View Installation Logs

```bash
# Latest installation log
ls -lt /var/log/server-setup/*.log | head -1 | awk '{print $9}' | xargs cat

# All logs
ls -lh /var/log/server-setup/
```

### Re-run Installation

The installer is idempotent and can be safely re-run:

```bash
curl -fsSL https://raw.githubusercontent.com/USERNAME/REPO/main/setup.sh | sudo bash
```

Existing configurations will be preserved unless explicitly overwritten.

## 🏗️ Architecture

### Directory Structure

```
/opt/server-setup/          # Main installation directory
├── .env                    # Configuration file
├── scripts/                # Installation scripts
│   ├── 01-preflight.sh
│   ├── 02-ssh-hardening.sh
│   ├── 03-users.sh
│   ├── 04-firewall.sh
│   ├── 05-docker-install.sh
│   ├── 06-docker-hardening.sh
│   ├── 07-proxy-install-traefik.sh
│   ├── 08-proxy-install-nginx.sh
│   ├── 09-portainer.sh
│   ├── 10-fail2ban.sh
│   ├── 11-auditd.sh
│   ├── 12-backups.sh
│   ├── 13-cloud-storage.sh
│   ├── 14-postinstall-tests.sh
│   └── 15-healthcheck.sh
├── backup.sh               # Backup utility
├── restore.sh              # Restore utility
└── test-suite.sh           # Test suite

/opt/backups/               # Backup storage
/var/log/server-setup/      # Installation logs
/root/server-setup-backup/  # Config backups
```

### Execution Flow

```
setup.sh (bootstrap)
    ↓
Preflight Checks
    ↓
Download & Verify Scripts
    ↓
Interactive Configuration
    ↓
Execute Installation Scripts
    ├── User Creation
    ├── Firewall Setup
    ├── Security Tools
    ├── Docker Installation
    ├── Docker Hardening
    ├── Proxy Installation
    ├── Backup Configuration
    └── SSH Hardening (last)
    ↓
Post-Install Tests
    ↓
Generate Report
```

## 🛡️ Security Best Practices

This framework implements:

- **SSH**: Key-only authentication, strong ciphers, rate limiting
- **Firewall**: Default-deny, minimal open ports
- **Docker**: Rootless where possible, seccomp profiles, read-only root fs
- **Secrets**: Never stored in plain text, encrypted at rest
- **Logging**: Comprehensive audit trails
- **Updates**: Automated security patches
- **Backups**: Encrypted, versioned, tested
- **Monitoring**: Intrusion detection, resource monitoring

## 📚 Additional Resources

- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [SSH Hardening Guide](https://www.ssh.com/academy/ssh/security)
- [Debian Security Manual](https://www.debian.org/doc/manuals/securing-debian-manual/)
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks/)

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Docker team for excellent containerization platform
- Traefik team for modern reverse proxy
- Debian team for rock-solid OS
- Community contributors

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/USERNAME/REPO/issues)
- **Discussions**: [GitHub Discussions](https://github.com/USERNAME/REPO/discussions)
- **Security**: Please report security issues privately to security@example.com

---

**⚠️ Important**: Always test in a development environment before deploying to production.

**Made with ❤️ for the DevOps community**
