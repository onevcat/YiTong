import XCTest
@testable import YiTongCore
@testable import YiTongBridge
@testable import YiTongWebAssets

final class YiTongCoreTests: XCTestCase {
  private func makeRequest(
    identifier: String = "document-1",
    appearance: YiTongBridgeResolvedAppearance = .dark,
    diffStyle: YiTongBridgeDiffStyle = .split
  ) -> YiTongRenderRequest {
    YiTongRenderRequest(
      document: YiTongBridgeDocumentPayload(
        identifier: identifier,
        title: "Example",
        patch: "diff --git a/a.txt b/a.txt"
      ),
      configuration: YiTongBridgeConfigurationPayload(
        diffStyle: diffStyle,
        diffIndicators: .bars,
        showsLineNumbers: true,
        showsChangeBackgrounds: true,
        wrapsLines: false,
        showsFileHeaders: true,
        inlineChangeStyle: .wordAlt,
        allowsSelection: true,
        resolvedAppearance: appearance
      )
    )
  }

  private func makeFileRequest(
    identifier: String = "document-files",
    patch: String? = "diff --git a/a.txt b/a.txt",
    files: [YiTongBridgeFilePayload]
  ) -> YiTongRenderRequest {
    YiTongRenderRequest(
      document: YiTongBridgeDocumentPayload(
        identifier: identifier,
        title: "Files",
        patch: patch,
        files: files
      ),
      configuration: YiTongBridgeConfigurationPayload(
        diffStyle: .split,
        diffIndicators: .bars,
        showsLineNumbers: true,
        showsChangeBackgrounds: true,
        wrapsLines: false,
        showsFileHeaders: true,
        inlineChangeStyle: .wordAlt,
        allowsSelection: true,
        resolvedAppearance: .dark
      )
    )
  }

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
    let request = makeRequest()

    coordinator.pageDidStartLoading()
    coordinator.pageDidFinishNavigation()
    let commands = coordinator.setRenderRequest(request)

