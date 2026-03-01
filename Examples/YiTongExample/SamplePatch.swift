import Foundation
import YiTong

enum SamplePatch {
  static let multiFile = """
  diff --git a/Sources/App/Counter.swift b/Sources/App/Counter.swift
  index 1111111..2222222 100644
  --- a/Sources/App/Counter.swift
  +++ b/Sources/App/Counter.swift
  @@ -1,7 +1,11 @@
   import Foundation
   
   struct Counter {
  -  var value: Int
  +  private(set) var value: Int
  +
  +  mutating func reset() {
  +    value = 0
  +  }
   
     mutating func increment() {
       value += 1
  diff --git a/Sources/App/AppView.swift b/Sources/App/AppView.swift
  index 3333333..4444444 100644
  --- a/Sources/App/AppView.swift
  +++ b/Sources/App/AppView.swift
  @@ -1,8 +1,12 @@
   import SwiftUI
   
   struct AppView: View {
  -  @State private var count = 0
  +  @State private var counter = Counter(value: 0)
   
     var body: some View {
  -    Text("\\(count)")
  +    VStack(spacing: 12) {
  +      Text("\\(counter.value)")
  +      Button("Reset") { counter.reset() }
  +    }
     }
   }
  """

  static let fileBasedMultiFile: [DiffFile] = [
    DiffFile(
      oldPath: "Sources/App/Counter.swift",
      newPath: "Sources/App/Counter.swift",
      oldContents: counterOld,
      newContents: counterNew
    ),
    DiffFile(
      oldPath: "Sources/App/AppView.swift",
      newPath: "Sources/App/AppView.swift",
      oldContents: appViewOld,
      newContents: appViewNew
    ),
  ]

  private static let counterOld = makeCounterSource(
    valueLine: "  var value: Int",
    extraMethodLines: []
  )

  private static let counterNew = makeCounterSource(
    valueLine: "  private(set) var value: Int",
    extraMethodLines: [
      "",
      "  mutating func reset() {",
      "    value = 0",
      "  }",
    ]
  )

  private static let appViewOld = makeAppViewSource(
    stateLine: "  @State private var count = 0",
    bodyLines: [
      "    Text(\"\\(count)\")",
    ]
  )

  private static let appViewNew = makeAppViewSource(
    stateLine: "  @State private var counter = Counter(value: 0)",
    bodyLines: [
      "    VStack(spacing: 12) {",
      "      Text(\"\\(counter.value)\")",
      "      Button(\"Reset\") { counter.reset() }",
      "    }",
    ]
  )

  private static let counterHeaderLines = [
    "import Foundation",
    "",
  ]

  private static let counterSeedLines = (1...36).map {
    "private let counterSeed\($0) = \($0)"
  }

  private static let counterFooterLines = (1...24).map {
    "private let counterFooter\($0) = \"Footer \($0)\""
  }

  private static let appViewHeaderLines = [
    "import SwiftUI",
    "",
  ]

  private static let appViewSeedLines = (1...28).map {
    "private let previewTitle\($0) = \"Preview \($0)\""
  }

  private static let appViewFooterLines = (1...20).map {
    "private let appViewFooter\($0) = \"Footer \($0)\""
  }

  private static func makeCounterSource(
    valueLine: String,
    extraMethodLines: [String]
  ) -> String {
    let lines = counterHeaderLines
      + counterSeedLines
      + [
      "",
      "struct Counter {",
      valueLine,
      ]
      + extraMethodLines
      + [
      "",
      "  mutating func increment() {",
      "    value += 1",
      "  }",
      "}",
      "",
      ]
      + counterFooterLines
      + [
      "",
    ]

    return lines.joined(separator: "\n")
  }

  private static func makeAppViewSource(
    stateLine: String,
    bodyLines: [String]
  ) -> String {
    let lines = appViewHeaderLines
      + appViewSeedLines
      + [
      "",
      "struct AppView: View {",
      stateLine,
      "",
      "  var body: some View {",
      ]
      + bodyLines
      + [
      "  }",
      "}",
      "",
      ]
      + appViewFooterLines
      + [
      "",
    ]

    return lines.joined(separator: "\n")
  }
}
