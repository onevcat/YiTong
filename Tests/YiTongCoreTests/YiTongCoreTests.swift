import XCTest
@testable import YiTongCore
@testable import YiTongBridge
@testable import YiTongWebAssets

final class YiTongCoreTests: XCTestCase {
  func testDiagnosticsAreDisabledByDefault() {
    XCTAssertFalse(YiTongDiagnostics.isEnabled(environment: [:]))
  }

  func testDiagnosticsRecognizeEnabledEnvironmentValues() {
    XCTAssertTrue(YiTongDiagnostics.isEnabled(environment: ["YITONG_DEBUG": "1"]))
    XCTAssertTrue(YiTongDiagnostics.isEnabled(environment: ["YITONG_DEBUG": "true"]))
    XCTAssertTrue(YiTongDiagnostics.isEnabled(environment: ["YITONG_DEBUG": " YES "]))
  }

  func testDiagnosticsIgnoreUnexpectedEnvironmentValues() {
    XCTAssertFalse(YiTongDiagnostics.isEnabled(environment: ["YITONG_DEBUG": "0"]))
    XCTAssertFalse(YiTongDiagnostics.isEnabled(environment: ["YITONG_DEBUG": "false"]))
    XCTAssertFalse(YiTongDiagnostics.isEnabled(environment: ["YITONG_DEBUG": "debug"]))
  }

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

  func testBundledIndexUsesRelativeAssetPaths() throws {
    let indexURL = try XCTUnwrap(YiTongWebAssets.resourceURL(for: "index", withExtension: "html"))
    let html = try String(contentsOf: indexURL, encoding: .utf8)

    XCTAssertFalse(html.contains("src=\"/renderer.js\""))
    XCTAssertFalse(html.contains("href=\"/renderer.css\""))
    XCTAssertFalse(html.contains("crossorigin"))
    XCTAssertFalse(html.contains("type=\"module\""))
    XCTAssertTrue(html.contains("src=\"./renderer.js\""))
    XCTAssertTrue(html.contains("href=\"./renderer.css\""))
  }

  func testCoordinatorQueuesRenderUntilReady() {
    var coordinator = YiTongRendererCoordinator()
    let request = YiTongRenderRequest(
      document: YiTongBridgeDocumentPayload(identifier: "document-1", title: "Example", patch: "diff --git a/a.txt b/a.txt"),
      configuration: YiTongBridgeConfigurationPayload(
        diffStyle: .split,
        showsLineNumbers: true,
        wrapsLines: false,
        showsFileHeaders: true,
        inlineChangeStyle: .wordAlt,
        allowsSelection: true,
        resolvedAppearance: .dark
      )
    )

    coordinator.pageDidStartLoading()
    coordinator.pageDidFinishNavigation()
    let commands = coordinator.setRenderRequest(request)

    XCTAssertEqual(coordinator.session.state, .waitingForReady)
    XCTAssertTrue(commands.isEmpty)
  }

  func testCoordinatorEmitsInitializeAndRenderAfterReady() throws {
    var coordinator = YiTongRendererCoordinator()
    let request = YiTongRenderRequest(
      document: YiTongBridgeDocumentPayload(identifier: "document-1", title: "Example", patch: "diff --git a/a.txt b/a.txt"),
      configuration: YiTongBridgeConfigurationPayload(
        diffStyle: .split,
        showsLineNumbers: true,
        wrapsLines: false,
        showsFileHeaders: true,
        inlineChangeStyle: .wordAlt,
        allowsSelection: true,
        resolvedAppearance: .dark
      )
    )

    coordinator.pageDidStartLoading()
    coordinator.pageDidFinishNavigation()
    _ = coordinator.setRenderRequest(request)
    let result = try coordinator.handleReady(
      payload: YiTongReadyPayload(rendererVersion: "0.1.0-placeholder"),
      platform: .macos
    )

    XCTAssertEqual(result.1, .didFinishInitialLoad)
    XCTAssertEqual(result.0.count, 2)
    XCTAssertEqual(coordinator.session.state, .renderingDocument)
  }

  func testDidFinishNavigationDoesNotRegressReadyState() throws {
    var coordinator = YiTongRendererCoordinator()
    let request = YiTongRenderRequest(
      document: YiTongBridgeDocumentPayload(identifier: "document-1", title: "Example", patch: "diff --git a/a.txt b/a.txt"),
      configuration: YiTongBridgeConfigurationPayload(
        diffStyle: .split,
        showsLineNumbers: true,
        wrapsLines: false,
        showsFileHeaders: true,
        inlineChangeStyle: .wordAlt,
        allowsSelection: true,
        resolvedAppearance: .dark
      )
    )

    coordinator.pageDidStartLoading()
    _ = coordinator.setRenderRequest(request)
    _ = try coordinator.handleReady(
      payload: YiTongReadyPayload(rendererVersion: "0.1.0-placeholder"),
      platform: .ios
    )
    coordinator.pageDidFinishNavigation()

    XCTAssertEqual(coordinator.session.state, .renderingDocument)
  }

  func testCoordinatorMapsRenderedStateToHostEvent() {
    var coordinator = YiTongRendererCoordinator()

    let event = coordinator.handleRenderStateChanged(
      payload: YiTongRenderStateChangedPayload(
        state: .rendered,
        documentIdentifier: "document-1",
        summary: YiTongRenderSummaryPayload(fileCount: 3)
      )
    )

    XCTAssertEqual(event, .didRender(fileCount: 3))
    XCTAssertEqual(coordinator.session.state, .rendered)
  }
}
