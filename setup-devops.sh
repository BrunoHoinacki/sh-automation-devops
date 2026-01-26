#!/usr/bin/env bash
set -euo pipefail

# ==========================================
# Setup DevOps user + SSH key (Ubuntu/Debian)
# - Creates user
# - Adds to sudo group
# - Generates SSH key (ed25519)
# - Prints public key to add on GitHub
# ==========================================

USER_NAME="${1:-devops}"
SSH_EMAIL="${2:-devops@localhost}"
KEY_NAME="${3:-id_ed25519}"

echo "==> Starting setup for user: ${USER_NAME}"
echo "==> SSH email/comment: ${SSH_EMAIL}"
echo "==> Key name: ${KEY_NAME}"
echo

if [[ "$EUID" -ne 0 ]]; then
  echo "ERROR: run as root (or use sudo)."
  exit 1
fi

# 1) Create user if needed
if id -u "$USER_NAME" >/dev/null 2>&1; then
  echo "==> User '${USER_NAME}' already exists. Skipping adduser."
else
  echo "==> Creating user '${USER_NAME}'..."
  adduser --gecos "" "$USER_NAME"
fi

# 2) Add to sudo group
echo "==> Adding '${USER_NAME}' to sudo group..."
usermod -aG sudo "$USER_NAME"

# 3) Prepare .ssh
USER_HOME="$(getent passwd "$USER_NAME" | cut -d: -f6)"
SSH_DIR="${USER_HOME}/.ssh"
KEY_PATH="${SSH_DIR}/${KEY_NAME}"

echo "==> Ensuring ${SSH_DIR} exists..."
install -d -m 700 -o "$USER_NAME" -g "$USER_NAME" "$SSH_DIR"

# 4) Generate key if it doesn't exist
if [[ -f "${KEY_PATH}" ]]; then
  echo "==> SSH key already exists: ${KEY_PATH}"
else
  echo "==> Generating SSH key for ${USER_NAME}..."
  sudo -u "$USER_NAME" ssh-keygen -t ed25519 -C "$SSH_EMAIL" -f "$KEY_PATH" -N ""
fi

# 5) Ensure permissions
chown -R "$USER_NAME:$USER_NAME" "$SSH_DIR"
chmod 700 "$SSH_DIR"
chmod 600 "${KEY_PATH}" || true
chmod 644 "${KEY_PATH}.pub" || true

# 6) Output
echo
echo "=========================================================="
echo "✅ Done!"
echo "User: ${USER_NAME}"
echo "Home: ${USER_HOME}"
echo "Key:  ${KEY_PATH}"
echo
echo "👉 Public key (add to GitHub -> Settings -> SSH keys):"
echo "----------------------------------------------------------"
cat "${KEY_PATH}.pub"
echo "----------------------------------------------------------"
echo
echo "Test as the user:"
echo "  su - ${USER_NAME}"
echo "  ssh -T git@github.com"
echo "=========================================================="