    XCTAssertEqual(coordinator.session.state, .waitingForReady)
    XCTAssertTrue(commands.isEmpty)
  }

  func testCoordinatorEmitsInitializeAndRenderAfterReady() throws {
    var coordinator = YiTongRendererCoordinator()
    let request = makeRequest()

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

  func testRenderRequestPlannerKeepsFileModeWithinLimits() {
    let request = makeFileRequest(
      files: [
        YiTongBridgeFilePayload(
          oldPath: "Sources/Counter.swift",
          newPath: "Sources/Counter.swift",
          oldContents: String(repeating: "a", count: 128),
          newContents: String(repeating: "b", count: 128)
        ),
      ]
    )

    let result = YiTongRenderRequestPlanner.plan(request)

    switch result {
    case .success(let plannedRequest, let diagnostic):
      XCTAssertNil(diagnostic)
      XCTAssertEqual(plannedRequest.document.files?.count, 1)
      XCTAssertEqual(plannedRequest.document.patch, request.document.patch)
    case .failure(let error):
      XCTFail("Expected success, got failure: \(error)")
    }
  }

  func testRenderRequestPlannerFallsBackToPatchWhenSingleFileExceedsLimit() {
    let request = makeFileRequest(
      files: [
        YiTongBridgeFilePayload(
          oldPath: "Sources/Large.swift",
          newPath: "Sources/Large.swift",
          oldContents: String(repeating: "a", count: 2_100_000),
          newContents: String(repeating: "b", count: 2_100_000)
        ),
      ]
    )

    let result = YiTongRenderRequestPlanner.plan(request)

    switch result {
    case .success(let plannedRequest, let diagnostic):
      XCTAssertNotNil(diagnostic)
      XCTAssertNil(plannedRequest.document.files)
      XCTAssertEqual(plannedRequest.document.patch, request.document.patch)
    case .failure(let error):
      XCTFail("Expected fallback, got failure: \(error)")
    }
  }

  func testRenderRequestPlannerFailsWhenTotalSizeExceedsLimitWithoutPatchFallback() {
    let request = makeFileRequest(
      patch: nil,
      files: [
        YiTongBridgeFilePayload(
          oldPath: "Sources/A.swift",
          newPath: "Sources/A.swift",
          oldContents: String(repeating: "a", count: 5_500_000),
          newContents: String(repeating: "b", count: 5_500_000)
        ),
      ]
    )

    let result = YiTongRenderRequestPlanner.plan(request)

    switch result {
    case .success(let plannedRequest, _):
      XCTFail("Expected failure, got success: \(plannedRequest)")
    case .failure(let error):
      XCTAssertEqual(error.code, "document_too_large")
    }
  }

  func testDidFinishNavigationDoesNotRegressReadyState() throws {
    var coordinator = YiTongRendererCoordinator()
    let request = makeRequest()

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

  func testCoordinatorEmitsRenderImmediatelyWhenRequestChangesAfterReady() throws {
    var coordinator = YiTongRendererCoordinator()

    coordinator.pageDidStartLoading()
    coordinator.pageDidFinishNavigation()
    _ = try coordinator.handleReady(
      payload: YiTongReadyPayload(rendererVersion: "0.1.0-placeholder"),
      platform: .macos
    )

    let commands = coordinator.setRenderRequest(makeRequest(identifier: "document-2"))

    XCTAssertEqual(commands.count, 1)
    XCTAssertEqual(commands, [.renderDocument(YiTongRenderDocumentPayload(document: makeRequest(identifier: "document-2").document, configuration: makeRequest(identifier: "document-2").configuration))])
  }

  func testCoordinatorEmitsUpdateConfigurationAfterReady() throws {
    var coordinator = YiTongRendererCoordinator()
    let request = makeRequest()

    coordinator.pageDidStartLoading()
    coordinator.pageDidFinishNavigation()
    _ = coordinator.setRenderRequest(request)
    _ = try coordinator.handleReady(
      payload: YiTongReadyPayload(rendererVersion: "0.1.0-placeholder"),
      platform: .macos
    )

    let updatedConfiguration = YiTongBridgeConfigurationPayload(
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
    let commands = coordinator.updateConfiguration(updatedConfiguration)

    XCTAssertEqual(commands, [.updateConfiguration(updatedConfiguration)])
    XCTAssertEqual(coordinator.request?.configuration, updatedConfiguration)
  }

  func testCoordinatorUsesLatestQueuedConfigurationWhenReadyArrives() throws {
    var coordinator = YiTongRendererCoordinator()
    let initialRequest = makeRequest()
    let updatedConfiguration = YiTongBridgeConfigurationPayload(
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

    coordinator.pageDidStartLoading()
    coordinator.pageDidFinishNavigation()
    _ = coordinator.setRenderRequest(initialRequest)
    let queuedCommands = coordinator.updateConfiguration(updatedConfiguration)

    XCTAssertTrue(queuedCommands.isEmpty)

    let result = try coordinator.handleReady(
      payload: YiTongReadyPayload(rendererVersion: "0.1.0-placeholder"),
      platform: .macos
    )

    XCTAssertEqual(
      result.0.last,
      .renderDocument(
        YiTongRenderDocumentPayload(
          document: initialRequest.document,
          configuration: updatedConfiguration
        )
      )
    )
  }

  func testCoordinatorIgnoresRenderedStateForDifferentDocumentIdentifier() {
    var coordinator = YiTongRendererCoordinator()
    _ = coordinator.setRenderRequest(makeRequest(identifier: "document-current"))
    coordinator.pageDidStartLoading()
    coordinator.pageDidFinishNavigation()

    let event = coordinator.handleRenderStateChanged(
      payload: YiTongRenderStateChangedPayload(
        state: .rendered,
        documentIdentifier: "document-stale",
        summary: YiTongRenderSummaryPayload(fileCount: 99)
      )
    )

    XCTAssertNil(event)
    XCTAssertEqual(coordinator.session.state, .waitingForReady)
  }

  func testCoordinatorTerminatesAndIgnoresFurtherRenderStateChanges() {
    var coordinator = YiTongRendererCoordinator()
    _ = coordinator.setRenderRequest(makeRequest())

    let commands = coordinator.terminate()
    let event = coordinator.handleRenderStateChanged(
      payload: YiTongRenderStateChangedPayload(
        state: .rendered,
        documentIdentifier: "document-1",
        summary: YiTongRenderSummaryPayload(fileCount: 3)
      )
    )

    XCTAssertEqual(commands, [.teardown(YiTongEmptyPayload())])
    XCTAssertEqual(coordinator.session.state, .terminated)
    XCTAssertNil(event)
  }

  func testCoordinatorIgnoresDuplicateReadyAfterInitialization() throws {
    var coordinator = YiTongRendererCoordinator()
    let request = makeRequest()

    coordinator.pageDidStartLoading()
    coordinator.pageDidFinishNavigation()
    _ = coordinator.setRenderRequest(request)
    _ = try coordinator.handleReady(
      payload: YiTongReadyPayload(rendererVersion: "0.1.0-placeholder"),
      platform: .macos
    )

    let duplicateReady = try coordinator.handleReady(
      payload: YiTongReadyPayload(rendererVersion: "0.1.0-placeholder"),
      platform: .macos
    )

    XCTAssertTrue(duplicateReady.0.isEmpty)
    XCTAssertNil(duplicateReady.1)
    XCTAssertEqual(coordinator.session.state, .renderingDocument)
  }

  func testCoordinatorTerminateIsIdempotent() {
    var coordinator = YiTongRendererCoordinator()

    let first = coordinator.terminate()
    let second = coordinator.terminate()

    XCTAssertEqual(first, [.teardown(YiTongEmptyPayload())])
    XCTAssertTrue(second.isEmpty)
    XCTAssertEqual(coordinator.session.state, .terminated)
  }
}
