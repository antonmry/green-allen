#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://gitlab.cern.ch/lhcb/Allen.git"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
TARGET_DIR="${SCRIPT_DIR}/Allen"

if [ -d "${TARGET_DIR}" ]; then
  echo "Allen repository already exists at ${TARGET_DIR}"
  exit 0
fi

git clone "${REPO_URL}" "${TARGET_DIR}"
