#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"
MODULES_DIR="${SCRIPT_DIR}/modules"

# shellcheck source=lib/common.sh
source "${LIB_DIR}/common.sh"

require_root
detect_os

run_module() {
  local file="$1"
  bash "${MODULES_DIR}/${file}"
}

while true; do
  clear
  echo "=========================================="
  echo "   DevOps Automation Toolbox"
  echo "=========================================="
  echo "OS: ${OS_NAME} ${OS_VERSION}"
  echo
  echo "1) Create DevOps user + SSH key"
  echo "2) System update & upgrade"
  echo "3) Install Docker + Compose plugin"
  echo "4) Install PHP (choose version)"
  echo "5) Install Composer"
  echo "6) Install Node.js + NPM (choose version)"
  echo "7) Check open ports + close with UFW"
  echo "0) Exit"
  echo

  read -rp "Choice: " choice

  case "${choice}" in
    1) run_module "01_ssh_user.sh"; pause ;;
    2) run_module "02_system_update.sh"; pause ;;
    3) run_module "03_docker.sh"; pause ;;
    4) run_module "04_php.sh"; pause ;;
    5) run_module "05_composer.sh"; pause ;;
    6) run_module "06_node.sh"; pause ;;
    7) run_module "07_ports.sh"; pause ;;
    0) exit 0 ;;
    *) echo "Invalid option"; pause ;;
  esac
done