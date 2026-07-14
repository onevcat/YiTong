import Foundation
import YiTongCore
import YiTongBridge

@MainActor
final class DiffViewControllerEventRouter {
  private enum PendingHandoff {
    case none
    case waitingForRender(documentIdentifier: String, onEvent: ((DiffEvent) -> Void)?)
    case failed(documentIdentifier: String, onEvent: ((DiffEvent) -> Void)?)
  }

  private var onEvent: ((DiffEvent) -> Void)?
  private var pendingHandoff: PendingHandoff = .none

  init(onEvent: ((DiffEvent) -> Void)?) {
    self.onEvent = onEvent
  }

  func replaceImmediately(with onEvent: ((DiffEvent) -> Void)?) {
    self.onEvent = onEvent
    pendingHandoff = .none
  }

  func prepareUpdate(
    documentChanged: Bool,
    documentIdentifier: String,
    onEvent: ((DiffEvent) -> Void)?
  ) {
    if documentChanged {
      pendingHandoff = .waitingForRender(documentIdentifier: documentIdentifier, onEvent: onEvent)
      return
    }

    switch pendingHandoff {
    case .none:
      self.onEvent = onEvent
    case .waitingForRender(let documentIdentifier, _):
      pendingHandoff = .waitingForRender(documentIdentifier: documentIdentifier, onEvent: onEvent)
    case .failed(let documentIdentifier, _):
      pendingHandoff = .failed(documentIdentifier: documentIdentifier, onEvent: onEvent)
    }
  }

  func handle(_ event: DiffEvent, renderedDocumentIdentifier: String? = nil) {
    // Only `.didRender` reliably confirms the pending document has taken over
    // the screen. A failed pending swap keeps its own state so follow-up SwiftUI
    // updates cannot install the failed document's handler while the old document
    // is still visible.
    switch event {
    case .didRender:
      if case .waitingForRender(let documentIdentifier, let pendingOnEvent) = pendingHandoff,
         renderedDocumentIdentifier == documentIdentifier {
        onEvent = pendingOnEvent
        pendingHandoff = .none
      } else if case .failed(let documentIdentifier, let pendingOnEvent) = pendingHandoff,
                renderedDocumentIdentifier == documentIdentifier {
        onEvent = pendingOnEvent
        pendingHandoff = .none
      }
      onEvent?(event)
    case .didFail:
      switch pendingHandoff {
      case .waitingForRender(let documentIdentifier, let pendingOnEvent):
        pendingOnEvent?(event)
        pendingHandoff = .failed(documentIdentifier: documentIdentifier, onEvent: pendingOnEvent)
      case .failed(_, let pendingOnEvent):
        pendingOnEvent?(event)
      case .none:
        onEvent?(event)
      }
    default:
      onEvent?(event)
    }
  }
}

#if canImport(UIKit)
import UIKit

@MainActor
public final class DiffViewController: UIViewController {
  private let host = YiTongWebViewHost(platform: .ios)
  private var document: DiffDocument
  private var configuration: DiffConfiguration
  private let eventRouter: DiffViewControllerEventRouter
  private var documentIdentifier = UUID().uuidString

  public init(
    document: DiffDocument,
    configuration: DiffConfiguration = .default,
    onEvent: ((DiffEvent) -> Void)? = nil
  ) {
    self.document = document
    self.configuration = configuration
    self.eventRouter = DiffViewControllerEventRouter(onEvent: onEvent)
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
      resolvedAppearance: resolveAppearance(configuration.appearance)
    )
  }

  func update(document: DiffDocument, configuration: DiffConfiguration, onEvent: ((DiffEvent) -> Void)? = nil) {
    let documentChanged = self.document != document
    let configurationChanged = self.configuration != configuration

    guard isViewLoaded else {
      eventRouter.replaceImmediately(with: onEvent)

      guard documentChanged || configurationChanged else {
        return
      }

      self.document = document
      self.configuration = configuration
      if documentChanged {
        documentIdentifier = UUID().uuidString
      }
      return
    }

    let nextDocumentIdentifier = documentChanged ? UUID().uuidString : documentIdentifier
    eventRouter.prepareUpdate(
      documentChanged: documentChanged,
      documentIdentifier: nextDocumentIdentifier,
      onEvent: onEvent
    )

    guard documentChanged || configurationChanged else {
      return
    }

    self.document = document
    self.configuration = configuration

    if documentChanged {
      documentIdentifier = nextDocumentIdentifier
      host.render(request: makeRenderRequest())
    } else if configurationChanged {
      host.updateConfiguration(makeRenderRequest().configuration)
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
    let renderedDocumentIdentifier: String?
    if case .didRender(_, let documentIdentifier) = event {
      renderedDocumentIdentifier = documentIdentifier
    } else {
      renderedDocumentIdentifier = nil
    }

    eventRouter.handle(
      YiTongPublicModelAdapter.makeDiffEvent(from: event),
      renderedDocumentIdentifier: renderedDocumentIdentifier
    )
  }

  /// Captures the current WKWebView pixels so a caller can show
  /// them as a placeholder while a new render is in flight for this same document.
  public func snapshot(completion: @escaping (UIImage?) -> Void) {
    host.webView.takeSnapshot(with: nil) { image, _ in
      completion(image)
    }
  }
}
#elseif canImport(AppKit)
import AppKit

