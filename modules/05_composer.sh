#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

require_root

is_docker_php84_wrapper() {
  [[ -f /usr/local/bin/php ]] && grep -q 'php:8.4-cli' /usr/local/bin/php
}

is_docker_composer_wrapper() {
  [[ -f /usr/local/bin/composer ]] && grep -q 'composer:2' /usr/local/bin/composer
}

install_composer_docker_wrapper() {
  if ! command_exists docker; then
    echo "ERROR: Docker not found. Run module 'Install Docker + Compose plugin' first."
    exit 1
  fi

  docker pull composer:2

  install -d -m 0755 /usr/local/bin

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

  chmod 0755 /usr/local/bin/composer
}

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
  if is_docker_composer_wrapper; then
    echo "Composer is running through Docker image composer:2."
    echo "Use 'docker pull composer:2' to update the wrapper runtime."
  elif confirm "Update Composer to latest?"; then
    composer self-update
  fi
elif is_docker_php84_wrapper; then
  echo "==> PHP 8.4 Docker wrapper detected; installing Composer Docker wrapper..."
  install_composer_docker_wrapper
else
  curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php
  php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer
fi

composer --version
echo "✅ Composer ready."
