# YiTong

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://github.com/onevcat/YiTong/releases/download/0.1.0/yitong-logo-dark-0.1.0.png">
    <source media="(prefers-color-scheme: light)" srcset="https://github.com/onevcat/YiTong/releases/download/0.1.0/yitong-logo-light-0.1.0.png">
    <img src="https://github.com/onevcat/YiTong/releases/download/0.1.0/yitong-logo-light-0.1.0.png" alt="YiTong logo">
  </picture>
</p>

YiTong provides `DiffView` and `DiffViewController` for rendering diffs on Apple platforms.
It is an Apple-platform wrapper around [diffs.com](https://diffs.com/), rendered through `WKWebView`.
It supports both unified patch input and file-based old/new contents input.

YiTong = 异同
> 析其所异，合其所同。

## Preview

![YiTong Example App](https://github.com/user-attachments/assets/43dca931-7c94-4afd-94d5-f88006aa4a9a)

## Integration

YiTong supports:

- iOS 16+
- macOS 13+

For released builds, prefer a tagged Swift Package dependency:

```swift
dependencies: [
  .package(url: "https://github.com/onevcat/YiTong.git", from: "0.1.0")
]
```

Then add the product to your target:

```swift
targets: [
  .target(
    name: "MyApp",
    dependencies: [
      .product(name: "YiTong", package: "YiTong")
    ]
  )
]
```

Replace `0.1.0` with the latest tagged release.
If you need unreleased changes during development, you can temporarily track `branch: "master"` instead.

## Common Usage

### Create a DiffDocument

#### Files

```swift
import YiTong

let document = DiffDocument(
  files: [
    DiffFile(
      oldPath: "Sources/Counter.swift",
      newPath: "Sources/Counter.swift",
      oldContents: "struct Counter { var value: Int }\n",
      newContents: "struct Counter { private(set) var value: Int }\n"
    ),
  ],
  title: "Counter.swift"
)
```

If you also have the original patch text, pass it as `fallbackPatch`.
YiTong automatically falls back to patch-based rendering when file-based input exceeds supported limits.

#### Patch

```swift
import YiTong

let document = DiffDocument(
  patch: """
  diff --git a/Example.swift b/Example.swift
  --- a/Example.swift
  +++ b/Example.swift
  @@ -1,3 +1,3 @@
  -let value = 1
  +let value = 2
  """
)
```

Use `files` when your app already has old/new contents in memory.
Use `patch` when you already have unified diff output, or when patch text is the more natural transport format.

### Render the Diff

#### SwiftUI

```swift
import SwiftUI
import YiTong

struct ContentView: View {
  let document: DiffDocument

  var body: some View {
    DiffView(
      document: document,
      configuration: DiffConfiguration(
        appearance: .automatic,
        style: .split,
        indicators: .bars
      )
    )
  }
}
```

#### Integrate With Your Own File List

When your app already provides file navigation, render one file at a time and hide YiTong's built-in file header.
This is the integration pattern used in `supacode`.

```swift
import SwiftUI
import YiTong

struct DiffDetailView: View {
  let selectedFile: DiffFile
  let selectedTitle: String
  let selectedPatch: String?

  var body: some View {
    DiffView(
      document: DiffDocument(
        files: [selectedFile],
        title: selectedTitle,
        fallbackPatch: selectedPatch
      ),
      configuration: DiffConfiguration(
        style: .split,
        showsFileHeaders: false
      )
    )
  }
}
```

#### UIKit / AppKit

```swift
import YiTong

let controller = DiffViewController(
  document: document,
  configuration: DiffConfiguration(style: .unified)
)
```

### Handle Events

```swift
DiffView(
  document: document,
  onEvent: { event in
    switch event {
    case .didFinishInitialLoad:
      break
    case .didRender(let summary):
      print(summary.fileCount)
    case .didClickLine(let line):
      print(line.fileIndex, line.number)
    case .didChangeSelection(let selection):
      print(selection as Any)
    case .didFail(let error):
      print(error.code, error.message)
    }
  }
)
```

## Configuration

`DiffConfiguration` currently supports:

- `appearance`: `.automatic`, `.light`, `.dark`
- `style`: `.split`, `.unified`
- `indicators`: `.bars`, `.classic`, `.none`
- `showsLineNumbers`
- `showsChangeBackgrounds`
- `wrapsLines`
- `showsFileHeaders`
- `inlineChangeStyle`: `.wordAlt`, `.word`, `.char`, `.none`
- `allowsSelection`

## Feature Mapping

YiTong exposes a smaller Swift-facing API than the full `diffs` vanilla JS surface.

| `diffs` vanilla option | YiTong public API | Status |
| --- | --- | --- |
| `diffStyle` | `DiffConfiguration.style` | Supported |
| `lineDiffType` | `DiffConfiguration.inlineChangeStyle` | Supported |
| `diffIndicators` | `DiffConfiguration.indicators` | Supported |
| `disableBackground` | `DiffConfiguration.showsChangeBackgrounds` | Supported |
| `disableLineNumbers` | `DiffConfiguration.showsLineNumbers` | Supported |
| `overflow` | `DiffConfiguration.wrapsLines` | Supported |
| `disableFileHeader` | `DiffConfiguration.showsFileHeaders` | Supported |
| `enableLineSelection` | `DiffConfiguration.allowsSelection` | Supported |
| `themeType` | `DiffConfiguration.appearance` | Supported |
| `theme` | Not public | Hidden |
| `renderHeaderMetadata` | Not public | Not supported |
| annotation/comment hooks | Not public | Not supported |
| worker pool options | Not public | Not supported |
| custom DOM / unsafe CSS hooks | Not public | Not supported |

## Development

Most common commands:

```bash
make verify
make run-example
make update-web-assets
```

`make run-example` launches the bundled macOS example app for manual verification.

## License

YiTong is licensed under the Apache License 2.0.

This repository also bundles generated web assets derived from
`@pierre/diffs` (`Apache-2.0`) for local `WKWebView` rendering.

See:

- [LICENSE](LICENSE)
- [NOTICE](NOTICE)
- [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)
