# YiTong

YiTong is an Apple-platform wrapper around `diffs.com`, exposing a native-feeling diff viewer for SwiftUI, UIKit, and AppKit while rendering through `WKWebView` internally.

The first goal is not to build a new diff engine. It is to define a stable Apple API surface for loading, displaying, and interacting with beautiful diffs backed by a proven web renderer.

See [docs/plans/2026-02-28-yitong-web-wrapper-plan.md](docs/plans/2026-02-28-yitong-web-wrapper-plan.md) for the initial project plan.

## Development Workflow

YiTong is a Swift package with bundled web assets.

- Regular Swift users should not need Node or npm to build and test the package.
- Web tooling is only required when maintaining or regenerating the bundled renderer assets under `Sources/YiTongWebAssets/Resources/`.

### Official Entry Point

Use `make` as the canonical task runner:

```bash
make help
```

For people who prefer `just`, a thin `Justfile` is included and delegates to the same `make` targets:

```bash
just help
```

### Common Commands

Swift-only verification:

```bash
make verify-swift
```

Default verification:

```bash
make verify
```

This always runs Swift verification. Web verification runs only when `node`, `npm`, and installed `WebRenderer` dependencies are available.

### Minimal Visual Harness

To manually verify that `DiffView` actually renders in a macOS window:

```bash
make run-example
```

This launches a minimal macOS example app backed by the current local package code and bundled web assets.

The example is also the preferred manual acceptance path for the current public surface. It exposes live controls for:

- split vs unified layout
- diff indicators
- line numbers
- change backgrounds
- line wrapping
- file headers
- selection behavior

The expected behavior is that these updates apply while the host app stays running, and that event output continues to update in the example sidebar.

## Feature Mapping

YiTong intentionally exposes a smaller Swift-facing API than the full `diffs` vanilla JS surface.

For options that map cleanly into stable Apple-facing semantics, the current public API is:

| `diffs` vanilla option | YiTong public API | Status | Notes |
| --- | --- | --- | --- |
| `diffStyle` | `DiffConfiguration.style` | Supported | `split` / `unified` |
| `lineDiffType` | `DiffConfiguration.inlineChangeStyle` | Supported | `word-alt` maps to `wordAlt` |
| `diffIndicators` | `DiffConfiguration.indicators` | Supported | `bars` / `classic` / `none` |
| `disableBackground` | `DiffConfiguration.showsChangeBackgrounds` | Supported | Inverted semantics in Swift |
| `disableLineNumbers` | `DiffConfiguration.showsLineNumbers` | Supported | Inverted semantics in Swift |
| `overflow` | `DiffConfiguration.wrapsLines` | Supported | `wrap` vs scrolling behavior |
| `disableFileHeader` | `DiffConfiguration.showsFileHeaders` | Supported | Inverted semantics in Swift |
| `enableLineSelection` | `DiffConfiguration.allowsSelection` | Supported | Also drives native selection events |
| `themeType` | `DiffConfiguration.appearance` | Supported | YiTong resolves native appearance to renderer theme internally |
| `theme` | Not public | Intentionally hidden | YiTong does not expose upstream theme names in v1 |
| `renderHeaderMetadata` | Not public | Not supported | Would require a YiTong-native data model, not raw DOM injection |
| annotation/comment hooks | Not public | Not supported | Deferred until a native review model exists |
| worker pool options | Not public | Not supported | Upstream marks worker mode as experimental |
| custom DOM / unsafe CSS hooks | Not public | Not supported | Explicitly out of v1 scope |

### Naming Policy

YiTong does not mirror every upstream option name 1:1.

The rule is:

- when an option represents a stable user-facing concept on Apple platforms, expose it with a Swift-native name
- when an option leaks web implementation details, keep it internal

That is why some names differ:

- `lineDiffType` -> `inlineChangeStyle`
- `disableBackground` -> `showsChangeBackgrounds`
- `disableLineNumbers` -> `showsLineNumbers`
- `disableFileHeader` -> `showsFileHeaders`

The intent is to make the Swift API read like product semantics rather than web renderer switches, while keeping the mapping documented and explicit.

### Maintainer Workflow

Install web dependencies:

```bash
make bootstrap
```

Rebuild and sync bundled web assets:

```bash
make update-web-assets
```

This updates the checked-in files under `Sources/YiTongWebAssets/Resources/`.

### Asset Policy

The generated files under `Sources/YiTongWebAssets/Resources/` are committed to the repository.

That keeps the default Swift build path simple:

- `swift build`
- `swift test`

No runtime Node dependency is required for package consumers or for a fresh clone that only needs to build the Swift side.
