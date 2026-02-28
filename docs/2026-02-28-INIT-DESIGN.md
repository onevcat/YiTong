# YiTong Initial Design

**Date:** 2026-02-28
**Status:** Accepted
**Scope:** Initial architecture, internal bridge schema, repository structure, and packaging strategy for v1

## Summary

YiTong will be an Apple-platform wrapper around `@pierre/diffs`, exposing a small native API while keeping rendering inside `WKWebView`.

The public UI names are:

- `DiffView`
- `DiffViewController`

Internal modules and implementation types keep the `YiTong` prefix.

The core design decision is to treat `@pierre/diffs` as an internal web renderer runtime, not as a public API dependency. YiTong will use the vanilla JS `FileDiff` / `parsePatchFiles` path, not the React layer, not SSR, and not worker mode in v1.

This design is validated against the published `@pierre/diffs@1.0.11` package, not against the moving `main` branch documentation alone.

## Goals

- Expose a native-feeling Apple API for displaying diffs.
- Keep the public API smaller than the underlying web renderer API.
- Support multi-file unified diff patches as the primary input.
- Make Xcode and SwiftPM builds deterministic without a runtime Node dependency.
- Freeze a minimal host-to-web protocol before implementation.

## Non-Goals

- Re-exporting `@pierre/diffs` concepts directly in Swift.
- Shipping React inside the embedded web runtime.
- Using worker pool mode in v1.
- Supporting arbitrary custom DOM injection APIs in v1.
- Designing a code review product or comment system in v1.

## External Dependency Findings

The relevant upstream facts for v1 are:

- `@pierre/diffs` ships a usable vanilla JS API centered on `File`, `FileDiff`, `parsePatchFiles`, and worker utilities.
- The React layer is a thin wrapper over the same vanilla classes.
- `PatchDiff` is not suitable as YiTong's core runtime primitive because it only accepts a patch containing exactly one diff for exactly one file.
- The worker pool API is explicitly documented upstream as experimental.
- Upstream documentation and the published npm package are not perfectly aligned, so YiTong must treat the published npm tarball as the compatibility source of truth.

## Public API Direction

The public API remains patch-first and platform-native. The public surface should describe user intent, not renderer internals.

```swift
public struct DiffDocument: Sendable {
  public var patch: String
  public var title: String?
}

public struct DiffConfiguration: Sendable {
  public var appearance: DiffAppearance
  public var style: DiffStyle
  public var showsLineNumbers: Bool
  public var wrapsLines: Bool
  public var showsFileHeaders: Bool
  public var inlineChangeStyle: DiffInlineChangeStyle
  public var allowsSelection: Bool
}

public enum DiffEvent: Sendable {
  case didFinishInitialLoad
  case didRender(DiffRenderSummary)
  case didClickLine(DiffLineReference)
  case didChangeSelection(DiffSelection?)
  case didFail(DiffError)
}
```

### Naming Decisions

- Public view names are unprefixed: `DiffView`, `DiffViewController`.
- Public model and event types are also unprefixed when part of the main API.
- Internal implementation types are prefixed, for example `YiTongWebViewHost`, `YiTongBridgeCodec`, and `YiTongRendererSession`.

### Public Surface Constraints

The following are intentionally excluded from v1 public API:

- Upstream theme names such as `pierre-dark`
- Upstream DOM callback hooks such as custom header nodes or custom hunk separators
- Worker pool configuration
- Unsafe CSS injection
- Arbitrary file-to-file diff APIs

The only public appearance concept is native appearance. YiTong resolves that to concrete renderer themes internally.

## Renderer Strategy

YiTong's embedded web app will use the upstream vanilla runtime directly:

- `parsePatchFiles(...)` to parse a multi-file patch string
- one `FileDiff` instance per parsed file diff
- one root DOM container managed by YiTong's own web entrypoint

This avoids the `PatchDiff` single-file limitation and removes any need for React in the embedded runtime.

### Why Not React

- React does not simplify the bridge contract.
- React does not solve the multi-file patch requirement.
- The React layer in `@pierre/diffs` is already a wrapper over vanilla classes.
- Removing React reduces bundle size, state duplication, and lifecycle complexity inside `WKWebView`.

### Why Not SSR

- YiTong loads local bundled assets inside `WKWebView`, not server-rendered pages.
- SSR does not materially improve the runtime path for this use case.
- Pre-rendering would add a second render mode and a second state model before v1 needs it.

### Why Not Worker Mode in v1

- Upstream explicitly documents worker mode as experimental.
- Worker startup, packaging, and CSP-style restrictions add complexity early.
- YiTong can add worker mode later as an internal implementation upgrade without changing public Swift API.

## Host-Web Protocol

The bridge protocol is an internal contract between native Swift code and the bundled web runtime. It is versioned and intentionally narrow.

### Protocol Principles

- Versioned from day one.
- Full-replacement messages over patch-style incremental mutation.
- Git-native semantics in payloads, not upstream internal names.
- No raw JavaScript snippets crossing the bridge.
- Every message is serializable JSON.

### Envelope

