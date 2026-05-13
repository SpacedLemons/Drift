//
//  DriftUITests.swift
//  DriftUITests
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import XCTest

final class DriftUITests: XCTestCase {

  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  @MainActor
  func testLaunchShowsJournalHome() throws {
    let app = XCUIApplication()
    app.launch()

    XCTAssertTrue(app.staticTexts["Drift"].waitForExistence(timeout: 5))
  }

  @MainActor
  func testMainTabsAreReachable() throws {
    let app = XCUIApplication()
    app.launch()

    XCTAssertTrue(app.tabBars.buttons["Journal"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.tabBars.buttons["Insights"].exists)
    XCTAssertTrue(app.tabBars.buttons["Settings"].exists)
  }

  @MainActor
  func testLaunchPerformance() throws {
    measure(metrics: [XCTApplicationLaunchMetric()]) {
      XCUIApplication().launch()
    }
  }
}
