# M1 Foundation Skeleton

**Date:** 2026-02-28
**Status:** Completed
**Plan:** `docs/plans/2026-02-28-yitong-initial-implementation-plan.md`
**Linear:** `CLAW-53`

## Goal

Establish the package graph, bundled asset layout, and web renderer workspace so the repository has a deterministic build boundary before real rendering logic is added.

## Completed

- Added `Package.swift` with one public library product, internal implementation targets, and three test targets.
- Added the public API skeleton:
  - `DiffDocument`
  - `DiffConfiguration`
  - `DiffEvent`
  - `DiffView`
  - `DiffViewController`
- Added internal implementation skeleton:
  - `YiTongRendererState`
  - `YiTongRendererSession`
  - `YiTongWebViewHost`
  - `YiTongBridgeSchema`
  - `YiTongBridgeMessage`
  - `YiTongBridgeCodec`
  - `YiTongWebAssets`
- Added a deterministic `WebRenderer/` workspace with:
  - exact-pinned `@pierre/diffs`
  - exact-pinned `vite`
  - exact-pinned `typescript`
  - `vite build`
  - `copy-assets` script
  - generated asset copy into `Sources/YiTongWebAssets/Resources/`
- Added repository-level task entrypoints:
  - `Makefile` as the canonical interface
  - `Justfile` as a thin wrapper for users who prefer `just`
  - `scripts/bootstrap.sh`
  - `scripts/update-web-assets.sh`
  - `scripts/verify.sh`
- Checked in the generated placeholder assets:
  - `index.html`
  - `renderer.js`
  - `renderer.css`
  - `manifest.json`
- Added initial automated coverage for:
  - bridge codec round-trip
  - protocol version constant
  - bundled asset manifest loading
  - public API construction smoke tests

## Verification Performed

Executed successfully:

- `npm install` in `WebRenderer/`
- `npm run bundle-assets` in `WebRenderer/`
- `swift test 2>&1 | xcsift -f toon`

Observed result:

- web bundle built successfully and copied deterministic assets into SwiftPM resources
- Swift test suite passed with 7 tests and no failures

## Deliverables

- [Package.swift](/Users/onevcat/Sync/github/YiTong/Package.swift)
- [DiffView.swift](/Users/onevcat/Sync/github/YiTong/Sources/YiTong/DiffView.swift)
- [DiffViewController.swift](/Users/onevcat/Sync/github/YiTong/Sources/YiTong/DiffViewController.swift)
- [YiTongWebViewHost.swift](/Users/onevcat/Sync/github/YiTong/Sources/YiTongCore/YiTongWebViewHost.swift)
- [YiTongWebAssets.swift](/Users/onevcat/Sync/github/YiTong/Sources/YiTongWebAssets/YiTongWebAssets.swift)
- [manifest.json](/Users/onevcat/Sync/github/YiTong/Sources/YiTongWebAssets/Resources/manifest.json)
- [package.json](/Users/onevcat/Sync/github/YiTong/WebRenderer/package.json)
- [copy-assets.mjs](/Users/onevcat/Sync/github/YiTong/WebRenderer/scripts/copy-assets.mjs)
- [Makefile](/Users/onevcat/Sync/github/YiTong/Makefile)
- [Justfile](/Users/onevcat/Sync/github/YiTong/Justfile)

## Acceptance

You can validate M1 with these steps:

1. Run `cd WebRenderer && npm install && npm run bundle-assets`.
2. Confirm these files exist under `Sources/YiTongWebAssets/Resources/`:
   `index.html`, `renderer.js`, `renderer.css`, `manifest.json`.
3. Run `swift test 2>&1 | xcsift -f toon`.
4. Confirm the package builds and all tests pass.
5. Spot-check that the public API names are already aligned with the design:
   `DiffView` and `DiffViewController`.

## Next Milestone

M2 focuses on the first real runtime loop:

- load local bundled assets inside `WKWebView`
- emit and receive `ready`
- send `initialize`
- send `renderDocument`
- receive `renderStateChanged`
- render a real multi-file patch through the embedded web runtime
