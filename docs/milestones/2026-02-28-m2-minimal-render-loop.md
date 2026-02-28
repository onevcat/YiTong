# M2 Minimal Render Loop

**Date:** 2026-02-28
**Status:** Completed
**Plan:** `docs/plans/2026-02-28-yitong-initial-implementation-plan.md`
**Linear:** `CLAW-54`

## Goal

Establish the first end-to-end render loop from native `WKWebView` host code to the bundled local web runtime and back.

This milestone is about making the bridge path real and exposing a minimal visual harness for manual verification, not about polishing the full public UI surface yet.

## Completed

- Added typed bridge payloads for the v1 minimal message loop:
  - `initialize`
  - `renderDocument`
  - `ready`
  - `renderStateChanged`
- Added native-side render coordination:
  - `YiTongRenderRequest`
  - `YiTongHostCommand`
  - `YiTongHostEvent`
  - `YiTongRendererCoordinator`
- Upgraded `YiTongWebViewHost` from a static page loader into a bridge-aware `WKWebView` host that:
  - registers a script message handler
  - loads bundled local assets
  - decodes incoming bridge events
  - dispatches outgoing commands into the page
  - maps bridge results into native host events
- Wired `DiffViewController` to the host so the initial document/configuration now becomes a real render request instead of a placeholder page load.
- Replaced the placeholder web entrypoint with a bridge-aware renderer runtime.
- Added web-side protocol types and message handling:
  - `protocol.ts`
  - `bridge.ts`
  - `theme.ts`
  - `renderer.ts`
- Implemented multi-file patch rendering in the embedded web runtime using:
  - `parsePatchFiles(...)`
  - one `FileDiff` instance per parsed file diff
- Regenerated bundled assets so the checked-in renderer resources match the current bridge/runtime implementation.
- Added a minimal macOS harness that hosts `DiffView` with a bundled multi-file sample patch so rendering can be verified visually.

## Behavior Now Supported

The current runtime path is:

1. Native loads bundled `index.html` from SwiftPM resources.
2. Web runtime boots and posts `ready`.
3. Native host sends `initialize`.
4. Native host sends `renderDocument`.
5. Web runtime parses the patch and renders all file diffs into the page.
6. Web runtime emits `renderStateChanged` with `loading`, then `rendered`, or `failed`.
7. Native host maps the result into public events:
   - `didFinishInitialLoad`
   - `didRender`
   - `didFail`

## Automated Coverage Added Or Updated

- Bridge codec coverage for typed envelopes and payloads
- Coordinator tests for:
  - queuing render requests before `ready`
  - emitting `initialize` + `renderDocument` after `ready`
  - mapping rendered state back to native events
  - avoiding state regression when navigation callbacks arrive after `ready`
- Public smoke tests remain intact
- Example target build coverage via `swift build --product YiTongExample`

## Verification Performed

Executed successfully:

- `swift test 2>&1 | xcsift -f toon`
- `make verify`
- `make update-web-assets`
- `swift build --product YiTongExample 2>&1 | xcsift -f toon`
- `swift run YiTongExample` (validated startup path; process entered the app run loop)

Observed result:

- Swift tests passed with 17 tests and no failures
- Web renderer built successfully against the real `@pierre/diffs` dependency
- Bundled local assets were regenerated and copied into `Sources/YiTongWebAssets/Resources/`
- The example target compiled cleanly and launched into the macOS app event loop without immediate startup failure

## Known Limitations

- The visual harness is intentionally minimal and macOS-only. It is a manual verification entrypoint, not yet a polished sample app.
- `renderDocument` is implemented; `updateConfiguration` is still only a placeholder path and is not treated as complete for broader reconfiguration scenarios yet.
- Line click and selection schema exist in design, but event behavior is not implemented in this milestone.
- The current single-file `renderer.js` bundle is large and emits a Vite chunk-size warning. This is accepted for now because the current priority is a deterministic embeddable asset set rather than bundle optimization.

## Deliverables

- [YiTongBridgePayloads.swift](/Users/onevcat/Sync/github/YiTong/Sources/YiTongBridge/YiTongBridgePayloads.swift)
- [YiTongRendererCoordinator.swift](/Users/onevcat/Sync/github/YiTong/Sources/YiTongCore/YiTongRendererCoordinator.swift)
- [YiTongWebViewHost.swift](/Users/onevcat/Sync/github/YiTong/Sources/YiTongCore/YiTongWebViewHost.swift)
- [DiffViewController.swift](/Users/onevcat/Sync/github/YiTong/Sources/YiTong/DiffViewController.swift)
- [protocol.ts](/Users/onevcat/Sync/github/YiTong/WebRenderer/src/protocol.ts)
- [bridge.ts](/Users/onevcat/Sync/github/YiTong/WebRenderer/src/bridge.ts)
- [renderer.ts](/Users/onevcat/Sync/github/YiTong/WebRenderer/src/renderer.ts)
- [renderer.js](/Users/onevcat/Sync/github/YiTong/Sources/YiTongWebAssets/Resources/renderer.js)
- [main.swift](/Users/onevcat/Sync/github/YiTong/Examples/YiTongExample/main.swift)
- [SamplePatch.swift](/Users/onevcat/Sync/github/YiTong/Examples/YiTongExample/SamplePatch.swift)

## Acceptance

You can validate M2 with these steps:

1. Run `make verify`.
2. Confirm the Swift suite passes and the WebRenderer build succeeds.
3. Run `make run-example`.
4. Confirm a macOS window opens with:
   - a title/header area labeled `YiTong Example`
   - a rendered multi-file diff below it
   - a status label that advances from initial loading into `didRender(fileCount: 2)`
5. Close the example window after visual verification.
6. Run `make update-web-assets`.
7. Confirm the generated asset set under `Sources/YiTongWebAssets/Resources/` includes:
   - `index.html`
   - `renderer.css`
   - `renderer.js`
   - `manifest.json`
8. Inspect the bridge and coordinator entrypoints to confirm the minimal loop exists:
   - native host: [YiTongWebViewHost.swift](/Users/onevcat/Sync/github/YiTong/Sources/YiTongCore/YiTongWebViewHost.swift)
   - web bootstrap: [main.ts](/Users/onevcat/Sync/github/YiTong/WebRenderer/src/main.ts)
   - web render path: [renderer.ts](/Users/onevcat/Sync/github/YiTong/WebRenderer/src/renderer.ts)
9. Confirm the web runtime uses `parsePatchFiles(...)` plus one `FileDiff` per file diff, not the upstream `PatchDiff` API.

## Next Milestone

M3 will harden the bridge contract and state model further:

- fill in the remaining typed schema edges
- add stronger configuration/update behavior
- extend coverage around bridge decoding and lifecycle sequencing
- prepare the internal contract for future line click and selection events
