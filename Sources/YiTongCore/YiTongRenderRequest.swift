import Foundation
import YiTongBridge

public struct YiTongRenderRequest: Equatable, Sendable {
  public var document: YiTongBridgeDocumentPayload
  public var configuration: YiTongBridgeConfigurationPayload

  public init(document: YiTongBridgeDocumentPayload, configuration: YiTongBridgeConfigurationPayload) {
    self.document = document
    self.configuration = configuration
  }
}
