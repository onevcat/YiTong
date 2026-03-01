# YiTong Initial Implementation Plan

**Goal:** Build the first usable YiTong integration path from local bundled web assets to a native `DiffView` / `DiffViewController` that can render a multi-file patch through `WKWebView`.

**Scope:**
- In: Swift package skeleton, local web renderer bundle, typed host-web bridge, minimal native UI surface, tests for bridge/core behavior, milestone docs and verification guidance.
- Out: Worker mode, file list UI, public annotations, virtualization, asset update automation beyond basic scripts, release packaging.

**Architecture:**
- One Swift package with a public `YiTong` target and internal core/bridge/assets targets.
- One bundled local web renderer workspace under `WebRenderer/`, built with Vite and checked into SwiftPM resources.
- One versioned JSON bridge schema shared by Swift and TypeScript.
- One `WKWebView` host path reused by SwiftUI and UIKit/AppKit wrappers.

**Acceptance / Verification:**
- A local `WKWebView` can load bundled `index.html` and complete the `ready -> initialize -> renderDocument -> renderStateChanged(rendered)` loop.
- A multi-file unified diff patch renders correctly through `DiffView`.
- Core bridge encoding/decoding and lifecycle behavior have automated test coverage.
- Each completed milestone has a milestone doc with explicit verification steps.

## Milestones

1. Foundation skeleton
2. Minimal render loop
3. Typed bridge and state management
4. Public UI surface and usable demo path

## Milestone 1: Foundation Skeleton

**Goal:** Create the repository structure and toolchain boundaries without implementing rendering behavior yet.

**Files:**
- Create: `Package.swift`
- Create: `Sources/YiTong/`
- Create: `Sources/YiTongCore/`
- Create: `Sources/YiTongBridge/`
- Create: `Sources/YiTongWebAssets/Resources/`
- Create: `Tests/YiTongTests/`
- Create: `Tests/YiTongCoreTests/`
- Create: `Tests/YiTongBridgeTests/`
- Create: `WebRenderer/package.json`
- Create: `WebRenderer/package-lock.json`
- Create: `WebRenderer/vite.config.ts`
- Create: `WebRenderer/src/main.ts`
- Create: `WebRenderer/scripts/copy-assets.mjs`

**Steps:**
1. Add `Package.swift` with public and internal targets matching the design doc.
2. Add placeholder Swift source files so the package graph builds cleanly.
3. Add the `WebRenderer/` workspace with exact npm dependency pinning and a deterministic build target.
4. Add placeholder bundled assets into `Sources/YiTongWebAssets/Resources/`.
5. Add smoke tests that verify the package can compile and the assets target resolves resources.
6. Write `docs/milestones/2026-02-28-m1-foundation-skeleton.md`.

**Verification:**
- `swift test` succeeds.
- `npm ci` and `npm run build` inside `WebRenderer/` succeed.
- The generated asset copy path is deterministic and documented.

## Milestone 2: Minimal Render Loop

**Goal:** Load the local page in `WKWebView` and render a multi-file patch via the web runtime.

**Files:**
- Modify: `Sources/YiTongCore/`
- Modify: `Sources/YiTongBridge/`
- Modify: `Sources/YiTongWebAssets/Resources/`
- Modify: `WebRenderer/src/main.ts`
- Create: `WebRenderer/src/bridge.ts`
- Create: `WebRenderer/src/renderer.ts`
- Tests: `Tests/YiTongCoreTests/`

**Steps:**
1. Implement the minimal web app boot path that emits `ready`.
2. Implement native page loading and message injection for `initialize` and `renderDocument`.
3. Parse and render multi-file patches using `parsePatchFiles(...)` plus one `FileDiff` per file.
4. Emit `renderStateChanged` with `loading`, `rendered`, and `failed`.
5. Add tests for native lifecycle sequencing and failure propagation.
6. Write `docs/milestones/2026-02-28-m2-minimal-render-loop.md`.

**Verification:**
- A sample multi-file patch renders from local assets with no network dependency.
- Native side observes `ready` and `rendered` in the expected order.
- Broken patch input produces a typed failure event.

## Milestone 3: Typed Bridge And State Management

**Goal:** Lock the bridge schema into code on both sides and harden configuration/update behavior.

**Files:**
- Modify: `Sources/YiTongBridge/`
- Modify: `Sources/YiTongCore/`
- Modify: `WebRenderer/src/bridge.ts`
- Create: `WebRenderer/src/protocol.ts`
- Create: `WebRenderer/src/theme.ts`
- Tests: `Tests/YiTongBridgeTests/`
- Tests: `Tests/YiTongCoreTests/`

**Steps:**
1. Encode the protocol envelope and message/event payloads as Swift types.
2. Encode the same protocol types in TypeScript.
3. Implement full-replacement `updateConfiguration` behavior.
4. Add native state machine tests for `idle/loadingPage/waitingForReady/renderingDocument/rendered/failed/terminated`.
5. Add bridge codec tests for every message and event shape.
6. Implement line click and selection message plumbing if the render loop is already stable.
7. Write `docs/milestones/2026-02-28-m3-typed-bridge-and-state.md`.

**Verification:**
- Swift and TypeScript schema snapshots match the design contract.
- Reconfiguration re-renders deterministically.
- Event decoding is covered by tests, including failure cases.

## Milestone 4: Public UI Surface And Usable Demo Path

**Goal:** Expose the native API surface and leave the repo in a state that is easy to validate manually.

**Files:**
- Modify: `Sources/YiTong/`
- Modify: `Sources/YiTongCore/`
- Tests: `Tests/YiTongTests/`
- Create or modify: `Examples/YiTongExamples/` if needed

**Steps:**
1. Implement `DiffDocument`, `DiffConfiguration`, and `DiffEvent`.
2. Implement `DiffView`.
3. Implement `DiffViewController`.
4. Wire event translation from internal bridge events to the public API.
5. Add smoke tests for view/controller construction and basic configuration flow.
6. Add a minimal demo or example harness if needed for manual acceptance.
7. Write `docs/milestones/2026-02-28-m4-public-ui-and-demo.md`.

**Verification:**
- A developer can render a diff in `DiffView` with a small amount of setup.
- UIKit/AppKit host path shares the same core behavior.
- Public API remains smaller than the underlying renderer API.

## Execution Notes

- Execute milestones in order.
- Do not start worker mode, SSR, or public annotation APIs during this plan.
- Treat milestone docs as required completion artifacts, not optional notes.
- When milestone scope changes, update this plan before continuing.

---

## Post-M4 / Follow-ups

- File-based diff (old/new contents) + expand unchanged: see `docs/plans/2026-03-01-yitong-file-based-diff-plan.md`.
