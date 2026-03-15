# Repository Guidelines

## Project Structure & Module Organization
- `Sources/` contains Swift package targets:
  - `YiTong/`: public API (`DiffView`, `DiffViewController`, document/config models).
  - `YiTongCore/`: render coordination, request planning, diagnostics, host bridge glue.
  - `YiTongBridge/`: typed payload/schema/codec for Swift-Web communication.
  - `YiTongWebAssets/Resources/`: bundled web runtime assets loaded by `WKWebView`.
- `Tests/` mirrors Swift modules (`YiTongTests`, `YiTongCoreTests`, `YiTongBridgeTests`).
- `WebRenderer/` is the TypeScript renderer source (`src/`) and build scripts.
- `Examples/YiTongExample/` is the macOS manual verification app.
- `scripts/` hosts repo-level automation (`bootstrap`, `verify`, `update-web-assets`).

## Build, Test, and Development Commands
- `make bootstrap`: install `WebRenderer` npm dependencies.
- `make verify`: run Swift tests and, when dependencies exist, web build verification.
- `make verify-swift`: run `swift test` only.
- `make verify-web`: run `WebRenderer` production build (`vite build`).
- `make update-web-assets`: rebuild web bundle and sync generated assets into `Sources/YiTongWebAssets/Resources`.
- `make run-example`: launch `YiTongExample` for UI/manual checks.
- Optional web tests: `cd WebRenderer && npm test`.

## Coding Style & Naming Conventions
- Follow existing style; this repo uses 2-space indentation in Swift and TypeScript.
- Swift: `UpperCamelCase` for types, `lowerCamelCase` for methods/properties, file name matches primary type.
- TypeScript: ES modules, explicit `type` imports when possible, `*.test.ts` for tests.
- Prefer small, focused APIs; add comments only when intent is non-obvious.

## Testing Guidelines
- Swift tests use XCTest under `Tests/*Tests` with `test...` method naming.
- Web renderer tests use Vitest in `WebRenderer/src/*.test.ts`.
- Add/adjust tests for behavior changes, especially bridge payloads, planner logic, and rendering mode selection.
- Run relevant checks before PR: `make verify` and `cd WebRenderer && npm test` when web logic changes.

## Commit & Pull Request Guidelines
- Use concise, imperative commit subjects (examples from history: `Add ...`, `Fix ...`, `Docs: ...`).
- Keep each commit focused; include generated web assets in the same change when renderer source changes.
- PRs should include:
  - what changed and why,
  - linked issue (if any),
  - verification steps/commands run,
  - screenshots or GIFs for UI/rendering changes.
- Ensure CI is green on both Swift and WebRenderer jobs before merge.

## Web Assets Sync Rule
- Do not hand-edit files under `Sources/YiTongWebAssets/Resources/`.
- Modify `WebRenderer/src/` first, then run `make update-web-assets` and commit both source and generated outputs together.
