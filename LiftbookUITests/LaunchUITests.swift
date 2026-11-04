import XCTest

@MainActor
final class LaunchUITests: XCTestCase {
    func testAppLaunchesOnWorkoutTab() {
        continueAfterFailure = false
        let app = XCUIApplication.launchLiftbook()

        XCTAssertTrue(app.navigationBars["Workout"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.tabBars.buttons["Workout"].isSelected)
    }
}
