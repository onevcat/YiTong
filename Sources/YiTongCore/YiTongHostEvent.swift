import Foundation
import YiTongBridge

public enum YiTongHostEvent: Equatable, Sendable {
  case didFinishInitialLoad
  case didRender(fileCount: Int)
  case didActivateLine(YiTongLineActivatedPayload)
  case didChangeSelection(YiTongSelectionPayload?)
  case didFail(code: String, message: String)
}

public enum YiTongHostCommand: Equatable, Sendable {
  case initialize(YiTongInitializePayload)
  case renderDocument(YiTongRenderDocumentPayload)
  case updateConfiguration(YiTongBridgeConfigurationPayload)
  case teardown(YiTongEmptyPayload)
}
