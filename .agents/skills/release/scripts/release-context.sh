#!/usr/bin/env bash
set -euo pipefail

if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "Not inside a git repository" >&2
  exit 1
fi

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

latest_tag=${1:-$(git tag --sort=version:refname | tail -n 1)}
range=${latest_tag:+$latest_tag..HEAD}

if [[ -n "$latest_tag" ]]; then
  compare_label="$latest_tag..HEAD"
else
  compare_label="initial release (full history)"
fi

printf 'Repository: %s\n' "$(basename "$repo_root")"
printf 'Branch: %s\n' "$(git branch --show-current)"
printf 'Latest tag: %s\n' "${latest_tag:-<none>}"
printf 'Range: %s\n' "$compare_label"
printf 'Working tree: %s\n' "$(git status --short | wc -l | tr -d ' ') changed path(s)"

printf '\n== Commits ==\n'
if [[ -n "$range" ]]; then
  git log --no-merges --reverse --format='- %h %s' "$range"
else
  git log --no-merges --reverse --format='- %h %s'
fi

printf '\n== Changed files ==\n'
if [[ -n "$range" ]]; then
  git diff --name-only "$range"
else
  git ls-files
fi

printf '\n== Area summary ==\n'
if [[ -n "$range" ]]; then
  git diff --name-only "$range"
else
  git ls-files
fi | awk -F/ '
  NF == 1 { key = $1; counts[key]++; next }
  { key = $1 "/" $2; counts[key]++ }
  END {
    for (key in counts) {
      printf "%4d %s\n", counts[key], key
    }
  }
' | sort -k2

printf '\n== Public API touch points ==\n'
public_api=$(
  if [[ -n "$range" ]]; then
    git diff --name-only "$range"
  else
    git ls-files
  fi | rg '^(Sources/YiTong/|Package.swift|README.md|LICENSE|NOTICE|THIRD_PARTY_NOTICES\.md)$' || true
)
if [[ -n "$public_api" ]]; then
  printf '%s\n' "$public_api"
else
  echo '<none>'
fi
