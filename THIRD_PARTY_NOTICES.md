# Third-Party Notices

YiTong bundles web-renderer assets for local `WKWebView` rendering.

Those bundled assets may include mechanically transformed or minified code
derived from third-party packages during the `WebRenderer` build step.

The complete license text and attribution for all 53 installed non-development
packages represented by `WebRenderer/package-lock.json` is generated at:

- `LICENSES/WebRenderer-THIRD-PARTY-LICENSES.txt`
- `Sources/YiTongWebAssets/Resources/WebRenderer-THIRD-PARTY-LICENSES.txt`

Run `npm run licenses` after dependency changes. `make verify` checks that the
committed documentation copy and SwiftPM resource both match the lockfile and
installed production dependency tree. The sections below call out the direct
Pierre renderer packages.

## `@pierre/diffs`

- Package: `@pierre/diffs`
- Version used by this repository: `1.2.12`
- Upstream repository: <https://github.com/pierrecomputer/pierre>
- Upstream source path: <https://github.com/pierrecomputer/pierre/tree/main/packages/diffs>
- Copyright: Pierre Computer Company
- License: Apache License 2.0

YiTong uses `@pierre/diffs` as the embedded web diff renderer that powers the
bundled assets under `Sources/YiTongWebAssets/Resources/`.

The full Apache 2.0 license text for this dependency is included in:

- `LICENSES/pierre-diffs-APACHE-2.0.txt`

## `@pierre/theme`

- Package: `@pierre/theme`
- Version used by this repository: `1.1.0`
- Upstream repository: <https://github.com/pierrecomputer/pierre>
- Upstream source path: <https://github.com/pierrecomputer/pierre/tree/main/packages/theme>
- Copyright: 2026 The Pierre Computer Company
- License: MIT

The full MIT license text for this dependency is included in:

- `LICENSES/pierre-theme-MIT.txt`

## `@pierre/theming`

- Package: `@pierre/theming`
- Version used by this repository: `0.0.2`
- Upstream repository: <https://github.com/pierrecomputer/pierre>
- Upstream source path: <https://github.com/pierrecomputer/pierre/tree/main/packages/theming>
- Copyright: Pierre Computer Company
- License: Apache License 2.0

The full Apache 2.0 license text for this dependency is included in:

- `LICENSES/pierre-diffs-APACHE-2.0.txt`
