#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<USAGE
Usage: $(basename "$0") [current-version] <patch|minor|major>

If current-version is omitted, the latest local git tag is used.
If no tag exists, 0.1.0 is returned.
USAGE
  exit 1
}

if [[ $# -eq 1 ]]; then
  current=$(git tag --sort=version:refname | tail -n 1)
  bump=$1
elif [[ $# -eq 2 ]]; then
  current=$1
  bump=$2
else
  usage
fi

case "$bump" in
  patch|minor|major) ;;
  *) usage ;;
esac

if [[ -z "${current:-}" ]]; then
  echo "0.1.0"
  exit 0
fi

prefix=""
version="$current"
if [[ "$version" == v* ]]; then
  prefix="v"
  version=${version#v}
fi

IFS=. read -r major minor patch <<< "$version"
: "${major:?}"
: "${minor:?}"
: "${patch:?}"

case "$bump" in
  patch)
    patch=$((patch + 1))
    ;;
  minor)
    minor=$((minor + 1))
    patch=0
    ;;
  major)
    major=$((major + 1))
    minor=0
    patch=0
    ;;
esac

echo "${prefix}${major}.${minor}.${patch}"
