import Foundation
import YiTongBridge
import YiTongWebAssets

public struct YiTongRendererCoordinator: Equatable, Sendable {
  public private(set) var session: YiTongRendererSession
  public private(set) var request: YiTongRenderRequest?
  private var hasReceivedReady = false
  private var hasSentInitialize = false

  public init(session: YiTongRendererSession = YiTongRendererSession()) {
    self.session = session
  }

  public mutating func pageDidStartLoading() {
    session.state = .loadingPage
    hasReceivedReady = false
    hasSentInitialize = false
  }

  public mutating func pageDidFinishNavigation() {
    guard session.state == .loadingPage else {
      return
    }

    session.state = .waitingForReady
  }

  public mutating func setRenderRequest(_ request: YiTongRenderRequest) -> [YiTongHostCommand] {
    self.request = request

    guard hasReceivedReady else {
      return []
    }

    return [
      .renderDocument(
        YiTongRenderDocumentPayload(document: request.document, configuration: request.configuration)
      ),
    ]
  }

  public mutating func handleReady(
    payload: YiTongReadyPayload,
    platform: YiTongBridgePlatform
  ) throws -> ([YiTongHostCommand], YiTongHostEvent?) {
    hasReceivedReady = true
    session.state = .renderingDocument

    let manifest = try YiTongWebAssets.loadManifest()
    let initializePayload = YiTongInitializePayload(
      rendererVersion: manifest.rendererVersion,
      platform: platform,
      resolvedAppearance: request?.configuration.resolvedAppearance ?? .light,
      features: YiTongBridgeFeatureFlags(
        selection: request?.configuration.allowsSelection ?? true,
        workerMode: false
      )
    )

    var commands: [YiTongHostCommand] = []
    if !hasSentInitialize {
      hasSentInitialize = true
      commands.append(.initialize(initializePayload))
    }

    if let request {
      commands.append(
        .renderDocument(
          YiTongRenderDocumentPayload(document: request.document, configuration: request.configuration)
        )
      )
    }

    _ = payload
    return (commands, .didFinishInitialLoad)
  }

  public mutating func handleRenderStateChanged(
    payload: YiTongRenderStateChangedPayload
  ) -> YiTongHostEvent? {
    switch payload.state {
    case .loading:
      session.state = .renderingDocument
      return nil
    case .rendered:
      session.state = .rendered
      return .didRender(fileCount: payload.summary?.fileCount ?? 0)
    case .failed:
      session.state = .failed
      return .didFail(
        code: payload.error?.code ?? "render_failed",
        message: payload.error?.message ?? "Unknown render failure"
      )
    }
  }
}
