#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

require_root

echo "==> Open ports (listening)"
echo

apt_install ufw

echo "Listening ports (TCP/UDP):"
ss -tulpn | sed -n '1,25p'
echo

echo "UFW status:"
ufw status verbose || true
echo

SSH_PORT="$(detect_ssh_port)"

if ! confirm "Do you want to enable UFW now?"; then
  echo "Skipping UFW enable."
else
  # Always allow SSH BEFORE enabling, otherwise default 'deny incoming' locks us out
  echo "==> Allowing SSH on port ${SSH_PORT}/tcp before enabling UFW"
  ufw allow "${SSH_PORT}/tcp" comment 'SSH'
  if confirm "Allow HTTP/HTTPS (80, 443)?"; then
    ufw allow 80/tcp comment 'HTTP'
    ufw allow 443/tcp comment 'HTTPS'
  fi
  ufw --force enable
fi

echo
read -rp "Enter a port number to BLOCK (ex: 80) or press ENTER to skip: " PORT
if [[ -z "${PORT}" ]]; then
  echo "No port selected."
  exit 0
fi

if [[ "${PORT}" == "${SSH_PORT}" ]]; then
  echo "❌ Refusing to block the SSH port (${SSH_PORT}) — you would lose access."
  exit 1
fi

read -rp "Protocol [tcp/udp/both] (default tcp): " PROTO
PROTO="${PROTO:-tcp}"

case "${PROTO}" in
  tcp|udp)
    ufw deny "${PORT}/${PROTO}"
    ;;
  both)
    ufw deny "${PORT}/tcp"
    ufw deny "${PORT}/udp"
    ;;
  *)
    echo "Invalid protocol. Using tcp."
    ufw deny "${PORT}/tcp"
    ;;
esac

echo
echo "✅ Updated firewall rules:"
ufw status numbered