All messages use the same envelope shape:

```json
{
  "protocolVersion": 1,
  "id": "msg-0001",
  "type": "initialize",
  "payload": {}
}
```

Rules:

- `protocolVersion` is required and must match on both sides.
- `id` is a host-assigned or web-assigned opaque identifier for logging and correlation.
- `type` is the discriminant.
- `payload` contains the typed body.

## Native-to-Web Messages

### `initialize`

Sent once after the page is loaded and the script bridge is ready.

```json
{
  "protocolVersion": 1,
  "id": "msg-0001",
  "type": "initialize",
  "payload": {
    "rendererVersion": "1.0.11+yitong.1",
    "platform": "ios",
    "resolvedAppearance": "dark",
    "features": {
      "selection": true,
      "workerMode": false
    }
  }
}
```

Notes:

- `resolvedAppearance` is the already-resolved appearance, not `.automatic`.
- `rendererVersion` refers to the bundled web renderer build boundary, not just upstream npm version.

### `renderDocument`

Sent for the initial render and whenever the current document changes.

```json
{
  "protocolVersion": 1,
  "id": "msg-0002",
  "type": "renderDocument",
  "payload": {
    "document": {
      "identifier": "document-1",
      "title": "Example Diff",
      "patch": "diff --git a/file.swift b/file.swift\n..."
    },
    "configuration": {
      "diffStyle": "split",
      "showsLineNumbers": true,
      "wrapsLines": false,
      "showsFileHeaders": true,
      "inlineChangeStyle": "wordAlt",
      "allowsSelection": true,
      "resolvedAppearance": "dark"
    }
  }
}
```

Rules:

- `renderDocument` is a full replacement render request.
- The web side must dispose previous `FileDiff` instances before re-rendering.
- The patch string may contain multiple file diffs.

### `updateConfiguration`

Sent when configuration changes without replacing the document.

```json
{
  "protocolVersion": 1,
  "id": "msg-0003",
  "type": "updateConfiguration",
  "payload": {
    "diffStyle": "unified",
    "showsLineNumbers": true,
    "wrapsLines": false,
    "showsFileHeaders": true,
    "inlineChangeStyle": "wordAlt",
    "allowsSelection": true,
    "resolvedAppearance": "light"
  }
}
```

Rules:

- This is still treated as a full configuration replacement.
- The web side may internally re-render everything to keep behavior deterministic.

### `teardown`

Sent before the native host releases the web view or when the session is intentionally ended.

```json
{
  "protocolVersion": 1,
  "id": "msg-0004",
  "type": "teardown",
  "payload": {}
}
```

## Web-to-Native Messages

### `ready`

Emitted once when the embedded web app is ready to receive native messages.

```json
{
  "protocolVersion": 1,
  "id": "evt-0001",
  "type": "ready",
  "payload": {
    "rendererVersion": "1.0.11+yitong.1"
  }
}
```

### `renderStateChanged`

Emitted when rendering starts, succeeds, or fails.

```json
{
  "protocolVersion": 1,
  "id": "evt-0002",
  "type": "renderStateChanged",
  "payload": {
    "state": "rendered",
    "documentIdentifier": "document-1",
    "summary": {
      "fileCount": 3
    }
  }
}
```

Failure form:

```json
{
  "protocolVersion": 1,
  "id": "evt-0003",
  "type": "renderStateChanged",
  "payload": {
    "state": "failed",
    "documentIdentifier": "document-1",
    "error": {
      "code": "render_failed",
      "message": "Failed to parse patch"
    }
  }
}
```

Allowed states:

- `loading`
- `rendered`
- `failed`

### `lineActivated`

Emitted when a rendered diff line is clicked.

```json
{
  "protocolVersion": 1,
  "id": "evt-0004",
  "type": "lineActivated",
  "payload": {
    "file": {
      "index": 0,
      "oldPath": "Sources/Example.swift",
      "newPath": "Sources/Example.swift"
    },
    "line": {
      "side": "new",
      "number": 42,
      "kind": "addition"
    }
  }
}
```

Allowed line sides:

- `old`
- `new`
- `unified`

Allowed line kinds:

- `context`
- `addition`
- `deletion`
- `metadata`
- `expanded`

The web layer is responsible for mapping upstream terms such as `additions` and `deletions` into `new` and `old`.

### `selectionChanged`

Emitted when line selection changes.

```json
{
  "protocolVersion": 1,
  "id": "evt-0005",
  "type": "selectionChanged",
  "payload": {
    "selection": {
      "fileIndex": 0,
      "start": {
        "side": "old",
        "number": 12
      },
      "end": {
        "side": "new",
        "number": 18
      }
    }
  }
}
```

Cleared selection form:

```json
{
  "protocolVersion": 1,
  "id": "evt-0006",
  "type": "selectionChanged",
  "payload": {
    "selection": null
  }
}
```

Rules:

- Selection is scoped to a single file diff in v1.
- Cross-file selection is invalid in v1 and must not be emitted.

## Swift-Side State Model

The native core owns the session lifecycle and translates bridge messages into native state.

### Internal States

