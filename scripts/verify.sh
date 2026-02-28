#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

run_swift_tests() {
  echo "Running Swift verification..."
  if command -v xcsift >/dev/null 2>&1; then
    (cd "${ROOT_DIR}" && swift test 2>&1 | xcsift -f toon)
  else
    (cd "${ROOT_DIR}" && swift test)
  fi
}

run_web_verification() {
  echo "Running WebRenderer verification..."

  if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
    echo "Skipping WebRenderer verification because node/npm is unavailable."
    return 0
  fi

  if [ ! -d "${ROOT_DIR}/WebRenderer/node_modules" ]; then
    echo "Skipping WebRenderer verification because dependencies are not installed."
    echo "Run scripts/bootstrap.sh if you need to verify or update web assets."
    return 0
  fi

  (cd "${ROOT_DIR}/WebRenderer" && npm run build)
}

run_swift_tests
run_web_verification

echo "Verification complete."
