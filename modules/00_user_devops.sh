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

set_user_password() {
  local attempt
  for attempt in 1 2 3; do
    if passwd "${USER_NAME}"; then
      return 0
    fi
    echo "Password not changed, try again (${attempt}/3)."
  done
  echo "⚠️  Password not set. Run later as root: passwd ${USER_NAME}"
}

# passwd -S status: P = usable password, L = locked, NP = no password
PASS_STATUS="$(passwd -S "${USER_NAME}" 2>/dev/null | awk '{print $2}')"

echo
if [[ "${PASS_STATUS}" == "P" ]]; then
  if confirm "User already has a password. Change it?"; then
    set_user_password
  fi
else
  echo "==> User '${USER_NAME}' has no password yet (needed for sudo)."
  set_user_password
fi

USER_HOME="$(getent passwd "${USER_NAME}" | cut -d: -f6)"

echo
echo "✅ User ready."
echo "User:   ${USER_NAME}"
echo "Home:   ${USER_HOME}"
echo "Shell:  $(getent passwd "${USER_NAME}" | cut -d: -f7)"
echo "Groups: $(id -nG "${USER_NAME}")"
echo "Password: $(passwd -S "${USER_NAME}" 2>/dev/null | awk '{print ($2 == "P") ? "set" : "NOT set"}')"
echo
echo "Next steps:"
echo " - after logging in as ${USER_NAME}, group changes apply on a new session"
