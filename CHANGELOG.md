# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Changed
- Update the embedded `@pierre/diffs` renderer to 1.2.12.
- Generate and verify a complete license bundle for WebRenderer production dependencies.
- Add optional diff font-size configuration with proportional line-height scaling.
- Make UIKit and AppKit configuration updates public for live renderer changes.

### Fixed
- Decode Git C-quoted UTF-8 paths so patches containing non-ASCII file names render with readable paths.
- Keep the optional Shiki WASM engine out of YiTong's JavaScript-only embedded renderer bundle.

## [0.2.0] - 2026-03-23
### Changed
- Slim renderer bundle by curating Shiki language set to ~41 languages (from 371+), reducing gzipped bundle size by ~77% (1.7 MB → 387 KB).
- Run vitest in CI alongside the web renderer build step.

### Fixed
- README logo now uses release assets for stable image URLs.

## [0.1.0] - 2026-03-15
### Added
- Initial public release of YiTong, a Swift Package that renders diffs on Apple platforms through `WKWebView`.
- `DiffView` and `DiffViewController` for SwiftUI, UIKit, and AppKit integration.
- Support for both unified patch documents and file-based old/new content documents.
- Public configuration for appearance, split/unified layout, indicators, line numbers, inline change style, file headers, wrapping, and selection.
- Bridge events for renderer readiness, render completion, line clicks, selection changes, and failures.
- Bundled web renderer assets, example app, and Swift/Web test coverage for local verification.

### Changed
- README integration guidance now documents the tagged Swift Package dependency, real-world single-file integration, and fallback patch behavior.

### Fixed
- File-based rendering falls back to patch input when configured size limits are exceeded.
- README logo workflow now supports exporting release-ready light/dark assets from the local HTML source.
