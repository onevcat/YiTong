import XCTest
import SwiftUI
@testable import YiTong

final class YiTongTests: XCTestCase {
  func testDefaultConfigurationMatchesDesignDefaults() {
    let configuration = DiffConfiguration.default

    XCTAssertEqual(configuration.appearance, .automatic)
    XCTAssertEqual(configuration.style, .split)
    XCTAssertEqual(configuration.inlineChangeStyle, .wordAlt)
    XCTAssertTrue(configuration.showsLineNumbers)
    XCTAssertTrue(configuration.showsFileHeaders)
    XCTAssertTrue(configuration.allowsSelection)
    XCTAssertFalse(configuration.wrapsLines)
  }

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
