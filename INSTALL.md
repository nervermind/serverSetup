# Quick Installation Guide

## Prerequisites Checklist

Before running the installer, make sure you have:

- [ ] Fresh Debian 13 server
- [ ] Root or sudo access
- [ ] Your SSH public key ready
- [ ] A domain name (if using reverse proxy)
- [ ] Console access backup (in case of SSH lockout)
- [ ] At least 1GB RAM and 5GB disk space

## Installation Methods

### Method 1: One-Line Install (Fastest)

**For interactive setup:**

```bash
curl -fsSL https://raw.githubusercontent.com/nervermind/serverSetup/main/setup.sh | sudo bash
```

The script will prompt you for all required information.

### Method 2: Pre-Configured Install

**1. Download configuration template:**

```bash
curl -fsSL https://raw.githubusercontent.com/nervermind/serverSetup/main/.env.sample -o .env
```

**2. Edit configuration:**

```bash
nano .env
```

**Minimum required settings:**

```bash
ADMIN_USERNAME=your_username
ADMIN_SSH_KEY="ssh-ed25519 AAAA... your@email.com"
PROXY_TYPE=traefik  # or nginx or none
DOMAIN=example.com
LETSENCRYPT_EMAIL=you@example.com
```

**3. Run installer:**

```bash
curl -fsSL https://raw.githubusercontent.com/USERNAME/REPO/main/setup.sh | sudo bash
```

### Method 3: Clone and Install

**1. Clone repository:**

```bash
git clone https://github.com/USERNAME/REPO.git
cd REPO
```

**2. Review scripts (recommended):**

```bash
less setup.sh
less scripts/02-ssh-hardening.sh  # Most critical
```

**3. Configure:**

```bash
cp .env.sample .env
nano .env
```

**4. Install:**

```bash
sudo bash setup.sh
```

### Method 4: Non-Interactive (Automation/CI)

**For CI/CD or automation:**

```bash
#!/bin/bash
export NON_INTERACTIVE=true
export ADMIN_USERNAME=deploy
export ADMIN_SSH_KEY="ssh-ed25519 AAAA..."
export SSH_PORT=22
export DISABLE_ROOT_LOGIN=yes
export PROXY_TYPE=traefik
export DOMAIN=example.com
export LETSENCRYPT_EMAIL=admin@example.com
export INSTALL_PORTAINER=yes
export ENABLE_AUTO_UPDATES=yes
export ENABLE_BACKUPS=yes
export BACKUP_PROVIDER=s3
export AWS_ACCESS_KEY_ID=AKIA...
export AWS_SECRET_ACCESS_KEY=secret...
export AWS_S3_BUCKET=my-backups

curl -fsSL https://raw.githubusercontent.com/USERNAME/REPO/main/setup.sh | sudo bash
```

## What Happens During Installation

### Phase 1: Preflight (2-3 minutes)
- OS verification
- Network connectivity check
- Disk space validation
- Package cache update

### Phase 2: User Setup (1 minute)
- Create admin user
- Configure sudo access
- Set up SSH keys

### Phase 3: Security Hardening (3-5 minutes)
- Configure firewall (UFW)
- Install and configure fail2ban
- Install and configure auditd
- Apply system hardening

### Phase 4: Docker Installation (5-10 minutes)
- Install Docker CE
- Install Docker Compose
- Apply Docker hardening
- Configure Docker networks

### Phase 5: Reverse Proxy (2-5 minutes)
- Install Traefik or Nginx
- Configure Let's Encrypt
- Set up HTTPS redirection

### Phase 6: Optional Services (1-3 minutes)
- Install Portainer (if selected)
- Configure backups
- Set up cloud storage

### Phase 7: SSH Hardening (1 minute)
- Apply SSH security settings
- Restart SSH service
- **⚠️ Test SSH access before continuing!**

### Phase 8: Validation (1-2 minutes)
- Run post-install tests
- Generate installation report

**Total Time: 15-30 minutes**

## Post-Installation Checklist

### Immediately After Installation

