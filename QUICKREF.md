# Quick Reference Guide

## 🚀 Installation

```bash
# One-line install
curl -fsSL https://raw.githubusercontent.com/nervermind/serverSetup/main/setup.sh | sudo bash
```

## 🔧 Common Commands

### System Health
```bash
# Full health check
/opt/server-setup/scripts/15-healthcheck.sh

# Run test suite
/opt/server-setup/test-suite.sh

# View installation report
cat /root/setup-report.txt

# Check logs
tail -f /var/log/server-setup/install-*.log
```

### Firewall Management
```bash
# Show status
fw-manage status
sudo ufw status verbose

# Allow port
fw-manage allow 8080/tcp "My App"

# List rules
fw-manage list

# Delete rule
fw-manage delete 3

# Reload firewall
sudo ufw reload
```

### Docker Operations
```bash
# View containers
docker ps
docker ps -a

# View logs
docker logs <container>
docker logs -f <container>  # Follow

# Execute command
docker exec -it <container> bash

# View networks
docker network ls

# View volumes
docker volume ls

# System prune (cleanup)
docker system prune -a
```

### SSH Management
```bash
# Test SSH config
sudo sshd -t

# Restart SSH
sudo systemctl restart ssh

# View SSH logs
sudo tail -f /var/log/auth.log

# Check SSH status
sudo systemctl status ssh
```

### Security Tools
```bash
# fail2ban status
sudo fail2ban-client status
sudo fail2ban-client status sshd

# Unban IP
sudo fail2ban-client set sshd unbanip <IP>

# View audit logs
sudo ausearch -k docker
sudo ausearch -k auth

# Check auditd status
sudo systemctl status auditd
```

### Backup & Restore
```bash
# Manual backup
sudo /opt/server-setup/backup.sh

# List backups
ls -lh /opt/backups/

# Restore from backup
sudo /opt/server-setup/restore.sh /opt/backups/backup-*.tar.gz

# Sync to cloud
sudo /usr/local/bin/backup-to-cloud

# View backup logs
tail -f /var/log/backups.log
```

### Service Management
```bash
# Check service status
sudo systemctl status <service>

# Start/stop/restart
sudo systemctl start <service>
sudo systemctl stop <service>
sudo systemctl restart <service>

# Enable/disable at boot
sudo systemctl enable <service>
sudo systemctl disable <service>

# View service logs
sudo journalctl -u <service>
sudo journalctl -u <service> -f  # Follow
```

## 📋 Configuration Files

### Main Configuration
```
/opt/server-setup/.env              # Main config
/opt/server-setup/.env.sample       # Template
```

### SSH
```
/etc/ssh/sshd_config               # Main config
/etc/ssh/sshd_config.d/            # Additional configs
/root/server-setup-backup/ssh/     # Backups
```

### Firewall
```
/etc/ufw/                          # UFW config
/usr/local/bin/fw-manage           # Helper script
```

### Docker
```
/etc/docker/daemon.json            # Docker daemon config
/etc/docker/seccomp-default.json   # Security profile
/opt/traefik/                      # Traefik config (if installed)
/etc/nginx/                        # Nginx config (if installed)
```

### Security
```
/etc/fail2ban/jail.local           # fail2ban config
/etc/audit/rules.d/hardening.rules # Audit rules
```

## 🔍 Troubleshooting

### SSH Locked Out
```bash
# From console:
sudo cp /root/server-setup-backup/ssh/sshd_config.* /etc/ssh/sshd_config
sudo systemctl restart ssh
```

### Docker Not Starting
```bash
# Check status
sudo systemctl status docker

# View logs
sudo journalctl -u docker -n 50

# Reset config
sudo mv /etc/docker/daemon.json /etc/docker/daemon.json.backup
sudo systemctl restart docker
```

### Firewall Blocking
```bash
# Disable temporarily (console only!)
sudo ufw disable

# Allow your IP
sudo ufw allow from YOUR_IP

# Re-enable
sudo ufw enable
```

### Check Service Ports
```bash
# All listening ports
sudo ss -tulpn

# Specific port
sudo lsof -i :80
sudo lsof -i :443
```

## 📊 Monitoring

### Resource Usage
```bash
# CPU and memory
top
htop

# Disk usage
df -h
du -sh /*

# Network connections
ss -s
netstat -i
```

### Docker Resources
```bash
# Container stats
docker stats

# Disk usage
docker system df

# Top processes in container
docker top <container>
```

### Logs
```bash
# System log
sudo journalctl -xe

# Specific service
sudo journalctl -u docker

# Kernel messages
sudo dmesg

# Authentication
sudo tail -f /var/log/auth.log
```

## 🛠️ Maintenance

### Updates
```bash
# Update package list
sudo apt update

# Upgrade packages
sudo apt upgrade

# Dist upgrade
sudo apt dist-upgrade

# Clean up
sudo apt autoremove
sudo apt autoclean
```

### Docker Maintenance
```bash
# Update containers
docker compose pull
docker compose up -d

# Cleanup
docker system prune -a --volumes

# Update Docker
sudo apt update && sudo apt upgrade docker-ce
```

### SSL Certificates
```bash
# Renew Let's Encrypt (Traefik auto-renews)

# Manual renew (Nginx)
sudo certbot renew

# Check certificate
echo | openssl s_client -connect DOMAIN:443 2>/dev/null | openssl x509 -noout -dates
```

## 📱 Quick Checks

### Is everything running?
```bash
sudo systemctl status ssh docker ufw fail2ban auditd
```

### Are ports open?
```bash
sudo ufw status
sudo ss -tulpn | grep LISTEN
```

### Any failed services?
```bash
sudo systemctl --failed
```

### Disk space OK?
```bash
df -h | grep -v tmpfs
```

### Recent logins?
```bash
last -n 10
lastlog
```

### Any banned IPs?
```bash
sudo fail2ban-client status sshd
```

## 🔐 Security Checks

### Check for rootkits
```bash
# Install rkhunter
sudo apt install rkhunter

# Update and scan
sudo rkhunter --update
sudo rkhunter --check
```

### Check listening services
```bash
sudo ss -tulpn | grep LISTEN
```

### Review user accounts
```bash
cat /etc/passwd | grep -v nologin
```

### Check sudo access
```bash
sudo cat /etc/sudoers.d/*
```

### Review firewall logs
```bash
sudo grep UFW /var/log/syslog | tail -20
```

## 🎯 Common Tasks

### Add New Docker Service
```bash
cd /opt/myapp
nano docker-compose.yml
docker compose up -d
```

### Add New Domain to Proxy
```bash
# Traefik: Add labels to docker-compose.yml
# Nginx: Create new site config in /etc/nginx/sites-available/
```

### Change SSH Port
```bash
sudo nano /etc/ssh/sshd_config.d/99-hardening.conf
# Change Port value
sudo ufw allow NEW_PORT/tcp
sudo systemctl restart ssh
# Test before removing old port!
```

### Add New Firewall Rule
```bash
fw-manage allow PORT/tcp "Description"
```

## 📞 Emergency Contacts

- Console Access: Through hosting provider
- Backup Admin: [Contact info]
- Hosting Support: [Contact info]

## 📚 Resources

- Full Docs: [README.md](README.md)
- Install Guide: [INSTALL.md](INSTALL.md)
- Troubleshooting: README.md#troubleshooting

---

**Keep this file handy for quick reference!**
