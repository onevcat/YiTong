import AppKit
import SwiftUI
import YiTong

if getenv("YITONG_DEBUG") == nil {
  setenv("YITONG_DEBUG", "1", 1)
}

final class AppDelegate: NSObject, NSApplicationDelegate {
  private var window: NSWindow?

  func applicationDidFinishLaunching(_ notification: Notification) {
    let rootView = ExampleContentView()
    let hostingView = NSHostingView(rootView: rootView)

    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800),
      styleMask: [.titled, .closable, .miniaturizable, .resizable],
      backing: .buffered,
      defer: false
    )
    window.title = "YiTong Example"
    window.center()
    window.contentView = hostingView
    window.makeKeyAndOrderFront(nil)

    self.window = window

    NSApp.activate(ignoringOtherApps: true)
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    true
  }
}

struct ExampleContentView: View {
  @State private var latestEvent: String = "Waiting for renderer..."

  private let document = DiffDocument(
    patch: SamplePatch.multiFile,
    title: "YiTong Example"
  )

  var body: some View {
    VStack(spacing: 0) {
      header
      Divider()
      DiffView(
        document: document,
        configuration: .default,
        onEvent: { event in
          latestEvent = describe(event)
        }
      )
    }
    .frame(minWidth: 960, minHeight: 640)
  }

  private var header: some View {
    HStack(alignment: .firstTextBaseline, spacing: 12) {
      VStack(alignment: .leading, spacing: 4) {
        Text("YiTong Example")
          .font(.title3.weight(.semibold))
        Text("Renders an embedded multi-file patch through WKWebView.")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      Spacer()
      Text(latestEvent)
        .font(.callout.monospaced())
        .foregroundStyle(.secondary)
    }
    .padding(16)
    .background(.bar)
  }

  private func describe(_ event: DiffEvent) -> String {
    switch event {
    case .didFinishInitialLoad:
      return "didFinishInitialLoad"
    case .didRender(let summary):
      return "didRender(fileCount: \(summary.fileCount))"
    case .didClickLine(let line):
      return "didClickLine(fileIndex: \(line.fileIndex), line: \(line.number))"
    case .didChangeSelection(let selection):
      if let selection {
        return "didChangeSelection(fileIndex: \(selection.fileIndex))"
      }
      return "didChangeSelection(nil)"
    case .didFail(let error):
      return "didFail(\(error.code))"
    }
  }
}

let application = NSApplication.shared
let delegate = AppDelegate()

application.setActivationPolicy(.regular)
application.delegate = delegate
application.run()