@MainActor
public final class DiffViewController: NSViewController {
  private let host = YiTongWebViewHost(platform: .macos)
  private var document: DiffDocument
  private var configuration: DiffConfiguration
  private let eventRouter: DiffViewControllerEventRouter
  private var documentIdentifier = UUID().uuidString

  public init(
    document: DiffDocument,
    configuration: DiffConfiguration = .default,
    onEvent: ((DiffEvent) -> Void)? = nil
  ) {
    self.document = document
    self.configuration = configuration
    self.eventRouter = DiffViewControllerEventRouter(onEvent: onEvent)
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
      resolvedAppearance: resolveAppearance(configuration.appearance)
    )
  }

  func update(document: DiffDocument, configuration: DiffConfiguration, onEvent: ((DiffEvent) -> Void)? = nil) {
    let documentChanged = self.document != document
    let configurationChanged = self.configuration != configuration

    // Before the view loads, nothing has ever been rendered, so there is no
    // old document on screen to protect from a premature handler swap — the
    // deferred-handoff dance below doesn't apply yet. Assign the handler
    // immediately so it's already in place for the `.didFinishInitialLoad`
    // event `viewDidLoad` triggers when the first render kicks off.
    guard isViewLoaded else {
      eventRouter.replaceImmediately(with: onEvent)

      guard documentChanged || configurationChanged else {
        return
      }

      self.document = document
      self.configuration = configuration
      if documentChanged {
        documentIdentifier = UUID().uuidString
      }
      return
    }

    // `onEvent` was previously fixed at init time, so every event fired the
    // closure captured for the *first* document ever shown, not the one
    // relevant to whichever render is currently in flight. Simply reassigning
    // it here would fix that but open a narrower race: the old document can
    // still be on screen (and generating interaction events) for a moment
    // after we've issued the new render request, since the actual repaint
    // happens asynchronously on the JS side. So a document change defers the
    // swap until that new document's own render confirms it has taken over;
    // a configuration-only change has no such transition and can swap right away.
    // While a document swap is still in flight, later handler updates must
    // also target the pending handler, not `onEvent` directly, or they'd be
    // installed before the old document has finished handing off.
    let nextDocumentIdentifier = documentChanged ? UUID().uuidString : documentIdentifier
    eventRouter.prepareUpdate(
      documentChanged: documentChanged,
      documentIdentifier: nextDocumentIdentifier,
      onEvent: onEvent
    )

    guard documentChanged || configurationChanged else {
      return
    }

    self.document = document
    self.configuration = configuration

    if documentChanged {
      documentIdentifier = nextDocumentIdentifier
      host.render(request: makeRenderRequest())
    } else if configurationChanged {
      host.updateConfiguration(makeRenderRequest().configuration)
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
    let renderedDocumentIdentifier: String?
    if case .didRender(_, let documentIdentifier) = event {
      renderedDocumentIdentifier = documentIdentifier
    } else {
      renderedDocumentIdentifier = nil
    }

    eventRouter.handle(
      YiTongPublicModelAdapter.makeDiffEvent(from: event),
      renderedDocumentIdentifier: renderedDocumentIdentifier
    )
  }

  /// Captures the current WKWebView pixels so a caller can show
  /// them as a placeholder while a new render is in flight for this same document.
  public func snapshot(completion: @escaping (NSImage?) -> Void) {
    host.webView.takeSnapshot(with: nil) { image, _ in
      completion(image)
    }
  }
}
#endif
