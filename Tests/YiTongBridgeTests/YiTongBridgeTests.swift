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
}
