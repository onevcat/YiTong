import Foundation

public enum YiTongBridgeOutgoingType: String, Codable, Sendable {
  case initialize
  case renderDocument
  case updateConfiguration
  case teardown
}

public enum YiTongBridgeIncomingType: String, Codable, Sendable {
  case ready
  case renderStateChanged
  case lineActivated
  case selectionChanged
}

public struct YiTongBridgeOutgoingEnvelope<Payload: Codable & Equatable & Sendable>: Codable, Equatable, Sendable {
  public var protocolVersion: Int
  public var id: String
  public var type: YiTongBridgeOutgoingType
  public var payload: Payload

  private enum CodingKeys: String, CodingKey {
    case protocolVersion
    case id
    case type
    case payload
  }

  public init(
    protocolVersion: Int = YiTongBridgeSchema.protocolVersion,
    id: String,
    type: YiTongBridgeOutgoingType,
    payload: Payload
  ) {
    self.protocolVersion = protocolVersion
    self.id = id
    self.type = type
    self.payload = payload
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
    self.type = try container.decode(YiTongBridgeOutgoingType.self, forKey: .type)
    self.payload = try container.decode(Payload.self, forKey: .payload)
  }
}

public struct YiTongBridgeIncomingEnvelope<Payload: Codable & Equatable & Sendable>: Codable, Equatable, Sendable {
  public var protocolVersion: Int
  public var id: String
  public var type: YiTongBridgeIncomingType
  public var payload: Payload

  private enum CodingKeys: String, CodingKey {
    case protocolVersion
    case id
    case type
    case payload
  }

  public init(
    protocolVersion: Int = YiTongBridgeSchema.protocolVersion,
    id: String,
    type: YiTongBridgeIncomingType,
    payload: Payload
  ) {
    self.protocolVersion = protocolVersion
    self.id = id
    self.type = type
    self.payload = payload
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
    self.type = try container.decode(YiTongBridgeIncomingType.self, forKey: .type)
    self.payload = try container.decode(Payload.self, forKey: .payload)
  }
}

public enum YiTongBridgePlatform: String, Codable, Equatable, Sendable {
  case ios
  case macos
}

public enum YiTongBridgeResolvedAppearance: String, Codable, Equatable, Sendable {
  case light
  case dark
}

public enum YiTongBridgeDiffStyle: String, Codable, Equatable, Sendable {
  case split
  case unified
}

public enum YiTongBridgeDiffIndicators: String, Codable, Equatable, Sendable {
  case bars
  case classic
  case none
}

public enum YiTongBridgeInlineChangeStyle: String, Codable, Equatable, Sendable {
  case wordAlt
  case word
  case char
  case none
}

public struct YiTongBridgeFeatureFlags: Codable, Equatable, Sendable {
  public var selection: Bool
  public var workerMode: Bool

  public init(selection: Bool, workerMode: Bool) {
    self.selection = selection
    self.workerMode = workerMode
  }
}

public struct YiTongInitializePayload: Codable, Equatable, Sendable {
  public var rendererVersion: String
  public var platform: YiTongBridgePlatform
  public var resolvedAppearance: YiTongBridgeResolvedAppearance
  public var features: YiTongBridgeFeatureFlags

  public init(
    rendererVersion: String,
    platform: YiTongBridgePlatform,
    resolvedAppearance: YiTongBridgeResolvedAppearance,
    features: YiTongBridgeFeatureFlags
  ) {
    self.rendererVersion = rendererVersion
    self.platform = platform
    self.resolvedAppearance = resolvedAppearance
    self.features = features
  }
}

public struct YiTongBridgeDocumentPayload: Codable, Equatable, Sendable {
  public var identifier: String
  public var title: String?
  public var patch: String

  public init(identifier: String, title: String?, patch: String) {
    self.identifier = identifier
    self.title = title
    self.patch = patch
  }
}

public struct YiTongBridgeConfigurationPayload: Codable, Equatable, Sendable {
  public var diffStyle: YiTongBridgeDiffStyle
  public var diffIndicators: YiTongBridgeDiffIndicators
  public var showsLineNumbers: Bool
  public var showsChangeBackgrounds: Bool
  public var wrapsLines: Bool
  public var showsFileHeaders: Bool
  public var inlineChangeStyle: YiTongBridgeInlineChangeStyle
  public var allowsSelection: Bool
  public var resolvedAppearance: YiTongBridgeResolvedAppearance

