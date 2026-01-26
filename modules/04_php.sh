#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

require_root
detect_os

echo "==> Install PHP (choose version)"
echo "Examples: 8.2, 8.3, 8.4"
read -rp "PHP version [8.4]: " PHPV
PHPV="${PHPV:-8.4}"

if [[ "${OS_NAME}" != "ubuntu" && "${OS_NAME}" != "debian" ]]; then
  echo "❌ Unsupported OS for this module: ${OS_NAME}"
  exit 1
fi

echo "==> Removing old PHP/Composer from apt (safe cleanup)..."

# Para serviços se existirem (não explode se não existir)
systemctl stop php8.0-fpm php8.1-fpm php8.2-fpm php8.3-fpm php8.4-fpm 2>/dev/null || true

# Remove pacotes PHP instalados via apt (todas versões) + composer do apt
apt-get remove -y --purge \
  'php*' 'libapache2-mod-php*' 'php*-*' composer || true

apt-get autoremove -y --purge || true
apt-get autoclean -y || true

echo "==> Installing repo prerequisites..."
apt_install ca-certificates curl gnupg lsb-release apt-transport-https

# Repo Sury (packages.sury.org) - recomendado pra múltiplas versões PHP no Debian/Ubuntu
echo "==> Adding Sury PHP repository..."
install -d -m 0755 /etc/apt/keyrings

curl -fsSL https://packages.sury.org/php/apt.gpg \
  | gpg --dearmor -o /etc/apt/keyrings/sury-php.gpg

# Ubuntu noble / Debian bookworm etc
CODENAME="$(. /etc/os-release && echo "${VERSION_CODENAME}")"
echo "deb [signed-by=/etc/apt/keyrings/sury-php.gpg] https://packages.sury.org/php/ ${CODENAME} main" \
  > /etc/apt/sources.list.d/sury-php.list

apt-get update -y

echo "==> Installing PHP ${PHPV} + common extensions (CLI/FPM/XML/DOM/SimpleXML etc)..."
apt-get install -y \
  "php${PHPV}" \
  "php${PHPV}-cli" \
  "php${PHPV}-fpm" \
  "php${PHPV}-common" \
  "php${PHPV}-mbstring" \
  "php${PHPV}-xml" \
  "php${PHPV}-curl" \
  "php${PHPV}-zip" \
  "php${PHPV}-mysql" \
  "php${PHPV}-gd" \
  "php${PHPV}-bcmath" \
  "php${PHPV}-intl" \
  unzip

echo "==> Setting PHP ${PHPV} as default (cli tools)..."
update-alternatives --set php "/usr/bin/php${PHPV}" || true
update-alternatives --set phar "/usr/bin/phar${PHPV}" || true
update-alternatives --set phar.phar "/usr/bin/phar.phar${PHPV}" || true

php -v | head -n 2 || true
php -m | egrep -i 'dom|xml|simplexml|mbstring|curl|zip|intl' || true

echo "✅ PHP ${PHPV} installed + extensions ok."