- [ ] **Test SSH in a NEW terminal** (don't close current session!)
  ```bash
  ssh -p ${SSH_PORT} ${ADMIN_USERNAME}@${SERVER_IP}
  ```

- [ ] Verify you can use sudo:
  ```bash
  sudo ls /root
  ```

- [ ] Only after SSH test succeeds, close old terminal

### Within First Hour

- [ ] Review installation report:
  ```bash
  cat /root/setup-report.txt
  ```

- [ ] Run health check:
  ```bash
  /opt/server-setup/scripts/15-healthcheck.sh
  ```

- [ ] Run full test suite:
  ```bash
  /opt/server-setup/test-suite.sh
  ```

- [ ] Check firewall status:
  ```bash
  sudo ufw status verbose
  ```

- [ ] Verify Docker is running:
  ```bash
  docker ps
  docker info
  ```

- [ ] If using Traefik, check dashboard:
  ```
  https://YOUR_DOMAIN/dashboard/
  ```

- [ ] If using Portainer, access UI:
  ```
  https://YOUR_SERVER_IP:9443
  ```

### Within First Day

- [ ] Run manual backup test:
  ```bash
  sudo /opt/server-setup/backup.sh
  ```

- [ ] Verify backups were created:
  ```bash
  ls -lh /opt/backups/
  ```

- [ ] Configure cloud backup (if enabled):
  ```bash
  sudo rclone config
  ```

- [ ] Test cloud sync:
  ```bash
  sudo /usr/local/bin/backup-to-cloud
  ```

- [ ] Review security logs:
  ```bash
  sudo fail2ban-client status sshd
  sudo ausearch -k docker
  ```

- [ ] Set up monitoring/alerting (optional)

## Common Configuration Examples

### Example 1: Minimal Setup

```bash
ADMIN_USERNAME=admin
ADMIN_SSH_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGq..."
SSH_PORT=22
DISABLE_ROOT_LOGIN=yes
PROXY_TYPE=none
INSTALL_PORTAINER=no
ENABLE_AUTO_UPDATES=yes
ENABLE_BACKUPS=no
```

### Example 2: Web Server with Traefik

```bash
ADMIN_USERNAME=webmaster
ADMIN_SSH_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGq..."
SSH_PORT=22
DISABLE_ROOT_LOGIN=yes
PROXY_TYPE=traefik
DOMAIN=myapp.com
LETSENCRYPT_EMAIL=admin@myapp.com
INSTALL_PORTAINER=yes
ENABLE_AUTO_UPDATES=yes
ENABLE_BACKUPS=yes
BACKUP_PROVIDER=s3
```

### Example 3: Development Server

```bash
ADMIN_USERNAME=developer
ADMIN_SSH_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGq..."
SSH_PORT=22
DISABLE_ROOT_LOGIN=no  # Keep root for testing
PROXY_TYPE=nginx
DOMAIN=dev.example.com
LETSENCRYPT_EMAIL=dev@example.com
INSTALL_PORTAINER=yes
ENABLE_AUTO_UPDATES=no  # Manual updates for dev
ENABLE_BACKUPS=yes
BACKUP_PROVIDER=spaces
```

## Troubleshooting Installation Issues

### Problem: Download Failed

```bash
# Test connectivity
ping -c 3 raw.githubusercontent.com

# Check DNS
dig raw.githubusercontent.com

# Try with wget instead
wget -qO- https://raw.githubusercontent.com/USERNAME/REPO/main/setup.sh | sudo bash
```

### Problem: Checksum Verification Failed

```bash
# This means files were corrupted or tampered
# DO NOT proceed - investigate why checksums don't match
# Download again or verify the repository
```

### Problem: Installation Hung

```bash
# Check logs in another terminal
tail -f /var/log/server-setup/install-*.log

# Check system resources
top
df -h
```

### Problem: SSH Connection Refused After Install

```bash
# From console access:
# 1. Check SSH service
systemctl status ssh

# 2. Check firewall
ufw status

# 3. Restore SSH config if needed
cp /root/server-setup-backup/ssh/sshd_config.* /etc/ssh/sshd_config
systemctl restart ssh
```

### Problem: Docker Won't Start

```bash
# Check Docker status
systemctl status docker

# View logs
journalctl -u docker -n 50

# Try resetting daemon config
mv /etc/docker/daemon.json /etc/docker/daemon.json.backup
systemctl restart docker
```

## Getting Help

If you encounter issues:

1. **Check logs**: `/var/log/server-setup/install-*.log`
2. **Run health check**: `/opt/server-setup/scripts/15-healthcheck.sh`
3. **Search issues**: https://github.com/USERNAME/REPO/issues
4. **Open new issue**: Include logs and system info

## Next Steps

After successful installation:

1. **Deploy your application** - Use Docker Compose
2. **Set up monitoring** - Consider Prometheus/Grafana
3. **Configure backups** - Test restore process
4. **Review security** - Regular audits
5. **Keep updated** - Watch for security updates

## Resources

- [Full Documentation](README.md)
- [Configuration Reference](.env.sample)
- [Troubleshooting Guide](README.md#troubleshooting)
- [Contributing](CONTRIBUTING.md)
- [Changelog](CHANGELOG.md)

---

**Remember**: Always test in a development environment first!
