#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

require_root

disable_service_if_exists() {
  local service="$1"

  if ! systemctl list-unit-files "${service}.service" >/dev/null 2>&1; then
    echo "==> ${service}: service not found, skipping."
    return
  fi

  echo "==> Stopping ${service}..."
  systemctl stop "${service}" 2>/dev/null || true

  echo "==> Disabling ${service} on boot..."
  systemctl disable "${service}" 2>/dev/null || true

  echo "==> Mask ${service} to prevent accidental starts?"
  if confirm "Mask ${service}.service"; then
    systemctl mask "${service}" 2>/dev/null || true
  fi

  echo "==> ${service} status:"
  systemctl is-active "${service}" || true
  systemctl is-enabled "${service}" 2>/dev/null || true
  echo
}

echo "==> Disable native VPS web servers"
echo
echo "This stops Apache/Nginx installed directly on the VPS and disables them on boot."
echo "Useful before running Traefik on ports 80/443."
echo

disable_service_if_exists apache2
disable_service_if_exists nginx

echo "==> Listening on ports 80/443 after changes:"
ss -tulpn '( sport = :80 or sport = :443 )' || true
echo
echo "✅ Native Apache/Nginx services handled."
