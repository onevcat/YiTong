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
  @State private var eventLog: [String] = []
  @State private var style: DiffStyle = .split
  @State private var indicators: DiffIndicators = .bars
  @State private var showsLineNumbers = true
  @State private var showsChangeBackgrounds = true
  @State private var wrapsLines = false
  @State private var showsFileHeaders = true
  @State private var allowsSelection = true

  private let document = DiffDocument(
    patch: SamplePatch.multiFile,
    title: "YiTong Example"
  )

  var body: some View {
    VStack(spacing: 0) {
      header
      Divider()
      HSplitView {
        controlPanel
          .frame(minWidth: 280, idealWidth: 320, maxWidth: 360)
        DiffView(
          document: document,
          configuration: configuration,
          onEvent: handleEvent
        )
      }
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

  private var controlPanel: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        GroupBox("Layout") {
          VStack(alignment: .leading, spacing: 12) {
            Picker("Style", selection: $style) {
              Text("Split").tag(DiffStyle.split)
              Text("Unified").tag(DiffStyle.unified)
            }

            Picker("Indicators", selection: $indicators) {
              Text("Bars").tag(DiffIndicators.bars)
              Text("Classic").tag(DiffIndicators.classic)
              Text("None").tag(DiffIndicators.none)
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }

        GroupBox("Display") {
          VStack(alignment: .leading, spacing: 10) {
            Toggle("Show line numbers", isOn: $showsLineNumbers)
            Toggle("Show change backgrounds", isOn: $showsChangeBackgrounds)
            Toggle("Wrap long lines", isOn: $wrapsLines)
            Toggle("Show file headers", isOn: $showsFileHeaders)
            Toggle("Allow text selection", isOn: $allowsSelection)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }

        GroupBox("Acceptance") {
          VStack(alignment: .leading, spacing: 8) {
            Text("Use the controls to verify runtime updates without reloading the host app.")
              .font(.callout)
              .foregroundStyle(.secondary)

            Button("Reset to Defaults", action: resetConfiguration)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }

        GroupBox("Recent Events") {
          VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(eventLog.enumerated()), id: \.offset) { _, event in
              Text(event)
                .font(.footnote.monospaced())
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if eventLog.isEmpty {
              Text("No events yet.")
                .font(.footnote)
                .foregroundStyle(.tertiary)
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
      .padding(16)
    }
    .background(Color(nsColor: .windowBackgroundColor))
  }

  private var configuration: DiffConfiguration {
    DiffConfiguration(
      style: style,
      indicators: indicators,
      showsLineNumbers: showsLineNumbers,
      showsChangeBackgrounds: showsChangeBackgrounds,
      wrapsLines: wrapsLines,
      showsFileHeaders: showsFileHeaders,
      allowsSelection: allowsSelection
    )
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

  private func handleEvent(_ event: DiffEvent) {
    let description = describe(event)
    latestEvent = description
    eventLog = Array(([description] + eventLog).prefix(8))
  }

  private func resetConfiguration() {
    style = .split
    indicators = .bars
    showsLineNumbers = true
    showsChangeBackgrounds = true
    wrapsLines = false
    showsFileHeaders = true
    allowsSelection = true
  }
}

let application = NSApplication.shared
let delegate = AppDelegate()

application.setActivationPolicy(.regular)
application.delegate = delegate
application.run()
