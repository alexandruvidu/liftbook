import XCTest

@MainActor
final class AppIconUITests: XCTestCase {
    /// Installs and launches the app, then goes to the home screen to capture its icon.
    func testAppIconOnHomeScreen() {
        continueAfterFailure = false
        let app = XCUIApplication.launchLiftbook()
        XCTAssertTrue(app.navigationBars["Home"].waitForExistence(timeout: 15))

        XCUIDevice.shared.press(.home)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let icon = springboard.icons["Liftbook"]
        XCTAssertTrue(icon.waitForExistence(timeout: 10), "Liftbook icon not on the home screen")

        // Newly installed apps can land on a later page; swipe until the icon is visible.
        var swipes = 0
        while !icon.isHittable && swipes < 4 {
            springboard.swipeLeft()
            swipes += 1
        }
        snap("app-icon")
    }
}
