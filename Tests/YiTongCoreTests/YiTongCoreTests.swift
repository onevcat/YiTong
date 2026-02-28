import XCTest
@testable import YiTongCore
@testable import YiTongWebAssets

final class YiTongCoreTests: XCTestCase {
  func testRendererSessionUsesCurrentProtocolVersion() {
    let session = YiTongRendererSession()

    XCTAssertEqual(session.protocolVersion, YiTongWebAssetsManifest(rendererVersion: "", protocolVersion: 1, files: []).protocolVersion)
    XCTAssertEqual(session.state, .idle)
  }

  func testBundledAssetsManifestLoads() throws {
    let manifest = try YiTongWebAssets.loadManifest()

    XCTAssertEqual(manifest.protocolVersion, 1)
    XCTAssertTrue(manifest.files.contains("index.html"))
    XCTAssertNotNil(YiTongWebAssets.resourceURL(for: "index", withExtension: "html"))
  }
}
