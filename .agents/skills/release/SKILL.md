---
name: release
description: Prepare and publish a YiTong release. Use when deciding the next version, collecting commits since the previous tag, maintaining CHANGELOG.md, running final verification, creating/pushing a git tag, and creating a GitHub release with gh CLI.
---

# YiTong Release

Use this skill when the user wants to cut a release or asks what should happen before tagging YiTong.

## Principles

- Use `gh` for GitHub release operations.
- Prefer a deterministic, reviewable flow over interactive prompts.
- Treat `CHANGELOG.md` as the canonical user-facing release notes.
- For SwiftPM, the package version is the git tag. Do not add a version field to `Package.swift`.
- Do not publish from a dirty worktree unless the user explicitly wants the release commit to include the current changes.

## Versioning rules

YiTong currently ships as a Swift Package and has no in-manifest version field. Release identity comes from the git tag.

Choose the next version from the commit range since the previous tag:

- No previous tag: start at `0.1.0`.
- Before `1.0.0`:
  - `patch`: fixes, docs, tests, internal refactors, packaging-only changes.
  - `minor`: new public capability, public API surface changes, platform/support changes, or any intentional behavior break.
  - `major`: only when intentionally declaring stable `1.0.0+` semantics.
- At or after `1.0.0`, follow SemVer normally:
  - `major`: breaking public change.
  - `minor`: backward-compatible feature.
  - `patch`: backward-compatible fix.

Use `scripts/next-version.sh` to compute the next tag after deciding the bump class.

## Standard flow

### 1. Collect release context

Run:

```bash
.agents/skills/release/scripts/release-context.sh
```

This shows:

- latest local tag
- commit range
- ordered commit subjects
- changed files
- touched high-level areas
- likely public API touch points

If the repository has remotes, refresh tags first:

```bash
git fetch --tags origin
```

Use `gh release list --limit 20` to confirm what GitHub already published.

### 2. Decide the version

Judge the bump from actual user-visible impact, not just commit wording.
Commit messages in this repository are not guaranteed to encode SemVer intent.

Typical heuristics for YiTong:

- `Sources/YiTong/`, platform requirements, or rendering behavior visible to integrators changed: usually at least `minor` while still `< 1.0.0`.
- Only docs/tests/examples/internal/web asset sync changed without public behavior change: usually `patch`.
- Removing or renaming public API, changing default behavior, or changing supported platform baseline: breaking.

Then compute the candidate version:

```bash
.agents/skills/release/scripts/next-version.sh <patch|minor|major>
```

### 3. Maintain `CHANGELOG.md`

If `CHANGELOG.md` does not exist, create it in a Keep a Changelog style:

```md
# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

## [0.1.0] - 2026-03-15
### Added
- Initial public release.
```

Rules:

- Keep `## [Unreleased]` at the top.
- Insert the new version section directly below `Unreleased`.
- Write concise user-facing bullets, grouped under headings such as `Added`, `Changed`, `Fixed`, `Removed`.
- Skip noise like test-only chores unless they affect users or release confidence.
- For the first release, summarize the product surface, supported platforms, and notable integration model.

The release page should reuse this section verbatim. Extract it with:

```bash
.agents/skills/release/scripts/changelog-section.sh 0.1.0
```

### 4. Apply release-prep edits

Common release-prep edits:

- update `README.md` installation snippets to the actual released version
- add or update `CHANGELOG.md`
- regenerate bundled web assets if renderer source changed

For YiTong specifically:

- If `WebRenderer/src/` changed, run `make update-web-assets` and commit both source and generated assets together.
- Do not hand-edit `Sources/YiTongWebAssets/Resources/`.

### 5. Verify before tagging

Minimum verification:

```bash
make verify
```

Additional verification when relevant:

- Web renderer logic changed: `cd WebRenderer && npm test`
- UI or interaction changed: `make run-example` for manual validation
- If release-prep edits changed files, ensure the final worktree is clean after committing them

Do not claim tests were run unless you actually ran them.

### 6. Commit release-prep changes

If `CHANGELOG.md`, `README.md`, or generated assets changed, create a focused commit before tagging.
Use an imperative subject, for example:

```bash
git add CHANGELOG.md README.md Sources/YiTongWebAssets/Resources WebRenderer/src
git commit -m "Prepare 0.1.0 release"
```

### 7. Tag and push

Prefer an annotated tag:

```bash
git tag -a 0.1.0 -m "Release 0.1.0"
git push origin master
git push origin 0.1.0
```

If the release is from a non-default branch, replace `master` explicitly and state why.

### 8. Create the GitHub release

Prefer `gh release create` with `--verify-tag` so the command fails if the remote tag is missing.
Use `CHANGELOG.md` as the release notes source.
For non-initial releases, add `--fail-on-no-commits`.
Publish immediately by default. Only add `--draft` when the user explicitly asks for a draft release.

Default published release:

```bash
.agents/skills/release/scripts/changelog-section.sh 0.1.0 | \
  gh release create 0.1.0 \
    --verify-tag \
    --title "0.1.0" \
    --notes-file -
```

Draft release when explicitly requested:

```bash
.agents/skills/release/scripts/changelog-section.sh 0.1.0 | \
  gh release create 0.1.0 \
    --verify-tag \
    --draft \
    --title "0.1.0" \
    --notes-file -
```

To publish an existing draft later:

```bash
gh release edit 0.1.0 --draft=false
```

Then confirm the remote release state:

```bash
gh release view 0.1.0 --json url,isDraft,isPrerelease,tagName,publishedAt
```

### 9. Final report

Report:

- chosen version and why
- commit range used for notes
- verification commands run and result
- release commit SHA
- tag name
- GitHub release URL
- any manual follow-up still pending

## Release checklist

Use this exact mental checklist:

1. Worktree understood and intentionally clean or intentionally staged.
2. Previous tag and commit range confirmed.
3. Next version justified from public impact.
4. `CHANGELOG.md` updated.
5. Release-prep changes committed.
6. Required verification completed.
7. Annotated tag created and pushed.
8. GitHub release created from the pushed tag.
9. Remote release state verified.
10. Final summary returned with URLs and verification status.
