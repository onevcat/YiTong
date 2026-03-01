# YiTong File-based Diff + Expand Unchanged Plan

**Date:** 2026-03-01
**Status:** Draft

## Goal

Add first-class support for **file-based diffs** (old/new file contents) so the renderer can reliably support **expand unchanged**.

This should work for:
- single file diff
- multi-file diff (implemented as multiple single-file diffs rendered in a list)

## Key Constraints / Principles

- Maintainability first: keep the “multi-file” design as a container of per-file diffs.
- Backwards compatibility is not required yet (project still in active development), but **docs + schema must be updated together**.
- Prefer a deterministic and testable implementation over clever heuristics.

## Current State (Baseline)

- Bridge only supports unified patch strings: `document.patch: String`.
- WebRenderer uses `parsePatchFiles(patch)` and renders each parsed file via `FileDiff`.
- This path cannot reliably support expand-unchanged (no full old/new file lines available).

## Proposed Design

### 1) Public API (Swift): introduce file-based document source

Extend `DiffDocument` to support both:
- patch-based: existing initializer remains
- file-based: new initializer taking an array of file entries

Proposed API (names are illustrative):

- `DiffDocument(patch:title:)`
- `DiffDocument(files:title:)`

Where `files` is:

- `struct DiffFile { oldPath: String?; newPath: String?; oldContents: String; newContents: String }`

### 2) Bridge schema: make `document` support either patch or files

Update `YiTongBridgeDocumentPayload` (Swift) and `RenderDocumentPayload` (TS) to allow:

- `patch?: string`
- `files?: DiffFilePayload[]`

Rule:
- If `files` exists and is non-empty → render using file-based diff.
- Else → render using patch.

This avoids ambiguity for callers and keeps the renderer logic straightforward.

### 3) WebRenderer: render per-file diffs using `parseDiffFromFile`

Implementation direction:

- If patch-mode:
  - keep existing `parsePatchFiles(patch)`.

- If file-mode:
  - for each file entry:
    - compute `const fileDiff = parseDiffFromFile(oldContents, newContents)`
    - render `new FileDiff(...).render({ fileDiff })`

This is the path that provides the full line arrays required for expand-unchanged.

### 4) Size limits (soft boundary + graceful fallback)

We should “try hard” but not blow up WKWebView / JS runtime.

Proposed defaults (configurable later if needed):

- `maxTotalBytes` (sum of UTF-8 bytes for all old/new contents): **10 MB**
- `maxFileBytes` (per file old+new): **2 MB**
- `maxFiles`: **200**

Behavior:
- If within limits: use file-mode.
- If exceeds limits:
  - fall back to patch-mode (if patch provided)
  - otherwise fail with a typed error (document too large)
  - emit a diagnostic / renderStateChanged error so native can show a message.

### 5) Example app: add a visible file-based multi-file sample

Update `Examples/YiTongExample`:
- Add a TabView with at least:
  - “Patch (multi-file)” (existing sample)
  - “Files (multi-file)” (new sample)

The file-based sample should include enough unchanged context so expand-unchanged is visually meaningful.

## Testing Plan

### Swift

- Bridge codec tests:
  - file-based document payload encode/decode
  - patch-based document payload encode/decode (still supported)
- Core coordinator tests:
  - rendering lifecycle behaves the same for file-based requests
- Public smoke tests:
  - `DiffViewController` can be constructed with file-based document

### Web

Add `vitest`:
- Unit test a pure helper that maps payload → list of file diffs
- Unit test the renderer branch selection:
  - files present → calls file-diff path
  - patch only → calls patch-diff path

(Optional later) Playwright for expand interaction.

## Docs to Update

- `docs/milestones/*` add a new milestone or “post-M4” note for file-based diff.
- `docs/plans/2026-02-28-yitong-initial-implementation-plan.md` link to this plan.
- Bridge schema snapshots in both Swift + TS.
