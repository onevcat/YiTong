# M4 Public UI And Demo

**Date:** 2026-02-28
**Status:** Completed
**Plan:** `docs/plans/2026-02-28-yitong-initial-implementation-plan.md`
**Linear:** `CLAW-56`

## Goal

Polish the public `DiffView` / `DiffViewController` surface into a more usable v1 SDK layer while keeping the scope intentionally narrow.

This milestone does not introduce file navigation, full-file pairing, review workflows, or arbitrary web customization. It focuses on public configuration semantics, mapping stability, and practical manual verification.

## Completed

- Expanded `DiffConfiguration` with two additional public configuration controls that already exist upstream and map cleanly into YiTong:
  - `indicators`
  - `showsChangeBackgrounds`
- Added `DiffIndicators` as a stable public enum:
  - `.bars`
  - `.classic`
  - `.none`
- Introduced `YiTongPublicModelAdapter` so public Swift models now have a single internal mapping layer for:
  - `DiffDocument` + `DiffConfiguration` -> render request
  - host events -> public `DiffEvent`
- Updated `DiffViewController` to use the shared public-model adapter instead of duplicating per-platform mapping logic.
- Extended the web protocol/runtime configuration to accept:
  - `diffIndicators`
  - `showsChangeBackgrounds`
- Extended the example app from a static harness into a usable acceptance surface with live controls for:
  - split vs unified layout
  - indicator style
  - line numbers
  - change backgrounds
  - line wrapping
  - file headers
  - selection enablement
- Updated the README so the bundled example is now documented as the primary visual acceptance path for the current public API.

## Public Surface Now Supported

At the end of M4, the intended v1 public configuration surface is:

- appearance: automatic, light, dark
- layout style: split, unified
- diff indicators: bars, classic, none
- line numbers: on/off
- change backgrounds: on/off
- line wrapping: on/off
- file headers: on/off
- inline change style: word alt, word, char, none
- selection: on/off

This remains intentionally smaller than the full upstream `diffs` feature matrix.

## Automated Coverage Added Or Updated

- Public API tests now verify:
  - default configuration semantics for the expanded public surface
  - `DiffConfiguration` -> bridge payload mapping for the new configuration fields
  - `DiffDocument` + `DiffConfiguration` -> render request mapping
  - host line activation -> public event mapping
  - host selection change -> public event mapping
- Existing bridge and core suites were updated to construct the expanded configuration payloads so schema drift is caught by compile-time and runtime coverage.

## Verification Performed

Executed successfully:

- `swift test 2>&1 | xcsift -f toon`
- `make update-web-assets`
- `make verify`

Observed result:

- Swift tests passed with 34 tests and no failures
- Web assets regenerated successfully with the expanded public configuration protocol
- The example app remained the manual validation path for runtime configuration changes

## Known Limitations

- The example is intentionally a validation harness, not a polished product demo.
- Public configuration still exposes only stable Apple-facing semantics, not the full upstream web customization surface.
- Full-file `oldFile/newFile` pairing remains explicitly post-v1 work.

## Deliverables

- [DiffConfiguration.swift](/Users/onevcat/Sync/github/YiTong/Sources/YiTong/DiffConfiguration.swift)
- [DiffViewController.swift](/Users/onevcat/Sync/github/YiTong/Sources/YiTong/DiffViewController.swift)
- [YiTongPublicModelAdapter.swift](/Users/onevcat/Sync/github/YiTong/Sources/YiTong/YiTongPublicModelAdapter.swift)
- [YiTongBridgePayloads.swift](/Users/onevcat/Sync/github/YiTong/Sources/YiTongBridge/YiTongBridgePayloads.swift)
- [protocol.ts](/Users/onevcat/Sync/github/YiTong/WebRenderer/src/protocol.ts)
- [theme.ts](/Users/onevcat/Sync/github/YiTong/WebRenderer/src/theme.ts)
- [main.swift](/Users/onevcat/Sync/github/YiTong/Examples/YiTongExample/main.swift)
- [README.md](/Users/onevcat/Sync/github/YiTong/README.md)

## Acceptance

You can validate M4 with these steps:

1. Run `make verify`.
2. Confirm the Swift suite passes with 34 tests and the web bundle regenerates successfully.
3. Run `make run-example`.
4. Confirm the sample diff renders and reaches `didRender(fileCount: 2)`.
5. Switch layout between `Split` and `Unified` and confirm the diff rerenders inside the same app session.
6. Change `Indicators` between `Bars`, `Classic`, and `None` and confirm the visual styling updates.
7. Toggle `Show change backgrounds` and confirm added/removed line highlighting updates.
8. Toggle line numbers, line wrapping, file headers, and selection; confirm the example remains responsive and the event sidebar continues to update.
9. Click a diff line and drag-select lines to confirm line and selection events still reach the example UI.

## Next Milestone

With M4 complete, YiTong has a plausible v1 SDK surface. The next work should move away from basic viewer polish and toward whichever post-v1 direction is most valuable:

- full-file pairing support
- file outline/navigation support
- richer review-oriented interaction models
