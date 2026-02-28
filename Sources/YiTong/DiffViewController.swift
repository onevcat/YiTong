import Foundation
import YiTongCore

#if canImport(UIKit)
import UIKit

public final class DiffViewController: UIViewController {
  private let host = YiTongWebViewHost()
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
    host.loadPlaceholderPage()
  }
}
#elseif canImport(AppKit)
import AppKit

public final class DiffViewController: NSViewController {
  private let host = YiTongWebViewHost()
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
    host.loadPlaceholderPage()
  }
}
#endif
