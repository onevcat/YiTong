import Foundation
import YiTongCore
import YiTongBridge

#if canImport(UIKit)
import UIKit

@MainActor
public final class DiffViewController: UIViewController {
  private let host = YiTongWebViewHost(platform: .ios)
  private let document: DiffDocument
  private var configuration: DiffConfiguration
  private let onEvent: ((DiffEvent) -> Void)?

  public init(
    document: DiffDocument,
    configuration: DiffConfiguration = .default,
    onEvent: ((DiffEvent) -> Void)? = nil
  ) {
    self.document = document
    self.configuration = configuration
    self.onEvent = onEvent
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override func loadView() {
    view = UIView()
    view.backgroundColor = .systemBackground
  }

  public override func viewDidLoad() {
    super.viewDidLoad()
    let webView = host.webView
    webView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(webView)
    NSLayoutConstraint.activate([
      webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      webView.topAnchor.constraint(equalTo: view.topAnchor),
      webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    host.setEventHandler { [weak self] event in
      Task { @MainActor in
        self?.handle(event)
      }
    }
    host.load(request: makeRenderRequest())
  }

  private func makeRenderRequest() -> YiTongRenderRequest {
    YiTongRenderRequest(
      document: YiTongBridgeDocumentPayload(
        identifier: "document-1",
        title: document.title,
        patch: document.patch
      ),
      configuration: YiTongBridgeConfigurationPayload(
        diffStyle: configuration.style == .split ? .split : .unified,
        showsLineNumbers: configuration.showsLineNumbers,
        wrapsLines: configuration.wrapsLines,
        showsFileHeaders: configuration.showsFileHeaders,
        inlineChangeStyle: {
          switch configuration.inlineChangeStyle {
          case .wordAlt:
            return .wordAlt
          case .word:
            return .word
          case .char:
            return .char
          case .none:
            return .none
          }
        }(),
        allowsSelection: configuration.allowsSelection,
        resolvedAppearance: resolveAppearance(configuration.appearance)
      )
    )
  }

  private func resolveAppearance(_ appearance: DiffAppearance) -> YiTongBridgeResolvedAppearance {
    switch appearance {
    case .automatic:
      return traitCollection.userInterfaceStyle == .dark ? .dark : .light
    case .light:
      return .light
    case .dark:
      return .dark
    }
  }

  private func handle(_ event: YiTongHostEvent) {
    switch event {
    case .didFinishInitialLoad:
      onEvent?(.didFinishInitialLoad)
    case .didRender(let fileCount):
      onEvent?(.didRender(DiffRenderSummary(fileCount: fileCount)))
    case .didFail(let code, let message):
      onEvent?(.didFail(DiffError(code: code, message: message)))
    }
  }
}
#elseif canImport(AppKit)
import AppKit

@MainActor
public final class DiffViewController: NSViewController {
  private let host = YiTongWebViewHost(platform: .macos)
  private let document: DiffDocument
  private var configuration: DiffConfiguration
  private let onEvent: ((DiffEvent) -> Void)?

  public init(
    document: DiffDocument,
    configuration: DiffConfiguration = .default,
    onEvent: ((DiffEvent) -> Void)? = nil
  ) {
    self.document = document
    self.configuration = configuration
    self.onEvent = onEvent
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override func loadView() {
    view = NSView()
  }

  public override func viewDidLoad() {
    super.viewDidLoad()
    let webView = host.webView
    webView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(webView)
    NSLayoutConstraint.activate([
      webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      webView.topAnchor.constraint(equalTo: view.topAnchor),
      webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    host.setEventHandler { [weak self] event in
      Task { @MainActor in
        self?.handle(event)
      }
    }
    host.load(request: makeRenderRequest())
  }

  private func makeRenderRequest() -> YiTongRenderRequest {
    YiTongRenderRequest(
      document: YiTongBridgeDocumentPayload(
        identifier: "document-1",
        title: document.title,
        patch: document.patch
      ),
      configuration: YiTongBridgeConfigurationPayload(
        diffStyle: configuration.style == .split ? .split : .unified,
        showsLineNumbers: configuration.showsLineNumbers,
        wrapsLines: configuration.wrapsLines,
        showsFileHeaders: configuration.showsFileHeaders,
        inlineChangeStyle: {
          switch configuration.inlineChangeStyle {
          case .wordAlt:
            return .wordAlt
          case .word:
            return .word
          case .char:
            return .char
          case .none:
            return .none
          }
        }(),
        allowsSelection: configuration.allowsSelection,
        resolvedAppearance: resolveAppearance(configuration.appearance)
      )
    )
  }

  private func resolveAppearance(_ appearance: DiffAppearance) -> YiTongBridgeResolvedAppearance {
    switch appearance {
    case .automatic:
      return view.effectiveAppearance.bestMatch(from: [NSAppearance.Name.darkAqua, NSAppearance.Name.aqua]) == .darkAqua ? .dark : .light
    case .light:
      return .light
    case .dark:
      return .dark
    }
  }

  private func handle(_ event: YiTongHostEvent) {
    switch event {
    case .didFinishInitialLoad:
      onEvent?(.didFinishInitialLoad)
    case .didRender(let fileCount):
      onEvent?(.didRender(DiffRenderSummary(fileCount: fileCount)))
    case .didFail(let code, let message):
      onEvent?(.didFail(DiffError(code: code, message: message)))
    }
  }
}
#endif
