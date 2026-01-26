#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

require_root

DEFAULT_USER="devops"
DEFAULT_EMAIL="devops@localhost"
DEFAULT_KEY="id_ed25519"

echo "==> Create DevOps user + SSH key"
echo

read -rp "Username [${DEFAULT_USER}]: " USER_NAME
USER_NAME="${USER_NAME:-$DEFAULT_USER}"

read -rp "SSH email/comment [${DEFAULT_EMAIL}]: " SSH_EMAIL
SSH_EMAIL="${SSH_EMAIL:-$DEFAULT_EMAIL}"

read -rp "SSH key filename [${DEFAULT_KEY}]: " KEY_NAME
KEY_NAME="${KEY_NAME:-$DEFAULT_KEY}"

echo
echo "User: ${USER_NAME}"
echo "Email: ${SSH_EMAIL}"
echo "Key:  ${KEY_NAME}"
echo

if id -u "$USER_NAME" >/dev/null 2>&1; then
  echo "==> User '${USER_NAME}' already exists. Skipping."
else
  echo "==> Creating user '${USER_NAME}'..."
  adduser --gecos "" "$USER_NAME"
fi

echo "==> Adding '${USER_NAME}' to sudo group..."
usermod -aG sudo "$USER_NAME"

USER_HOME="$(getent passwd "$USER_NAME" | cut -d: -f6)"
SSH_DIR="${USER_HOME}/.ssh"
KEY_PATH="${SSH_DIR}/${KEY_NAME}"

echo "==> Preparing ${SSH_DIR}..."
install -d -m 700 -o "$USER_NAME" -g "$USER_NAME" "$SSH_DIR"

if [[ -f "$KEY_PATH" ]]; then
  echo "==> SSH key already exists: ${KEY_PATH}"
else
  echo "==> Generating SSH key (ed25519)..."
  sudo -u "$USER_NAME" ssh-keygen -t ed25519 -C "$SSH_EMAIL" -f "$KEY_PATH" -N ""
fi

chown -R "$USER_NAME:$USER_NAME" "$SSH_DIR"
chmod 700 "$SSH_DIR"
chmod 600 "$KEY_PATH" || true
chmod 644 "${KEY_PATH}.pub" || true

echo
echo "✅ Public key (add to GitHub):"
echo "------------------------------------------"
cat "${KEY_PATH}.pub"
echo "------------------------------------------"
