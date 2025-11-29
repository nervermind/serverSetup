#!/usr/bin/env bash
#
# 06-docker-hardening.sh - Docker daemon hardening
#

set -euo pipefail

readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

log_info() { echo -e "${GREEN}[DOCKER-HARDEN]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[DOCKER-HARDEN]${NC} $*"; }

configure_daemon() {
    log_info "Configuring Docker daemon..."

    mkdir -p /etc/docker

    cat > /etc/docker/daemon.json << 'EOF'
{
  "icc": false,
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "live-restore": true,
  "userland-proxy": false,
  "no-new-privileges": true,
  "seccomp-profile": "/etc/docker/seccomp-default.json",
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 64000,
      "Soft": 64000
    }
  }
}
EOF

    log_info "Docker daemon configured"
}

create_seccomp_profile() {
    log_info "Creating seccomp profile..."

    cat > /etc/docker/seccomp-default.json << 'EOF'
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "archMap": [
    {
      "architecture": "SCMP_ARCH_X86_64",
      "subArchitectures": [
        "SCMP_ARCH_X86",
        "SCMP_ARCH_X32"
      ]
    }
  ],
  "syscalls": [
    {
      "names": [
        "accept",
        "accept4",
        "access",
        "bind",
        "brk",
        "chmod",
        "chown",
        "clone",
        "close",
        "connect",
        "dup",
        "dup2",
        "dup3",
        "epoll_create",
        "epoll_create1",
        "epoll_ctl",
        "epoll_wait",
        "execve",
        "exit",
        "exit_group",
        "fchmod",
        "fchown",
        "fcntl",
        "fork",
        "fstat",
        "futex",
        "getcwd",
        "getdents",
        "getegid",
        "geteuid",
        "getgid",
        "getgroups",
        "getpeername",
        "getpid",
        "getppid",
        "getsockname",
        "getsockopt",
        "gettid",
        "getuid",
        "listen",
        "lseek",
        "mmap",
        "mprotect",
        "munmap",
        "nanosleep",
        "open",
        "openat",
        "pipe",
        "pipe2",
        "poll",
        "read",
        "readv",
        "recvfrom",
        "recvmsg",
        "rt_sigaction",
        "rt_sigprocmask",
        "rt_sigreturn",
        "sendmsg",
        "sendto",
        "setgid",
        "setgroups",
        "setsockopt",
        "setuid",
        "shutdown",
        "socket",
        "stat",
        "unlink",
        "wait4",
        "write",
        "writev"
      ],
      "action": "SCMP_ACT_ALLOW"
    }
  ]
}
EOF

    log_info "Seccomp profile created"
}

configure_docker_network() {
    log_info "Configuring Docker networks..."

    # Create custom bridge network
    if ! docker network ls | grep -q secure-network; then
        docker network create \
            --driver bridge \
            --subnet=172.20.0.0/16 \
            --opt "com.docker.network.bridge.name=docker_sec" \
            --opt "com.docker.network.bridge.enable_icc=false" \
            --opt "com.docker.network.bridge.enable_ip_masquerade=true" \
            secure-network
    fi

    log_info "Docker network configured"
}

fix_ufw_docker() {
    log_info "Fixing UFW for Docker..."

    # Create UFW after rules for Docker
    cat > /etc/ufw/after.rules.d/docker << 'EOF'
*filter
:DOCKER-USER - [0:0]
:ufw-user-input - [0:0]

# Allow all from Docker networks
-A DOCKER-USER -j RETURN

COMMIT
EOF

    systemctl restart ufw || true

    log_info "UFW-Docker integration configured"
}

restart_docker() {
    log_info "Restarting Docker..."

    systemctl daemon-reload
    systemctl restart docker

    sleep 3

    if systemctl is-active --quiet docker; then
        log_info "Docker restarted successfully"
    else
        log_warn "Docker restart may have failed"
    fi
}

main() {
    log_info "Starting Docker hardening..."
    echo ""

    configure_daemon
    create_seccomp_profile
    configure_docker_network
    fix_ufw_docker
    restart_docker

    echo ""
    log_info "Docker hardening complete!"

    return 0
}

main "$@"
