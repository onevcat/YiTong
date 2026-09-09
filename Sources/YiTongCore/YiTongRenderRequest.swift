import Foundation
import YiTongBridge

public struct YiTongRenderRequest: Equatable, Sendable {
  public var document: YiTongBridgeDocumentPayload
  public var configuration: YiTongBridgeConfigurationPayload
  public var annotations: [YiTongBridgeAnnotationPayload]

  public init(
    document: YiTongBridgeDocumentPayload,
    configuration: YiTongBridgeConfigurationPayload,
    annotations: [YiTongBridgeAnnotationPayload] = []
  ) {
    self.document = document
    self.configuration = configuration
    self.annotations = annotations
  }

  var renderDocumentPayload: YiTongRenderDocumentPayload {
    YiTongRenderDocumentPayload(document: document, configuration: configuration, annotations: annotations)
  }
}
