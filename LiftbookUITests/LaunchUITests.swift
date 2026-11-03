import XCTest

@MainActor
final class LaunchUITests: XCTestCase {
    func testAppLaunchesOnWorkoutTab() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.navigationBars["Workout"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.tabBars.buttons["Workout"].isSelected)
    }
}
