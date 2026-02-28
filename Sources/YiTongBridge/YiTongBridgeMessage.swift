import Foundation

public struct YiTongBridgeMessage: Codable, Equatable, Sendable {
  public var protocolVersion: Int
  public var id: String
  public var type: String

  private enum CodingKeys: String, CodingKey {
    case protocolVersion
    case id
    case type
  }

  public init(
    protocolVersion: Int = YiTongBridgeSchema.protocolVersion,
    id: String,
    type: String
  ) {
    self.protocolVersion = protocolVersion
    self.id = id
    self.type = type
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let protocolVersion = try container.decode(Int.self, forKey: .protocolVersion)
    guard protocolVersion == YiTongBridgeSchema.protocolVersion else {
      throw DecodingError.dataCorruptedError(
        forKey: .protocolVersion,
        in: container,
        debugDescription: "Unsupported protocol version \(protocolVersion)"
      )
    }

    self.protocolVersion = protocolVersion
    self.id = try container.decode(String.self, forKey: .id)
    self.type = try container.decode(String.self, forKey: .type)
  }
}
