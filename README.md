# YiTong

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://github.com/user-attachments/assets/59df1005-12f4-418f-9188-06d28382895e">
    <source media="(prefers-color-scheme: light)" srcset="https://github.com/user-attachments/assets/16eed628-0799-4754-bde8-05889d499f2a">
    <img src="https://github.com/user-attachments/assets/16eed628-0799-4754-bde8-05889d499f2a" alt="YiTong logo">
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

Add YiTong as a Swift Package dependency:

```swift
dependencies: [
  .package(url: "https://github.com/onevcat/YiTong.git", branch: "master")
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

## Common Usage

### SwiftUI

```swift
import SwiftUI
import YiTong

struct ContentView: View {
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

### UIKit / AppKit

```swift
import YiTong

let controller = DiffViewController(
  document: DiffDocument(patch: patchString),
  configuration: DiffConfiguration(style: .unified)
)
```

### Handling Events

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

### File-based Input

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

- [LICENSE](/Users/onevcat/Sync/github/YiTong/LICENSE)
- [NOTICE](/Users/onevcat/Sync/github/YiTong/NOTICE)
- [THIRD_PARTY_NOTICES.md](/Users/onevcat/Sync/github/YiTong/THIRD_PARTY_NOTICES.md)
