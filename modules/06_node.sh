#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

require_root

echo "==> Install Node.js + NPM (choose major version)"
echo "Examples: 18, 20, 22"
read -rp "Node major version [20]: " NODEV
NODEV="${NODEV:-20}"

apt_install curl ca-certificates

curl -fsSL "https://deb.nodesource.com/setup_${NODEV}.x" | bash -
apt-get install -y nodejs

node -v || true
npm -v || true

echo "✅ Node.js ${NODEV}.x installed."
