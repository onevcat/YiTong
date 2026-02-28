import Foundation
import YiTongBridge

public struct YiTongRendererSession: Sendable, Equatable {
  public var id: UUID
  public var state: YiTongRendererState
  public var protocolVersion: Int

  public init(
    id: UUID = UUID(),
    state: YiTongRendererState = .idle,
    protocolVersion: Int = YiTongBridgeSchema.protocolVersion
  ) {
    self.id = id
    self.state = state
    self.protocolVersion = protocolVersion
  }
}
