# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]
### Added
- Annotations: `DiffAnnotation` attaches host-rendered HTML or text beneath a diff line, `DiffView` and `DiffViewController` accept an `annotations` list, `DiffViewController.update(annotations:)` updates them in place, and `DiffEvent.didActivateAnnotation` reports clicks on `data-action` elements.
- Bridge protocol: `renderDocument` carries `annotations`, new `updateAnnotations` command and `annotationActivated` event.
- Example app: sample discussion thread with Reply and Resolve actions.

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
