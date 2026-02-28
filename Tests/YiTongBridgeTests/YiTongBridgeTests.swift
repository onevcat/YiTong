import XCTest
@testable import YiTongBridge

final class YiTongBridgeTests: XCTestCase {
  func testProtocolVersionIsOne() {
    XCTAssertEqual(YiTongBridgeSchema.protocolVersion, 1)
  }

  func testBridgeCodecRoundTripsStubMessage() throws {
    let message = YiTongBridgeMessage(id: "msg-1", type: "initialize")
    let data = try YiTongBridgeCodec.encode(message)
    let decoded = try YiTongBridgeCodec.decode(YiTongBridgeMessage.self, from: data)

    XCTAssertEqual(decoded, message)
  }

  func testInitializeEnvelopeRoundTrips() throws {
    let payload = YiTongInitializePayload(
      rendererVersion: "1.0.11+yitong.1",
      platform: .ios,
      resolvedAppearance: .dark,
      features: YiTongBridgeFeatureFlags(selection: true, workerMode: false)
    )
    let message = YiTongBridgeOutgoingEnvelope(
      id: "msg-1",
      type: .initialize,
      payload: payload
    )

    let data = try YiTongBridgeCodec.encode(message)
    let decoded = try YiTongBridgeCodec.decode(
      YiTongBridgeOutgoingEnvelope<YiTongInitializePayload>.self,
      from: data
    )

    XCTAssertEqual(decoded, message)
  }

  func testReadyEnvelopeDecodes() throws {
    let json = """
    {
      "protocolVersion": 1,
      "id": "evt-1",
      "type": "ready",
      "payload": {
        "rendererVersion": "0.1.0-placeholder"
      }
    }
    """

    let decoded = try YiTongBridgeCodec.decode(
      YiTongBridgeIncomingEnvelope<YiTongReadyPayload>.self,
      from: Data(json.utf8)
    )

    XCTAssertEqual(decoded.type, .ready)
    XCTAssertEqual(decoded.payload.rendererVersion, "0.1.0-placeholder")
  }

  func testProtocolVersionMismatchFailsDecoding() {
    let json = """
    {
      "protocolVersion": 999,
      "id": "evt-1",
      "type": "ready",
      "payload": {
        "rendererVersion": "0.1.0-placeholder"
      }
    }
    """

    XCTAssertThrowsError(
      try YiTongBridgeCodec.decode(
        YiTongBridgeIncomingEnvelope<YiTongReadyPayload>.self,
        from: Data(json.utf8)
      )
    )
  }

  func testUpdateConfigurationEnvelopeRoundTrips() throws {
    let payload = YiTongBridgeConfigurationPayload(
      diffStyle: .unified,
      diffIndicators: .classic,
      showsLineNumbers: false,
      showsChangeBackgrounds: false,
      wrapsLines: true,
      showsFileHeaders: false,
      inlineChangeStyle: .char,
      allowsSelection: false,
      resolvedAppearance: .light
    )
    let message = YiTongBridgeOutgoingEnvelope(
      id: "msg-2",
      type: .updateConfiguration,
      payload: payload
    )

    let data = try YiTongBridgeCodec.encode(message)
    let decoded = try YiTongBridgeCodec.decode(
      YiTongBridgeOutgoingEnvelope<YiTongBridgeConfigurationPayload>.self,
      from: data
    )

    XCTAssertEqual(decoded, message)
  }

  func testTeardownEnvelopeRoundTrips() throws {
    let message = YiTongBridgeOutgoingEnvelope(
      id: "msg-3",
      type: .teardown,
      payload: YiTongEmptyPayload()
    )

    let data = try YiTongBridgeCodec.encode(message)
    let decoded = try YiTongBridgeCodec.decode(
      YiTongBridgeOutgoingEnvelope<YiTongEmptyPayload>.self,
      from: data
    )

    XCTAssertEqual(decoded, message)
  }

  func testLineActivatedEnvelopeDecodes() throws {
    let json = """
    {
      "protocolVersion": 1,
      "id": "evt-3",
      "type": "lineActivated",
      "payload": {
        "fileIndex": 1,
        "oldPath": "Sources/Old.swift",
        "newPath": "Sources/New.swift",
        "side": "new",
        "number": 42,
        "kind": "addition"
      }
    }
    """

    let decoded = try YiTongBridgeCodec.decode(
      YiTongBridgeIncomingEnvelope<YiTongLineActivatedPayload>.self,
      from: Data(json.utf8)
    )

    XCTAssertEqual(decoded.type, .lineActivated)
    XCTAssertEqual(decoded.payload.fileIndex, 1)
    XCTAssertEqual(decoded.payload.side, .new)
    XCTAssertEqual(decoded.payload.kind, .addition)
  }

  func testSelectionChangedEnvelopeDecodesNilSelection() throws {
    let json = """
    {
      "protocolVersion": 1,
      "id": "evt-4",
      "type": "selectionChanged",
      "payload": {
        "selection": null
      }
    }
    """

    let decoded = try YiTongBridgeCodec.decode(
      YiTongBridgeIncomingEnvelope<YiTongSelectionChangedPayload>.self,
      from: Data(json.utf8)
    )

    XCTAssertEqual(decoded.type, .selectionChanged)
    XCTAssertNil(decoded.payload.selection)
  }
}
