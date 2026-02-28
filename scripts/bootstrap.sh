#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WEB_RENDERER_DIR="${ROOT_DIR}/WebRenderer"

if ! command -v node >/dev/null 2>&1; then
  echo "error: node is required to bootstrap WebRenderer dependencies." >&2
  exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "error: npm is required to bootstrap WebRenderer dependencies." >&2
  exit 1
fi

echo "Bootstrapping WebRenderer dependencies..."
(cd "${WEB_RENDERER_DIR}" && npm install)

echo "Bootstrap complete."
