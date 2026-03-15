# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

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
