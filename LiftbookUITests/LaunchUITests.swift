import XCTest

@MainActor
final class LaunchUITests: XCTestCase {
    func testAppLaunchesOnHomeTab() {
        continueAfterFailure = false
        let app = XCUIApplication.launchLiftbook()

        XCTAssertTrue(app.navigationBars["Home"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.tabBars.buttons["Home"].isSelected)
    }
}
