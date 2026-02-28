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
}
