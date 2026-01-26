#!/usr/bin/env bash
set -euo pipefail

REPO_OWNER="BrunoHoinacki"
REPO_NAME="sh-automation-devops"
BRANCH="main"

ARCHIVE_URL="https://codeload.github.com/${REPO_OWNER}/${REPO_NAME}/tar.gz/refs/heads/${BRANCH}"

echo "=========================================="
echo " DevOps Automation Toolbox Installer"
echo "=========================================="
echo

# Detect current directory
TARGET_DIR="$(pwd)"
TMP_DIR="$(mktemp -d)"

echo "📁 Target directory:"
echo "   ${TARGET_DIR}"
echo

# Check required commands
for cmd in curl tar sudo; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "❌ Missing required command: $cmd"
    exit 1
  fi
done

# Check if directory already exists
if ls "${TARGET_DIR}" | grep -q "^${REPO_NAME}"; then
  echo "⚠️  A directory named '${REPO_NAME}' already exists here."
  read -rp "Do you want to overwrite it? [y/N]: " yn
  if [[ "${yn,,}" != "y" && "${yn,,}" != "yes" ]]; then
    echo "Aborted."
    exit 0
  fi
  rm -rf "${TARGET_DIR}/${REPO_NAME}"
fi

echo "⬇️  Downloading repository..."
curl -fsSL "${ARCHIVE_URL}" -o "${TMP_DIR}/repo.tar.gz"

echo "📦 Extracting..."
tar -xzf "${TMP_DIR}/repo.tar.gz" -C "${TMP_DIR}"

EXTRACTED_DIR="$(find "${TMP_DIR}" -maxdepth 1 -type d -name "${REPO_NAME}-*" | head -n1)"

if [[ -z "${EXTRACTED_DIR}" ]]; then
  echo "❌ Failed to extract repository."
  exit 1
fi

mv "${EXTRACTED_DIR}" "${TARGET_DIR}/${REPO_NAME}"

echo "🔐 Setting executable permissions..."
chmod +x "${TARGET_DIR}/${REPO_NAME}/devops.sh"
chmod +x "${TARGET_DIR}/${REPO_NAME}/modules/"*.sh
chmod +x "${TARGET_DIR}/${REPO_NAME}/install.sh"

rm -rf "${TMP_DIR}"

echo
echo "✅ Installation completed!"
echo
echo "📂 Location:"
echo "   ${TARGET_DIR}/${REPO_NAME}"
echo
echo "▶️  To start the toolbox:"
echo
echo "   cd ${REPO_NAME}"
echo "   sudo ./devops.sh"
echo

read -rp "Press ENTER to start DevOps Automation Toolbox..."

cd "${TARGET_DIR}/${REPO_NAME}"
sudo ./devops.sh
