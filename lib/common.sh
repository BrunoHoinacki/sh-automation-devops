#!/usr/bin/env bash
set -euo pipefail

OS_NAME="unknown"
OS_VERSION="unknown"

require_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo "ERROR: Please run as root or using sudo."
    exit 1
  fi
}

pause() {
  read -rp "Press ENTER to continue..."
}

detect_os() {
  if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release

    # ID costuma ser "ubuntu" / "debian" (ótimo pra lógica)
    OS_NAME="${ID:-${NAME:-unknown}}"
    OS_VERSION="${VERSION_ID:-unknown}"

    # normaliza pra minúsculo (evita esses bugs pra sempre)
    OS_NAME="$(echo "${OS_NAME}" | tr '[:upper:]' '[:lower:]')"
  fi
}

confirm() {
  local prompt="${1:-Are you sure?}"
  read -rp "${prompt} [y/N]: " yn
  [[ "${yn,,}" == "y" || "${yn,,}" == "yes" ]]
}

apt_install() {
  # Usage: apt_install pkg1 pkg2 ...
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get install -y "$@"
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}
