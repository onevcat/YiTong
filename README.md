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
