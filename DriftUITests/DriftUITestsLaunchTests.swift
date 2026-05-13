//
//  DriftUITestsLaunchTests.swift
//  DriftUITests
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import XCTest

final class DriftUITestsLaunchTests: XCTestCase {

  override class var runsForEachTargetApplicationUIConfiguration: Bool {
    true
  }

  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  @MainActor
  func testLaunch() throws {
    let app = XCUIApplication()
    app.launch()

    XCTAssertTrue(app.staticTexts["Drift"].waitForExistence(timeout: 5))

    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = "Launch Screen"
    attachment.lifetime = .keepAlways
    add(attachment)
  }
}
