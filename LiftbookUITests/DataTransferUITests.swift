import XCTest

@MainActor
final class DataTransferUITests: XCTestCase {
    func testDataTransferLight() { dataTransfer(appearance: "light") }
    func testDataTransferDark() { dataTransfer(appearance: "dark") }

    private func dataTransfer(appearance: String) {
        continueAfterFailure = false
        let app = XCUIApplication.launchLiftbook(appearance: appearance, seedHistory: true)
        app.tabBars.buttons["Profile"].tap()
        let link = app.buttons["profile.data"]
        XCTAssertTrue(app.scrollTo(link), "No export & import link")
        link.tap()

        let count = app.descendants(matching: .any)["data.workoutCount"]
        XCTAssertTrue(count.waitForExistence(timeout: 5), "Data screen did not open")
        XCTAssertTrue(count.label.contains("3"), "Workout count was \(count.label)")
        XCTAssertTrue(app.buttons["data.exportCSV"].waitForExistence(timeout: 5), "No CSV export")
        XCTAssertTrue(app.buttons["data.exportJSON"].exists, "No JSON export")
        XCTAssertTrue(app.buttons["data.import"].exists, "No import")
        snap("data-transfer-\(appearance)")

    }
}
