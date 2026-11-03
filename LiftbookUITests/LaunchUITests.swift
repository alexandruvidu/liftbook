import XCTest

@MainActor
final class LaunchUITests: XCTestCase {
    func testAppLaunches() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["root.title"].waitForExistence(timeout: 15))
        snap("launch")
    }
}