- `idle`
- `loadingPage`
- `waitingForReady`
- `renderingDocument`
- `rendered`
- `failed`
- `terminated`

### State Ownership

- `WKWebView` lifecycle is owned by `YiTongWebViewHost`.
- JSON encoding and decoding is owned by `YiTongBridge`.
- Public event emission is owned by `YiTongCore`.
- SwiftUI and UIKit/AppKit wrappers remain thin.

## Repository Structure

The repository will use one Swift package plus one small web renderer workspace.

```text
/
  README.md
  Package.swift
  Sources/
    YiTong/
      DiffView.swift
      DiffViewController.swift
      DiffDocument.swift
      DiffConfiguration.swift
      DiffEvent.swift
    YiTongCore/
      YiTongWebViewHost.swift
      YiTongRendererSession.swift
      YiTongRendererState.swift
    YiTongBridge/
      YiTongBridgeMessage.swift
      YiTongBridgeCodec.swift
      YiTongBridgeSchema.swift
    YiTongWebAssets/
      Resources/
        index.html
        renderer.js
        renderer.css
        manifest.json
  Tests/
    YiTongTests/
    YiTongCoreTests/
    YiTongBridgeTests/
  WebRenderer/
    package.json
    package-lock.json
    vite.config.ts
    src/
      main.ts
      bridge.ts
      renderer.ts
      protocol.ts
      theme.ts
    scripts/
      copy-assets.mjs
  Examples/
    YiTongExamples/
  docs/
    2026-02-28-INIT-DESIGN.md
    plans/
```

### Structure Decisions

- `YiTong` is the public Swift target.
- `YiTongCore`, `YiTongBridge`, and `YiTongWebAssets` are internal implementation targets.
- `WebRenderer/` is the only place that requires Node tooling.
- Checked-in bundled assets live under `Sources/YiTongWebAssets/Resources/`.
- Example apps are not required for the first commit, but the path is reserved now.

## Packaging Strategy

### Swift Packaging

- Use a single `Package.swift`.
- Bundle web assets as SwiftPM resources.
- The public package product is `YiTong`.
- Internal targets are implementation details even though they exist in the package graph.

### Web Packaging

- Use Vite to produce a deterministic browser bundle.
- Pin `@pierre/diffs` to an exact version.
- Generate a small static app, not a general-purpose web app shell.
- Check generated assets into git.

### Runtime Asset Shape

The v1 bundled asset set is intentionally small:

- `index.html`
- `renderer.js`
- `renderer.css`
- `manifest.json`

No worker assets are bundled in v1.

### Build and Update Workflow

The intended asset workflow is:

1. Update the pinned web dependency in `WebRenderer/package.json`.
2. Build the renderer bundle inside `WebRenderer/`.
3. Copy the generated assets into `Sources/YiTongWebAssets/Resources/`.
4. Record the renderer version in `manifest.json`.
5. Commit both source changes and generated assets together.

This keeps app runtime free of Node while making renderer updates explicit and reviewable.

## Renderer Compatibility Policy

There are two compatibility boundaries:

- Public Swift API version
- Bundled web renderer version

The bridge protocol version is the hard compatibility wall between them.

Rules:

- The Swift code and bundled web assets in one commit must agree on the same `protocolVersion`.
- Upgrading upstream `@pierre/diffs` does not automatically imply a public API change.
- Any bridge schema change increments the internal protocol version.
- Any renderer asset refresh must be treated as an explicit maintenance task.

## Testing Strategy

The initial design assumes the following test split:

- `YiTongBridgeTests`
  Validate JSON encoding and decoding for every schema message and event.
- `YiTongCoreTests`
  Validate state transitions and message sequencing around page load and render lifecycle.
- `YiTongTests`
  Smoke test `DiffView` and `DiffViewController` construction on supported platforms.
- Manual verification
  Render small, medium, and large multi-file patches inside SwiftUI and UIKit/AppKit hosts.

Web-side verification should include:

- parsing and rendering a multi-file patch with `parsePatchFiles(...)`
- event mapping for click and selection
- appearance switching between resolved light and dark themes

## Deferred Decisions

These are intentionally deferred until after the initial implementation proves out:

- Worker mode enablement
- Public file navigation UI
- Programmatic native-to-web selection synchronization
- Public annotation APIs
- Virtualization or large-patch special modes
- AppKit-specific wrapper details beyond sharing `DiffViewController`

## Immediate Implementation Constraints

The first implementation pass must follow these constraints:

- No React inside the embedded renderer.
- No worker mode.
- Multi-file patch rendering must be supported from day one.
- Public UI names must stay `DiffView` and `DiffViewController`.
- Internal bridge schema must match this document exactly unless the document is revised first.

## Implementation Starting Point

The first implementation milestone should establish only the following:

- Swift package skeleton with the target structure above
- bundled `WKWebView` host that can load local assets
- `initialize`, `renderDocument`, `ready`, and `renderStateChanged` messages
- rendering of a multi-file unified diff patch

Line click and selection can follow immediately after the basic render loop is stable, but the schema for them is locked in this design now.
