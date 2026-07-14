import SwiftUI

#if canImport(UIKit)
public struct DiffView: UIViewControllerRepresentable {
  private let document: DiffDocument
  private let configuration: DiffConfiguration
  private let onEvent: ((DiffEvent) -> Void)?

  public init(
    document: DiffDocument,
    configuration: DiffConfiguration = .default,
    onEvent: ((DiffEvent) -> Void)? = nil
  ) {
    self.document = document
    self.configuration = configuration
    self.onEvent = onEvent
  }

  public func makeUIViewController(context: Context) -> DiffViewController {
    DiffViewController(document: document, configuration: configuration, onEvent: onEvent)
  }

  public func updateUIViewController(_ uiViewController: DiffViewController, context: Context) {
    uiViewController.update(document: document, configuration: configuration, onEvent: onEvent)
  }
}
#elseif canImport(AppKit)
public struct DiffView: NSViewControllerRepresentable {
  private let document: DiffDocument
  private let configuration: DiffConfiguration
  private let onEvent: ((DiffEvent) -> Void)?
  // Lets the caller retain the created controller so it can
  // request a snapshot() of the currently-painted WebView content on demand.
  private let onControllerReady: ((DiffViewController) -> Void)?

  public init(
    document: DiffDocument,
    configuration: DiffConfiguration = .default,
    onEvent: ((DiffEvent) -> Void)? = nil,
    onControllerReady: ((DiffViewController) -> Void)? = nil
  ) {
    self.document = document
    self.configuration = configuration
    self.onEvent = onEvent
    self.onControllerReady = onControllerReady
  }

  public func makeNSViewController(context: Context) -> DiffViewController {
    let controller = DiffViewController(document: document, configuration: configuration, onEvent: onEvent)
    onControllerReady?(controller)
    return controller
  }

  public func updateNSViewController(_ nsViewController: DiffViewController, context: Context) {
    nsViewController.update(document: document, configuration: configuration, onEvent: onEvent)
  }
}
#endif
