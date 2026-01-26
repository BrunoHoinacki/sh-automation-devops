#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

require_root

DEFAULT_USER="devops"
DEFAULT_EMAIL="devops@localhost"
DEFAULT_KEY="id_ed25519"

echo "==> GitHub SSH setup (generate key + test)"
echo

read -rp "Linux username to own the SSH key [${DEFAULT_USER}]: " USER_NAME
USER_NAME="${USER_NAME:-$DEFAULT_USER}"

if ! id -u "$USER_NAME" >/dev/null 2>&1; then
  echo "ERROR: user '${USER_NAME}' does not exist."
  echo "Create the user first, then re-run this module."
  exit 1
fi

read -rp "SSH email/comment [${DEFAULT_EMAIL}]: " SSH_EMAIL
SSH_EMAIL="${SSH_EMAIL:-$DEFAULT_EMAIL}"

read -rp "SSH key filename (inside ~/.ssh) [${DEFAULT_KEY}]: " KEY_NAME
KEY_NAME="${KEY_NAME:-$DEFAULT_KEY}"

USER_HOME="$(getent passwd "$USER_NAME" | cut -d: -f6)"
SSH_DIR="${USER_HOME}/.ssh"
KEY_PATH="${SSH_DIR}/${KEY_NAME}"

echo
echo "User: ${USER_NAME}"
echo "Home: ${USER_HOME}"
echo "Key:  ${KEY_PATH}"
echo

echo "==> Preparing ${SSH_DIR}..."
install -d -m 700 -o "$USER_NAME" -g "$USER_NAME" "$SSH_DIR"

# Generate key if missing
if [[ -f "$KEY_PATH" && -f "${KEY_PATH}.pub" ]]; then
  echo "==> SSH key already exists. Skipping generation."
else
  echo "==> Generating SSH key (ed25519)..."
  sudo -u "$USER_NAME" ssh-keygen -t ed25519 -C "$SSH_EMAIL" -f "$KEY_PATH" -N ""
fi

# Permissions
chown -R "$USER_NAME:$USER_NAME" "$SSH_DIR"
chmod 700 "$SSH_DIR"
chmod 600 "$KEY_PATH" || true
chmod 644 "${KEY_PATH}.pub" || true

echo
echo "=========================================================="
echo "✅ Public key (copy/paste into GitHub -> Settings -> SSH keys)"
echo "----------------------------------------------------------"
cat "${KEY_PATH}.pub"
echo "----------------------------------------------------------"
echo
echo "Now add this key to GitHub."
echo "When you're done, come back here and press ENTER to test."
echo "=========================================================="
read -rp "Press ENTER to test GitHub SSH authentication..."

echo
echo "==> Testing SSH auth with GitHub (as ${USER_NAME})..."
echo "If asked to trust github.com fingerprint, type 'yes'."
echo

# Ensure known_hosts exists for that user (avoid permission weirdness)
sudo -u "$USER_NAME" bash -lc "mkdir -p ~/.ssh && chmod 700 ~/.ssh && touch ~/.ssh/known_hosts && chmod 644 ~/.ssh/known_hosts"

# Test connection
# NOTE: This will print the standard GitHub message on success.
set +e
sudo -u "$USER_NAME" ssh -T git@github.com
STATUS=$?
set -e

echo
if [[ $STATUS -eq 1 || $STATUS -eq 0 ]]; then
  # GitHub commonly returns exit code 1 even on success ("no shell access")
  echo "✅ SSH test completed. If you saw:"
  echo "   \"You've successfully authenticated\""
  echo "then you're good."
else
  echo "❌ SSH test failed with exit code: ${STATUS}"
  echo "Common fixes:"
  echo " - confirm the public key was added to GitHub"
  echo " - ensure you're using the correct key file: ${KEY_PATH}"
  echo " - check permissions on ~/.ssh and key files"
  exit $STATUS
fi
