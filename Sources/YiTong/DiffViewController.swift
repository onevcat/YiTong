import Foundation
import YiTongCore
import YiTongBridge

#if canImport(UIKit)
import UIKit

@MainActor
public final class DiffViewController: UIViewController {
  private let host = YiTongWebViewHost(platform: .ios)
  private var document: DiffDocument
  private var configuration: DiffConfiguration
  private var annotations: [DiffAnnotation]
  private let onEvent: ((DiffEvent) -> Void)?
  private var documentIdentifier = UUID().uuidString

  public init(
    document: DiffDocument,
    configuration: DiffConfiguration = .default,
    annotations: [DiffAnnotation] = [],
    onEvent: ((DiffEvent) -> Void)? = nil
  ) {
    self.document = document
    self.configuration = configuration
    self.annotations = annotations
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
    YiTongPublicModelAdapter.makeRenderRequest(
      documentIdentifier: documentIdentifier,
      document: document,
      configuration: configuration,
      annotations: annotations,
      resolvedAppearance: resolveAppearance(configuration.appearance)
    )
  }

  /// Replaces the annotations shown beneath diff lines without re-rendering the document.
  public func update(annotations: [DiffAnnotation]) {
    update(document: document, configuration: configuration, annotations: annotations)
  }

  func update(document: DiffDocument, configuration: DiffConfiguration) {
    update(document: document, configuration: configuration, annotations: annotations)
  }

  func update(document: DiffDocument, configuration: DiffConfiguration, annotations: [DiffAnnotation]) {
    let documentChanged = self.document != document
    let configurationChanged = self.configuration != configuration
    let annotationsChanged = self.annotations != annotations

    guard documentChanged || configurationChanged || annotationsChanged else {
      return
    }

    self.document = document
    self.configuration = configuration
    self.annotations = annotations

    guard isViewLoaded else {
      if documentChanged {
        documentIdentifier = UUID().uuidString
      }
      return
    }

    if documentChanged {
      documentIdentifier = UUID().uuidString
      host.render(request: makeRenderRequest())
      return
    }

    if configurationChanged {
      host.updateConfiguration(makeRenderRequest().configuration)
    }

    if annotationsChanged {
      host.updateAnnotations(makeRenderRequest().annotations)
    }
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
    onEvent?(YiTongPublicModelAdapter.makeDiffEvent(from: event))
  }
}
#elseif canImport(AppKit)
import AppKit

@MainActor
public final class DiffViewController: NSViewController {
  private let host = YiTongWebViewHost(platform: .macos)
  private var document: DiffDocument
  private var configuration: DiffConfiguration
  private var annotations: [DiffAnnotation]
  private let onEvent: ((DiffEvent) -> Void)?
  private var documentIdentifier = UUID().uuidString

  public init(
    document: DiffDocument,
    configuration: DiffConfiguration = .default,
    annotations: [DiffAnnotation] = [],
    onEvent: ((DiffEvent) -> Void)? = nil
  ) {
    self.document = document
    self.configuration = configuration
    self.annotations = annotations
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
    YiTongPublicModelAdapter.makeRenderRequest(
      documentIdentifier: documentIdentifier,
      document: document,
      configuration: configuration,
      annotations: annotations,
      resolvedAppearance: resolveAppearance(configuration.appearance)
    )
  }

  /// Replaces the annotations shown beneath diff lines without re-rendering the document.
  public func update(annotations: [DiffAnnotation]) {
    update(document: document, configuration: configuration, annotations: annotations)
  }

  func update(document: DiffDocument, configuration: DiffConfiguration) {
    update(document: document, configuration: configuration, annotations: annotations)
  }

  func update(document: DiffDocument, configuration: DiffConfiguration, annotations: [DiffAnnotation]) {
    let documentChanged = self.document != document
    let configurationChanged = self.configuration != configuration
    let annotationsChanged = self.annotations != annotations

    guard documentChanged || configurationChanged || annotationsChanged else {
      return
    }

    self.document = document
    self.configuration = configuration
    self.annotations = annotations

    guard isViewLoaded else {
      if documentChanged {
        documentIdentifier = UUID().uuidString
      }
      return
    }

    if documentChanged {
      documentIdentifier = UUID().uuidString
      host.render(request: makeRenderRequest())
      return
    }

    if configurationChanged {
      host.updateConfiguration(makeRenderRequest().configuration)
    }

    if annotationsChanged {
      host.updateAnnotations(makeRenderRequest().annotations)
    }
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
    onEvent?(YiTongPublicModelAdapter.makeDiffEvent(from: event))
  }
}
#endif
