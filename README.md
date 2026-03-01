# YiTong

<p align="center">
  <img src="https://github.com/user-attachments/assets/c45e8800-0179-4e83-bf22-e10577dcb45e" alt="YiTong logo">
</p>

YiTong provides `DiffView` and `DiffViewController` for rendering diffs on Apple platforms.
It is a native Apple-platform wrapper around [diffs.com](https://diffs.com/).

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
