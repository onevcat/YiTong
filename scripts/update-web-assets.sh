#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WEB_RENDERER_DIR="${ROOT_DIR}/WebRenderer"

if ! command -v node >/dev/null 2>&1; then
  echo "error: node is required to update bundled web assets." >&2
  exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "error: npm is required to update bundled web assets." >&2
  exit 1
fi

if [ ! -f "${WEB_RENDERER_DIR}/package.json" ]; then
  echo "error: WebRenderer workspace not found at ${WEB_RENDERER_DIR}." >&2
  exit 1
fi

if [ ! -d "${WEB_RENDERER_DIR}/node_modules" ]; then
  echo "error: WebRenderer dependencies are not installed. Run scripts/bootstrap.sh first." >&2
  exit 1
fi

echo "Building WebRenderer and syncing bundled assets..."
(cd "${WEB_RENDERER_DIR}" && npm run bundle-assets)

echo "Bundled web assets updated."
