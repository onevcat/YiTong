import Foundation
import WebKit
import YiTongBridge
import YiTongWebAssets

@MainActor
public final class YiTongWebViewHost: NSObject {
  public typealias EventHandler = @Sendable (YiTongHostEvent) -> Void

  @MainActor
  private final class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var delegate: (any WKScriptMessageHandler)?

    init(delegate: (any WKScriptMessageHandler)? = nil) {
      self.delegate = delegate
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
      delegate?.userContentController(userContentController, didReceive: message)
    }
  }

  private enum Constants {
    static let scriptMessageHandlerName = "yitongBridge"
    static let diagnosticMessageHandlerName = "yitongDiagnostic"
    static let diagnosticBootstrapScript = """
    (() => {
      const diagnosticHandler = window.webkit?.messageHandlers?.yitongDiagnostic;
      if (!diagnosticHandler) {
        return;
      }

      const stringify = (value) => {
        if (typeof value === "string") {
          return value;
        }

        try {
          return JSON.stringify(value);
        } catch {
          return String(value);
        }
      };

      const send = (level, message) => {
        diagnosticHandler.postMessage(JSON.stringify({ level, message }));
      };

      for (const level of ["log", "warn", "error"]) {
        const original = console[level]?.bind(console);
        console[level] = (...args) => {
          send(level, args.map(stringify).join(" "));
          original?.(...args);
        };
      }

      window.addEventListener("error", (event) => {
        send("error", `window.error: ${event.message}`);
      });

      window.addEventListener("unhandledrejection", (event) => {
        send("error", `window.unhandledrejection: ${stringify(event.reason)}`);
      });

      send("log", "diagnostic bridge installed");
    })();
    """
  }

  public let webView: WKWebView
  private let bridgeHandlerProxy: WeakScriptMessageHandler
  private let diagnosticHandlerProxy: WeakScriptMessageHandler?
  private let platform: YiTongBridgePlatform
  private let diagnosticsEnabled: Bool
  private var coordinator = YiTongRendererCoordinator()
  private var eventHandler: EventHandler?
  private var nextMessageID = 0
  private var currentRequest: YiTongRenderRequest?

  public init(platform: YiTongBridgePlatform) {
    self.platform = platform
    self.diagnosticsEnabled = YiTongDiagnostics.isEnabled()
    let configuration = WKWebViewConfiguration()
    configuration.defaultWebpagePreferences.allowsContentJavaScript = true
    let userContentController = WKUserContentController()
    if self.diagnosticsEnabled {
      userContentController.addUserScript(
        WKUserScript(
          source: Constants.diagnosticBootstrapScript,
          injectionTime: .atDocumentStart,
          forMainFrameOnly: true
        )
      )
    }
    configuration.userContentController = userContentController
    self.webView = WKWebView(frame: .zero, configuration: configuration)

    let bridgeHandlerProxy = WeakScriptMessageHandler()
    let diagnosticHandlerProxy = self.diagnosticsEnabled ? WeakScriptMessageHandler() : nil
    self.bridgeHandlerProxy = bridgeHandlerProxy
    self.diagnosticHandlerProxy = diagnosticHandlerProxy

    super.init()

    bridgeHandlerProxy.delegate = self
    userContentController.add(bridgeHandlerProxy, name: Constants.scriptMessageHandlerName)

    if diagnosticsEnabled, let diagnosticHandlerProxy {
      diagnosticHandlerProxy.delegate = self
      userContentController.add(diagnosticHandlerProxy, name: Constants.diagnosticMessageHandlerName)
    }
    webView.navigationDelegate = self
#if os(macOS)
    webView.setValue(false, forKey: "drawsBackground")
#else
    webView.isOpaque = false
    webView.backgroundColor = .clear
    webView.scrollView.backgroundColor = .clear
#endif
  }
  public func setEventHandler(_ handler: EventHandler?) {
    eventHandler = handler
  }

  public func load(request: YiTongRenderRequest) {
    guard let plannedRequest = plan(request) else {
      return
    }

    coordinator.pageDidStartLoading()
    currentRequest = plannedRequest
    _ = coordinator.setRenderRequest(plannedRequest)

    guard
      let fileURL = YiTongWebAssets.resourceURL(for: "index", withExtension: "html")
    else {
      log("Missing bundled index.html")
      return
    }

    log("Loading file URL: \(fileURL.path)")
    webView.loadFileURL(fileURL, allowingReadAccessTo: YiTongWebAssets.resourcesDirectory)
  }

  public func render(request: YiTongRenderRequest) {
    guard let plannedRequest = plan(request) else {
      return
    }

    currentRequest = plannedRequest
    let commands = coordinator.setRenderRequest(plannedRequest)
    for command in commands {
      send(command)
    }
  }

  public func updateConfiguration(_ configuration: YiTongBridgeConfigurationPayload) {
    guard let request = currentRequest else {
      return
    }

    currentRequest = YiTongRenderRequest(document: request.document, configuration: configuration)
    let commands = coordinator.updateConfiguration(configuration)
    for command in commands {
      send(command)
    }
  }

  public func teardown() {
    let commands = coordinator.terminate()
    for command in commands {
      send(command)
    }
  }

  private func handleReady(_ data: Data) {
    do {
      let envelope = try YiTongBridgeCodec.decode(
        YiTongBridgeIncomingEnvelope<YiTongReadyPayload>.self,
        from: data
      )
      log("Received ready(rendererVersion: \(envelope.payload.rendererVersion))")
      let result = try coordinator.handleReady(payload: envelope.payload, platform: platform)
      for command in result.0 {
        send(command)
      }
      if let event = result.1 {
        eventHandler?(event)
      }
    } catch {
      eventHandler?(.didFail(code: "bridge_decode_failed", message: error.localizedDescription))
    }
  }

  private func handleRenderStateChanged(_ data: Data) {
    do {
      let envelope = try YiTongBridgeCodec.decode(
        YiTongBridgeIncomingEnvelope<YiTongRenderStateChangedPayload>.self,
        from: data
      )
      log("Received renderStateChanged(state: \(envelope.payload.state.rawValue))")
      if let event = coordinator.handleRenderStateChanged(payload: envelope.payload) {
        eventHandler?(event)
      }
    } catch {
      eventHandler?(.didFail(code: "bridge_decode_failed", message: error.localizedDescription))
    }
  }

  private func handleLineActivated(_ data: Data) {
    do {
      let envelope = try YiTongBridgeCodec.decode(
        YiTongBridgeIncomingEnvelope<YiTongLineActivatedPayload>.self,
        from: data
      )
      eventHandler?(.didActivateLine(envelope.payload))
    } catch {
      eventHandler?(.didFail(code: "bridge_decode_failed", message: error.localizedDescription))
    }
  }

  private func handleSelectionChanged(_ data: Data) {
    do {
      let envelope = try YiTongBridgeCodec.decode(
        YiTongBridgeIncomingEnvelope<YiTongSelectionChangedPayload>.self,
        from: data
      )
      eventHandler?(.didChangeSelection(envelope.payload.selection))
    } catch {
      eventHandler?(.didFail(code: "bridge_decode_failed", message: error.localizedDescription))
    }
  }

  private func send(_ command: YiTongHostCommand) {
    let encodedData: Data

    do {
      switch command {
      case .initialize(let payload):
        encodedData = try YiTongBridgeCodec.encode(
          YiTongBridgeOutgoingEnvelope(
            id: nextID(),
            type: .initialize,
            payload: payload
          )
        )
      case .renderDocument(let payload):
        encodedData = try YiTongBridgeCodec.encode(
          YiTongBridgeOutgoingEnvelope(
            id: nextID(),
            type: .renderDocument,
            payload: payload
          )
        )
      case .updateConfiguration(let payload):
        encodedData = try YiTongBridgeCodec.encode(
          YiTongBridgeOutgoingEnvelope(
            id: nextID(),
            type: .updateConfiguration,
            payload: payload
          )
        )
      case .teardown(let payload):
        encodedData = try YiTongBridgeCodec.encode(
          YiTongBridgeOutgoingEnvelope(
            id: nextID(),
            type: .teardown,
            payload: payload
          )
        )
      }
    } catch {
      eventHandler?(.didFail(code: "bridge_encode_failed", message: error.localizedDescription))
      return
    }

    guard let jsonString = String(data: encodedData, encoding: .utf8) else {
      eventHandler?(.didFail(code: "bridge_encode_failed", message: "Unable to convert encoded message into UTF-8 string"))
      return
    }

    log("Sending command: \(command.logDescription)")
    webView.callAsyncJavaScript(
      "window.__yitongReceiveMessage(message)",
      arguments: ["message": jsonString],
      in: nil,
      in: .page
    ) { [weak self] result in
      if case .failure(let error) = result {
        self?.log("Failed to send command: \(error.localizedDescription)")
        self?.eventHandler?(.didFail(code: "bridge_send_failed", message: error.localizedDescription))
      }
    }
  }

  private func log(_ message: String) {
    guard diagnosticsEnabled else {
      return
    }
    print("[YiTongWebViewHost] \(message)")
  }

  private func plan(_ request: YiTongRenderRequest) -> YiTongRenderRequest? {
    switch YiTongRenderRequestPlanner.plan(request) {
    case .success(let plannedRequest, let diagnostic):
      if let diagnostic {
        log(diagnostic)
      }
      return plannedRequest
    case .failure(let failure):
      eventHandler?(.didFail(code: failure.code, message: failure.message))
      return nil
    }
  }

  private func logPageEnvironment() {
    guard diagnosticsEnabled else {
      return
    }

    webView.evaluateJavaScript(
      """
      ({
        href: window.location.href,
        readyState: document.readyState,
        hasReceiveMessage: typeof window.__yitongReceiveMessage,
        hasBridgeHandler: typeof window.webkit?.messageHandlers?.yitongBridge,
        appChildCount: document.querySelector('#app')?.childElementCount ?? -1
      })
      """
    ) { [weak self] result, error in
      if let error {
        self?.log("Page environment probe failed: \(error.localizedDescription)")
        return
      }

      self?.log("Page environment: \(String(describing: result))")
    }
  }

  private func nextID() -> String {
    nextMessageID += 1
    return "msg-\(nextMessageID)"
  }
}