  public init(
    diffStyle: YiTongBridgeDiffStyle,
    diffIndicators: YiTongBridgeDiffIndicators,
    showsLineNumbers: Bool,
    showsChangeBackgrounds: Bool,
    wrapsLines: Bool,
    showsFileHeaders: Bool,
    inlineChangeStyle: YiTongBridgeInlineChangeStyle,
    allowsSelection: Bool,
    resolvedAppearance: YiTongBridgeResolvedAppearance
  ) {
    self.diffStyle = diffStyle
    self.diffIndicators = diffIndicators
    self.showsLineNumbers = showsLineNumbers
    self.showsChangeBackgrounds = showsChangeBackgrounds
    self.wrapsLines = wrapsLines
    self.showsFileHeaders = showsFileHeaders
    self.inlineChangeStyle = inlineChangeStyle
    self.allowsSelection = allowsSelection
    self.resolvedAppearance = resolvedAppearance
  }
}

public struct YiTongRenderDocumentPayload: Codable, Equatable, Sendable {
  public var document: YiTongBridgeDocumentPayload
  public var configuration: YiTongBridgeConfigurationPayload

  public init(document: YiTongBridgeDocumentPayload, configuration: YiTongBridgeConfigurationPayload) {
    self.document = document
    self.configuration = configuration
  }
}

public struct YiTongEmptyPayload: Codable, Equatable, Sendable {
  public init() {
  }
}

public struct YiTongReadyPayload: Codable, Equatable, Sendable {
  public var rendererVersion: String

  public init(rendererVersion: String) {
    self.rendererVersion = rendererVersion
  }
}

public enum YiTongBridgeLineSide: String, Codable, Equatable, Sendable {
  case old
  case new
  case unified
}

public enum YiTongBridgeLineKind: String, Codable, Equatable, Sendable {
  case context
  case addition
  case deletion
  case metadata
  case expanded
}

public struct YiTongLineActivatedPayload: Codable, Equatable, Sendable {
  public var fileIndex: Int
  public var oldPath: String?
  public var newPath: String?
  public var side: YiTongBridgeLineSide
  public var number: Int
  public var kind: YiTongBridgeLineKind

  public init(
    fileIndex: Int,
    oldPath: String? = nil,
    newPath: String? = nil,
    side: YiTongBridgeLineSide,
    number: Int,
    kind: YiTongBridgeLineKind
  ) {
    self.fileIndex = fileIndex
    self.oldPath = oldPath
    self.newPath = newPath
    self.side = side
    self.number = number
    self.kind = kind
  }
}

public struct YiTongSelectionEndpointPayload: Codable, Equatable, Sendable {
  public var side: YiTongBridgeLineSide
  public var number: Int

  public init(side: YiTongBridgeLineSide, number: Int) {
    self.side = side
    self.number = number
  }
}

public struct YiTongSelectionPayload: Codable, Equatable, Sendable {
  public var fileIndex: Int
  public var start: YiTongSelectionEndpointPayload
  public var end: YiTongSelectionEndpointPayload

  public init(fileIndex: Int, start: YiTongSelectionEndpointPayload, end: YiTongSelectionEndpointPayload) {
    self.fileIndex = fileIndex
    self.start = start
    self.end = end
  }
}

public struct YiTongSelectionChangedPayload: Codable, Equatable, Sendable {
  public var selection: YiTongSelectionPayload?

  public init(selection: YiTongSelectionPayload?) {
    self.selection = selection
  }
}

public enum YiTongRenderState: String, Codable, Equatable, Sendable {
  case loading
  case rendered
  case failed
}

public struct YiTongRenderSummaryPayload: Codable, Equatable, Sendable {
  public var fileCount: Int

  public init(fileCount: Int) {
    self.fileCount = fileCount
  }
}

public struct YiTongRenderErrorPayload: Codable, Equatable, Sendable {
  public var code: String
  public var message: String

  public init(code: String, message: String) {
    self.code = code
    self.message = message
  }
}

public struct YiTongRenderStateChangedPayload: Codable, Equatable, Sendable {
  public var state: YiTongRenderState
  public var documentIdentifier: String?
  public var summary: YiTongRenderSummaryPayload?
  public var error: YiTongRenderErrorPayload?

  public init(
    state: YiTongRenderState,
    documentIdentifier: String? = nil,
    summary: YiTongRenderSummaryPayload? = nil,
    error: YiTongRenderErrorPayload? = nil
  ) {
    self.state = state
    self.documentIdentifier = documentIdentifier
    self.summary = summary
    self.error = error
  }
}
