#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

require_root

echo "==> Install Composer"
echo

apt_install curl php-cli unzip

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
