import Foundation

public struct YiTongBridgeMessage: Codable, Equatable, Sendable {
  public var protocolVersion: Int
  public var id: String
  public var type: String

  public init(
    protocolVersion: Int = YiTongBridgeSchema.protocolVersion,
    id: String,
    type: String
  ) {
    self.protocolVersion = protocolVersion
    self.id = id
    self.type = type
  }
}
