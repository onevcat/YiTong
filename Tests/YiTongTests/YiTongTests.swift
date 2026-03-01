import XCTest
import SwiftUI
@testable import YiTong
@testable import YiTongBridge
@testable import YiTongCore

final class YiTongTests: XCTestCase {
  func testDefaultConfigurationMatchesDesignDefaults() {
    let configuration = DiffConfiguration.default

    XCTAssertEqual(configuration.appearance, .automatic)
    XCTAssertEqual(configuration.style, .split)
    XCTAssertEqual(configuration.indicators, .bars)
    XCTAssertEqual(configuration.inlineChangeStyle, .wordAlt)
    XCTAssertTrue(configuration.showsLineNumbers)
    XCTAssertTrue(configuration.showsChangeBackgrounds)
    XCTAssertTrue(configuration.showsFileHeaders)
    XCTAssertTrue(configuration.allowsSelection)
    XCTAssertFalse(configuration.wrapsLines)
  }

  func testConfigurationBuildsBridgePayload() {
    let configuration = DiffConfiguration(
      appearance: .dark,
      style: .unified,
      indicators: .classic,
      showsLineNumbers: false,
      showsChangeBackgrounds: false,
      wrapsLines: true,
      showsFileHeaders: false,
      inlineChangeStyle: .char,
      allowsSelection: false
    )

    let payload = YiTongPublicModelAdapter.makeBridgeConfiguration(
      from: configuration,
      resolvedAppearance: .dark
    )

    XCTAssertEqual(payload.diffStyle, .unified)
    XCTAssertEqual(payload.diffIndicators, .classic)
    XCTAssertFalse(payload.showsLineNumbers)
    XCTAssertFalse(payload.showsChangeBackgrounds)
    XCTAssertTrue(payload.wrapsLines)
    XCTAssertFalse(payload.showsFileHeaders)
    XCTAssertEqual(payload.inlineChangeStyle, .char)
    XCTAssertFalse(payload.allowsSelection)
    XCTAssertEqual(payload.resolvedAppearance, .dark)
  }

  func testRenderRequestBuildsDocumentAndConfigurationPayload() {
    let document = DiffDocument(
      patch: "diff --git a/Old.swift b/New.swift",
      title: "Example"
    )
    let configuration = DiffConfiguration(
      appearance: .light,
      style: .unified,
      indicators: .none,
      showsLineNumbers: false,
      showsChangeBackgrounds: false,
      wrapsLines: true,
      showsFileHeaders: false,
      inlineChangeStyle: .none,
      allowsSelection: false
    )

    let request = YiTongPublicModelAdapter.makeRenderRequest(
      documentIdentifier: "document-42",
      document: document,
      configuration: configuration,
      resolvedAppearance: .light
    )

    XCTAssertEqual(request.document.identifier, "document-42")
    XCTAssertEqual(request.document.title, "Example")
    XCTAssertEqual(request.document.patch, "diff --git a/Old.swift b/New.swift")
    XCTAssertEqual(request.configuration.diffStyle, .unified)
    XCTAssertEqual(request.configuration.diffIndicators, .none)
    XCTAssertFalse(request.configuration.showsLineNumbers)
    XCTAssertFalse(request.configuration.showsChangeBackgrounds)
    XCTAssertTrue(request.configuration.wrapsLines)
    XCTAssertFalse(request.configuration.showsFileHeaders)
    XCTAssertEqual(request.configuration.inlineChangeStyle, .none)
    XCTAssertFalse(request.configuration.allowsSelection)
    XCTAssertEqual(request.configuration.resolvedAppearance, .light)
  }

  func testHostLineActivatedMapsToPublicDiffEvent() {
    let event = YiTongPublicModelAdapter.makeDiffEvent(
      from: .didActivateLine(
        YiTongLineActivatedPayload(
          fileIndex: 2,
          oldPath: "a.swift",
          newPath: "b.swift",
          side: .new,
          number: 17,
          kind: .addition
        )
      )
    )

    XCTAssertEqual(
      event,
      .didClickLine(
        DiffLineReference(
          fileIndex: 2,
          oldPath: "a.swift",
          newPath: "b.swift",
          side: .new,
          number: 17,
          kind: .addition
        )
      )
    )
  }

  func testHostSelectionChangedMapsToPublicDiffEvent() {
    let event = YiTongPublicModelAdapter.makeDiffEvent(
      from: .didChangeSelection(
        YiTongSelectionPayload(
          fileIndex: 1,
          start: YiTongSelectionEndpointPayload(side: .old, number: 3),
          end: YiTongSelectionEndpointPayload(side: .new, number: 9)
        )
      )
    )

    XCTAssertEqual(
      event,
      .didChangeSelection(
        DiffSelection(
          fileIndex: 1,
          start: DiffSelectionEndpoint(side: .old, number: 3),
          end: DiffSelectionEndpoint(side: .new, number: 9)
        )
      )
    )
  }

  @MainActor
  func testDiffViewCanBeConstructed() {
    let document = DiffDocument(patch: "diff --git a/a.txt b/a.txt")
    let view = DiffView(document: document)

    XCTAssertNotNil(view)
  }

  @MainActor
  func testDiffViewControllerCanBeConstructed() {
    let controller = DiffViewController(document: DiffDocument(patch: "diff --git a/a.txt b/a.txt"))

    XCTAssertNotNil(controller)
  }

  @MainActor
  func testDiffViewControllerAcceptsDocumentAndConfigurationUpdatesBeforeViewLoads() {
    let controller = DiffViewController(document: DiffDocument(patch: "diff --git a/a.txt b/a.txt"))

    controller.update(
      document: DiffDocument(patch: "diff --git a/b.txt b/b.txt", title: "Updated"),
      configuration: DiffConfiguration(style: .unified, showsLineNumbers: false)
    )

    XCTAssertNotNil(controller)
  }
}
