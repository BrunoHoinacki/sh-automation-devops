#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

require_root

DEFAULT_USER="devops"
DEFAULT_SHELL="/bin/bash"

echo "==> Create/update DevOps user"
echo

read -rp "Linux username [${DEFAULT_USER}]: " USER_NAME
USER_NAME="${USER_NAME:-$DEFAULT_USER}"

read -rp "Login shell [${DEFAULT_SHELL}]: " USER_SHELL
USER_SHELL="${USER_SHELL:-$DEFAULT_SHELL}"

if [[ ! -x "${USER_SHELL}" ]]; then
  echo "ERROR: shell '${USER_SHELL}' does not exist or is not executable."
  exit 1
fi

if id -u "${USER_NAME}" >/dev/null 2>&1; then
  echo "==> User '${USER_NAME}' already exists. Updating group membership..."
else
  echo "==> Creating user '${USER_NAME}'..."
  useradd -m -s "${USER_SHELL}" "${USER_NAME}"
fi

getent group docker >/dev/null 2>&1 || groupadd docker

usermod -aG sudo "${USER_NAME}"
usermod -aG docker "${USER_NAME}"

USER_HOME="$(getent passwd "${USER_NAME}" | cut -d: -f6)"

echo
echo "✅ User ready."
echo "User:   ${USER_NAME}"
echo "Home:   ${USER_HOME}"
echo "Shell:  $(getent passwd "${USER_NAME}" | cut -d: -f7)"
echo "Groups: $(id -nG "${USER_NAME}")"
echo
echo "Next steps:"
echo " - set a password if needed: passwd ${USER_NAME}"
echo " - after logging in as ${USER_NAME}, group changes apply on a new session"
