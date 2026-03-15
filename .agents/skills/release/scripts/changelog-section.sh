#!/usr/bin/env bash
set -euo pipefail

version=${1:-}
changelog=${2:-CHANGELOG.md}

if [[ -z "$version" ]]; then
  echo "Usage: $(basename "$0") <version> [CHANGELOG.md]" >&2
  exit 1
fi

if [[ ! -f "$changelog" ]]; then
  echo "Missing changelog: $changelog" >&2
  exit 1
fi

awk -v version="$version" '
  BEGIN {
    target = "## [" version "]"
    capture = 0
    found = 0
  }
  $0 == target {
    capture = 1
    found = 1
    next
  }
  capture && /^## \[/ {
    exit
  }
  capture {
    print
  }
  END {
    if (!found) {
      exit 2
    }
  }
' "$changelog"
status=$?

if [[ $status -eq 2 ]]; then
  echo "Version section not found in $changelog: $version" >&2
  exit 1
fi
