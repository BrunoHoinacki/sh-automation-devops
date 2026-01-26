#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

require_root

echo "==> Install PHP (choose version)"
echo "Examples: 8.1, 8.2, 8.3"
read -rp "PHP version [8.3]: " PHPV
PHPV="${PHPV:-8.3}"

echo "==> Installing PHP ${PHPV}..."

apt_install software-properties-common ca-certificates lsb-release apt-transport-https

# ondrej/php is the common path on Ubuntu for multiple PHP versions
add-apt-repository -y ppa:ondrej/php
apt-get update -y

apt-get install -y \
  "php${PHPV}" \
  "php${PHPV}-cli" \
  "php${PHPV}-fpm" \
  "php${PHPV}-mbstring" \
  "php${PHPV}-xml" \
  "php${PHPV}-curl" \
  "php${PHPV}-zip" \
  "php${PHPV}-mysql" \
  "php${PHPV}-gd" \
  unzip

php -v | head -n 2 || true
echo "✅ PHP ${PHPV} installed."
