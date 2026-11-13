#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

require_root

SSHD_DROPIN="/etc/ssh/sshd_config.d/99-devops-hardening.conf"
SYSCTL_FILE="/etc/sysctl.d/99-devops-hardening.conf"
F2B_JAIL="/etc/fail2ban/jail.d/99-devops.local"

ssh_service_name() {
  if systemctl list-unit-files ssh.service 2>/dev/null | grep -q '^ssh\.service'; then
    echo "ssh"
  else
    echo "sshd"
  fi
}

# Returns 0 if root or any sudo user has a non-empty authorized_keys file
has_authorized_keys() {
  local user home
  for user in root $(getent group sudo | cut -d: -f4 | tr ',' ' '); do
    home="$(getent passwd "${user}" | cut -d: -f6)"
    [[ -n "${home}" && -s "${home}/.ssh/authorized_keys" ]] && return 0
  done
  return 1
}

echo "==> Server security hardening"
echo
echo "This will:"
echo " - install and enable fail2ban (sshd + recidive jails)"
echo " - enable UFW (deny incoming, allow SSH and optionally 80/443)"
echo " - enable unattended security upgrades"
echo " - apply kernel/network sysctl hardening"
echo " - harden SSH (asks before disabling password login)"
echo

if ! confirm "Continue?"; then
  echo "Aborted."
  exit 0
fi

SSH_PORT="$(detect_ssh_port)"
SSH_SERVICE="$(ssh_service_name)"
echo "==> Detected SSH port: ${SSH_PORT} (service: ${SSH_SERVICE})"
echo

apt_install fail2ban python3-systemd ufw unattended-upgrades apt-listchanges

# ------------------------------------------------------------------
# Fail2ban
# ------------------------------------------------------------------
echo
echo "==> Configuring fail2ban..."

read -rp "IPs/CIDRs to never ban (space separated, ENTER to skip): " IGNORE_IPS

cat > "${F2B_JAIL}" <<EOF
# Managed by sh-automation-devops (09_security_hardening.sh)
[DEFAULT]
ignoreip  = 127.0.0.1/8 ::1 ${IGNORE_IPS}
bantime   = 1h
findtime  = 10m
maxretry  = 5
backend   = systemd
banaction = ufw
bantime.increment = true
bantime.maxtime   = 1w

[sshd]
enabled  = true
port     = ${SSH_PORT}
mode     = aggressive
maxretry = 4

# Bans repeat offenders (banned several times) for one week
[recidive]
enabled  = true
backend  = auto
logpath  = /var/log/fail2ban.log
bantime  = 1w
findtime = 1d
maxretry = 3
EOF

systemctl enable fail2ban >/dev/null
systemctl restart fail2ban
sleep 2
fail2ban-client status || true

# ------------------------------------------------------------------
# UFW
# ------------------------------------------------------------------
echo
echo "==> Configuring UFW..."

ufw default deny incoming
ufw default allow outgoing
ufw limit "${SSH_PORT}/tcp" comment 'SSH (rate limited)'

if confirm "Allow HTTP/HTTPS (80, 443)?"; then
  ufw allow 80/tcp comment 'HTTP'
  ufw allow 443/tcp comment 'HTTPS'
fi

ufw --force enable
ufw status verbose

# ------------------------------------------------------------------
# Unattended upgrades (security only, no automatic reboot)
# ------------------------------------------------------------------
echo
echo "==> Enabling unattended security upgrades..."

cat > /etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF

systemctl enable --now unattended-upgrades >/dev/null 2>&1 || true

# ------------------------------------------------------------------
# Sysctl hardening (keeps ip_forward untouched for Docker)
# ------------------------------------------------------------------
echo
echo "==> Applying sysctl hardening..."

cat > "${SYSCTL_FILE}" <<'EOF'
# Managed by sh-automation-devops (09_security_hardening.sh)
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
kernel.yama.ptrace_scope = 1
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
EOF

sysctl --system >/dev/null
echo "Applied ${SYSCTL_FILE}"

# ------------------------------------------------------------------
# SSH hardening
# ------------------------------------------------------------------
echo
echo "==> Hardening SSH..."

SSH_LOCKDOWN="no"
if has_authorized_keys; then
  echo "SSH keys found in authorized_keys (root or sudo users)."
  echo "⚠️  Make sure you can log in with a key BEFORE confirming."
  if confirm "Disable password login and allow root only with key?"; then
    SSH_LOCKDOWN="yes"
  fi
else
  echo "⚠️  No authorized_keys found for root or sudo users."
  echo "    Password login will stay enabled to avoid locking you out."
  echo "    Use menu option 1 + add your public key, then run this again."
fi

mkdir -p /etc/ssh/sshd_config.d
{
  echo "# Managed by sh-automation-devops (09_security_hardening.sh)"
  echo "MaxAuthTries 4"
  echo "LoginGraceTime 30"
  echo "PermitEmptyPasswords no"
  echo "KbdInteractiveAuthentication no"
  echo "X11Forwarding no"
  echo "ClientAliveInterval 300"
  echo "ClientAliveCountMax 2"
  if [[ "${SSH_LOCKDOWN}" == "yes" ]]; then
    echo "PermitRootLogin prohibit-password"
    echo "PasswordAuthentication no"
  fi
} > "${SSHD_DROPIN}"

if sshd -t; then
  systemctl reload "${SSH_SERVICE}" || systemctl restart "${SSH_SERVICE}"
  echo "SSH config applied (${SSHD_DROPIN})."
else
  echo "❌ Invalid sshd config, reverting ${SSHD_DROPIN}."
  rm -f "${SSHD_DROPIN}"
fi

# ------------------------------------------------------------------
# Summary
# ------------------------------------------------------------------
echo
echo "✅ Security hardening finished."
echo
echo "fail2ban:  $(systemctl is-active fail2ban)"
echo "UFW:       $(ufw status | head -n1)"
echo "SSH port:  ${SSH_PORT} (password login disabled: ${SSH_LOCKDOWN})"
echo
echo "Useful commands:"
echo " - fail2ban-client status sshd"
echo " - fail2ban-client set sshd unbanip <IP>"
echo " - ufw status numbered"
echo
echo "Note: ports published by Docker (-p) bypass UFW rules."
echo "      Bind internal services to 127.0.0.1 or use a reverse proxy."
echo "⚠️  Keep this session open and test a NEW SSH login before disconnecting."
