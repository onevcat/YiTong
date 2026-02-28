# M3 Typed Bridge And State

**Date:** 2026-02-28
**Status:** Completed
**Plan:** `docs/plans/2026-02-28-yitong-initial-implementation-plan.md`
**Linear:** `CLAW-55`

## Goal

Harden the host-web contract introduced in M2 so the bridge schema, state transitions, configuration updates, and event mapping are deterministic and testable.

This milestone is about internal reliability. It does not expand the product surface beyond the existing `DiffView` / `DiffViewController` API.

## Completed

- Tightened Swift bridge decoding so protocol version mismatches now fail decoding instead of being silently accepted.
- Added the missing typed payloads required by the accepted design:
  - `updateConfiguration`
  - `teardown`
  - `lineActivated`
  - `selectionChanged`
- Extended internal host command and event types so native code can carry:
  - configuration replacement
  - teardown
  - line activation
  - selection updates
- Hardened `YiTongRendererCoordinator` with additional state behavior:
  - `updateConfiguration` now behaves as a full replacement update
  - stale `renderStateChanged` events are ignored when document identifiers do not match the current request
  - duplicate `ready` events are ignored within the same session
  - `terminate()` transitions the session into `.terminated` and is idempotent
- Wired `YiTongWebViewHost` to:
  - send `updateConfiguration` and `teardown`
  - decode `lineActivated` and `selectionChanged`
  - expose a non-reloading `render(request:)` path for document replacement after initial page load
- Wired `DiffViewController` / `DiffView` updates so:
  - SwiftUI/AppKit/UIKit update paths are no longer placeholders
  - document changes trigger a fresh render request
  - configuration changes trigger `updateConfiguration`
  - document identifiers rotate when the document changes, preventing stale event collisions
- Extended the embedded web runtime so it now:
  - validates incoming protocol version before dispatch
  - re-renders deterministically on `updateConfiguration`
  - clears state on `teardown`
  - posts `lineActivated`
  - posts `selectionChanged`

## Behavior Now Supported

The bridge/runtime path now guarantees:

1. Incoming and outgoing envelopes are typed and version-validated.
2. Repeated `ready` events do not replay initialization for the same page session.
3. Configuration updates re-render deterministically without requiring a page reload.
4. Stale `renderStateChanged` events are ignored when they refer to an older document identifier.
5. Teardown transitions the internal renderer session into a terminal state.
6. Line click and line selection interactions are bridged back to native event types.

## Automated Coverage Added Or Updated

- Bridge codec tests now cover:
  - protocol version mismatch failure
  - `updateConfiguration`
  - `teardown`
  - `lineActivated`
  - `selectionChanged`
- Core state tests now cover:
  - immediate render after `ready`
  - deterministic configuration updates
  - queued configuration replacement before `ready`
  - stale render event rejection
  - termination behavior
  - duplicate `ready` idempotency
- Public smoke coverage now includes controller update calls before view loading

## Verification Performed

Executed successfully:

- `swift test 2>&1 | xcsift -f toon`
- `make update-web-assets`
- `make verify`

Observed result:

- Swift tests passed with 30 tests and no failures
- Web renderer built successfully against the current typed protocol/runtime code
- Bundled local assets were regenerated and copied into `Sources/YiTongWebAssets/Resources/`

## Known Limitations

- The bridge now carries line activation and selection events, but the example harness is still the only practical visual validation path.
- `teardown` exists as a real internal command, but the current public API still does not expose an explicit lifecycle control surface.
- Full-file `oldFile/newFile` pairing remains post-v1 work and is not part of this milestone.

## Deliverables

- [YiTongBridgePayloads.swift](/Users/onevcat/Sync/github/YiTong/Sources/YiTongBridge/YiTongBridgePayloads.swift)
- [YiTongBridgeMessage.swift](/Users/onevcat/Sync/github/YiTong/Sources/YiTongBridge/YiTongBridgeMessage.swift)
- [YiTongRendererCoordinator.swift](/Users/onevcat/Sync/github/YiTong/Sources/YiTongCore/YiTongRendererCoordinator.swift)
- [YiTongWebViewHost.swift](/Users/onevcat/Sync/github/YiTong/Sources/YiTongCore/YiTongWebViewHost.swift)
- [DiffViewController.swift](/Users/onevcat/Sync/github/YiTong/Sources/YiTong/DiffViewController.swift)
- [DiffView.swift](/Users/onevcat/Sync/github/YiTong/Sources/YiTong/DiffView.swift)
- [protocol.ts](/Users/onevcat/Sync/github/YiTong/WebRenderer/src/protocol.ts)
- [bridge.ts](/Users/onevcat/Sync/github/YiTong/WebRenderer/src/bridge.ts)
- [renderer.ts](/Users/onevcat/Sync/github/YiTong/WebRenderer/src/renderer.ts)

## Acceptance

You can validate M3 with these steps:

1. Run `make verify`.
2. Confirm the Swift suite passes with 30 tests and the WebRenderer build succeeds.
3. Run `make run-example`.
4. Confirm the example window renders the sample diff and reaches `didRender(fileCount: 2)`.
5. Click a diff line and confirm the status label changes to `didClickLine(...)`.
6. Drag-select lines in the diff and confirm the status label changes to `didChangeSelection(...)`.
7. Close the example window.
8. Run `make update-web-assets`.
9. Inspect the M3 bridge/state entrypoints:
   - native coordinator: [YiTongRendererCoordinator.swift](/Users/onevcat/Sync/github/YiTong/Sources/YiTongCore/YiTongRendererCoordinator.swift)
   - native host: [YiTongWebViewHost.swift](/Users/onevcat/Sync/github/YiTong/Sources/YiTongCore/YiTongWebViewHost.swift)
   - web protocol: [protocol.ts](/Users/onevcat/Sync/github/YiTong/WebRenderer/src/protocol.ts)
   - web runtime: [renderer.ts](/Users/onevcat/Sync/github/YiTong/WebRenderer/src/renderer.ts)

## Next Milestone

M4 should focus on public-facing polish rather than more internal contract work:

- tighten the public controller/view update behavior further where needed
- make manual validation easier and more polished
- decide how much of the new internal event plumbing should be treated as fully supported public behavior