extension YiTongWebViewHost: WKNavigationDelegate {
  public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
    log("didStartProvisionalNavigation")
    _ = webView
    _ = navigation
  }

  public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
    log("didCommitNavigation")
    _ = webView
    _ = navigation
  }

  public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    log("didFinishNavigation")
    coordinator.pageDidFinishNavigation()
    logPageEnvironment()
    _ = webView
    _ = navigation
  }

  public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) {
    log("Navigation failed: \(error.localizedDescription)")
    eventHandler?(.didFail(code: "navigation_failed", message: error.localizedDescription))
    _ = webView
    _ = navigation
  }

  public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: any Error) {
    log("Provisional navigation failed: \(error.localizedDescription)")
    eventHandler?(.didFail(code: "navigation_failed", message: error.localizedDescription))
    _ = webView
    _ = navigation
  }
}

extension YiTongWebViewHost: WKScriptMessageHandler {
  public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
    if diagnosticsEnabled, message.name == Constants.diagnosticMessageHandlerName {
      if let body = message.body as? String {
        log("JS diagnostic: \(body)")
      } else {
        log("JS diagnostic: \(String(describing: message.body))")
      }
      return
    }

    guard
      message.name == Constants.scriptMessageHandlerName,
      let body = message.body as? String,
      let data = body.data(using: .utf8)
    else {
      eventHandler?(.didFail(code: "bridge_decode_failed", message: "Unexpected script message body"))
      return
    }

    do {
      let message = try YiTongBridgeCodec.decode(YiTongBridgeMessage.self, from: data)
      switch message.type {
      case YiTongBridgeIncomingType.ready.rawValue:
        handleReady(data)
      case YiTongBridgeIncomingType.renderStateChanged.rawValue:
        handleRenderStateChanged(data)
      case YiTongBridgeIncomingType.lineActivated.rawValue:
        handleLineActivated(data)
      case YiTongBridgeIncomingType.selectionChanged.rawValue:
        handleSelectionChanged(data)
      default:
        break
      }
    } catch {
      eventHandler?(.didFail(code: "bridge_decode_failed", message: error.localizedDescription))
    }
    _ = userContentController
  }
}

private extension YiTongHostCommand {
  var logDescription: String {
    switch self {
    case .initialize:
      return "initialize"
    case .renderDocument(let payload):
      return "renderDocument(documentIdentifier: \(payload.document.identifier))"
    case .updateConfiguration:
      return "updateConfiguration"
    case .teardown:
      return "teardown"
    }
  }
}
