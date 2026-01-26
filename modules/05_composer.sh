#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

require_root

echo "==> Install Composer (official installer)"
echo

apt_install curl unzip

# remove composer do apt se existir (pra não misturar)
apt-get remove -y --purge composer || true
apt-get autoremove -y --purge || true

if ! command_exists php; then
  echo "❌ PHP not found. Run module 'Install PHP' first."
  exit 1
fi

if command_exists composer; then
  echo "==> Composer already installed:"
  composer --version
  echo
  if confirm "Update Composer to latest?"; then
    composer self-update
  fi
else
  curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php
  php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer
fi

composer --version
echo "✅ Composer ready."
