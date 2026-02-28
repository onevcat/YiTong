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
}

public struct YiTongBridgeIncomingEnvelope<Payload: Codable & Equatable & Sendable>: Codable, Equatable, Sendable {
  public var protocolVersion: Int
  public var id: String
  public var type: YiTongBridgeIncomingType
  public var payload: Payload

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
  public var showsLineNumbers: Bool
  public var wrapsLines: Bool
  public var showsFileHeaders: Bool
  public var inlineChangeStyle: YiTongBridgeInlineChangeStyle
  public var allowsSelection: Bool
  public var resolvedAppearance: YiTongBridgeResolvedAppearance

  public init(
    diffStyle: YiTongBridgeDiffStyle,
    showsLineNumbers: Bool,
    wrapsLines: Bool,
    showsFileHeaders: Bool,
    inlineChangeStyle: YiTongBridgeInlineChangeStyle,
    allowsSelection: Bool,
    resolvedAppearance: YiTongBridgeResolvedAppearance
  ) {
    self.diffStyle = diffStyle
    self.showsLineNumbers = showsLineNumbers
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

public struct YiTongReadyPayload: Codable, Equatable, Sendable {
  public var rendererVersion: String

  public init(rendererVersion: String) {
    self.rendererVersion = rendererVersion
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
