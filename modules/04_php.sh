#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

require_root
detect_os

remove_php_repositories() {
  rm -f /etc/apt/sources.list.d/ondrej-ubuntu-php-*.list || true
  rm -f /etc/apt/sources.list.d/ondrej-ubuntu-php-*.sources || true
  rm -f /etc/apt/sources.list.d/sury-php.list || true
  rm -f /etc/apt/keyrings/sury-php.gpg || true
}

remove_docker_wrappers() {
  rm -f /usr/local/bin/php84 || true

  if [[ -f /usr/local/bin/php ]] && grep -q 'php:8.4-cli' /usr/local/bin/php; then
    rm -f /usr/local/bin/php
  fi

  if [[ -f /usr/local/bin/composer ]] && grep -q 'composer:2' /usr/local/bin/composer; then
    rm -f /usr/local/bin/composer
  fi
}

remove_installed_php_packages() {
  local packages=()

  mapfile -t packages < <(
    dpkg-query -W -f='${binary:Package}\n' 'php*' 'libapache2-mod-php*' composer 2>/dev/null \
      | sort -u || true
  )

  if ((${#packages[@]})); then
    apt-get remove -y --purge "${packages[@]}" || true
  else
    echo "No installed PHP/Composer apt packages found."
  fi
}

install_php84_docker_wrapper() {
  if ! command_exists docker; then
    echo "ERROR: PHP 8.4 on Ubuntu ${OS_VERSION} (${OS_CODENAME}) uses a Docker wrapper."
    echo "Run module 'Install Docker + Compose plugin' first, then run this PHP module again."
    exit 1
  fi

  echo "==> Ubuntu ${OS_VERSION} (${OS_CODENAME}) does not use ondrej/php for PHP 8.4."
  echo "==> Installing PHP 8.4 through Docker CLI wrappers..."

  docker pull php:8.4-cli
  docker pull composer:2

  install -d -m 0755 /usr/local/bin

  cat > /usr/local/bin/php <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

TTY_ARGS=(-i)
if [[ -t 0 && -t 1 ]]; then
  TTY_ARGS=(-it)
fi

exec docker run --rm "${TTY_ARGS[@]}" \
  -v "$PWD":/app \
  -w /app \
  -v "$HOME/.composer":/tmp/composer \
  -e COMPOSER_HOME=/tmp/composer \
  php:8.4-cli php "$@"
EOF

  cat > /usr/local/bin/composer <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

TTY_ARGS=(-i)
if [[ -t 0 && -t 1 ]]; then
  TTY_ARGS=(-it)
fi

exec docker run --rm "${TTY_ARGS[@]}" \
  -v "$PWD":/app \
  -w /app \
  -v "$HOME/.composer":/tmp/composer \
  -e COMPOSER_HOME=/tmp/composer \
  composer:2 "$@"
EOF

  chmod 0755 /usr/local/bin/php /usr/local/bin/composer
  ln -sf /usr/local/bin/php /usr/local/bin/php84

  echo
  php -v | head -n 2 || true
  echo
  composer --version || true
  echo
  echo "✅ PHP 8.4 ready through Docker wrappers: /usr/local/bin/php, php84 and composer."
  echo "Note: PHP extensions for apps should live in the project Docker image/container."
}

echo "==> Install PHP (choose version)"
echo "Examples: 8.2, 8.3, 8.4, 8.5"
read -rp "PHP version [8.4]: " PHPV
PHPV="${PHPV:-8.4}"

if [[ "${OS_NAME}" != "ubuntu" && "${OS_NAME}" != "debian" ]]; then
  echo "ERROR: Unsupported OS for this module: ${OS_NAME}"
  exit 1
fi

echo "==> Removing old PHP/Composer (apt)..."

# Stop FPM services if present
systemctl stop php8.0-fpm php8.1-fpm php8.2-fpm php8.3-fpm php8.4-fpm php8.5-fpm 2>/dev/null || true

remove_docker_wrappers
remove_installed_php_packages
apt-get autoremove -y --purge || true
apt-get autoclean -y || true

remove_php_repositories

echo "==> Installing repo prerequisites..."
apt_install software-properties-common ca-certificates curl gnupg lsb-release apt-transport-https

if [[ "${OS_NAME}" == "ubuntu" && "${OS_CODENAME}" == "resolute" ]]; then
  if [[ "${PHPV}" == "8.4" ]]; then
    apt-get update -y || true
    install_php84_docker_wrapper
    exit 0
  fi

  if [[ "${PHPV}" != "8.5" ]]; then
    echo "ERROR: Ubuntu ${OS_VERSION} (${OS_CODENAME}) does not have PHP ${PHPV} in the native apt repository."
    echo "Use 8.5 for native apt, or 8.4 for the Docker wrapper."
    exit 1
  fi
fi

echo "==> Adding PHP repository..."

if [[ "${OS_NAME}" == "ubuntu" ]]; then
  if [[ "${OS_CODENAME}" == "resolute" ]]; then
    echo "==> Ubuntu ${OS_VERSION} (${OS_CODENAME}) detected; using native Ubuntu packages."
    apt-get update -y
  else
    # Ubuntu: use Ondrej PPA for multiple PHP versions when supported by the PPA.
    LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
    apt-get update -y
  fi

elif [[ "${OS_NAME}" == "debian" ]]; then
  # Debian: use Sury repository
  install -d -m 0755 /etc/apt/keyrings

  curl -fsSL https://packages.sury.org/php/apt.gpg \
    | gpg --dearmor -o /etc/apt/keyrings/sury-php.gpg

  CODENAME="$(. /etc/os-release && echo "${VERSION_CODENAME}")"
  echo "deb [signed-by=/etc/apt/keyrings/sury-php.gpg] https://packages.sury.org/php/ ${CODENAME} main" \
    > /etc/apt/sources.list.d/sury-php.list

  apt-get update -y
fi

echo "==> Installing PHP ${PHPV} + extensions..."
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

echo "==> Setting PHP ${PHPV} as default..."
update-alternatives --set php "/usr/bin/php${PHPV}" 2>/dev/null || true
update-alternatives --set phar "/usr/bin/phar${PHPV}" 2>/dev/null || true
update-alternatives --set phar.phar "/usr/bin/phar.phar${PHPV}" 2>/dev/null || true

echo
php -v | head -n 2 || true
echo
php -m | egrep -i 'dom|xml|simplexml|mbstring|curl|zip|intl' || true

echo "✅ PHP ${PHPV} installed and ready."
