import XCTest

@MainActor
final class ActivityUITests: XCTestCase {
    func testActivityLight() { activity(appearance: "light") }
    func testActivityDark() { activity(appearance: "dark") }

    private func activity(appearance: String) {
        continueAfterFailure = false
        // Seeded workouts 1, 2 and 9 days ago
        let app = XCUIApplication.launchLiftbook(appearance: appearance, seedHistory: true)
        app.openTab("Activity")

        XCTAssertTrue(app.descendants(matching: .any)["activity.week"].waitForExistence(timeout: 10), "No week block")
        XCTAssertTrue(app.staticTexts["goal.thisWeek"].exists, "No workouts-this-week count")
        for shortcut in ["exercises", "muscles", "records"] {
            XCTAssertTrue(app.buttons["activity.shortcut.\(shortcut)"].exists, "No \(shortcut) shortcut")
        }
        let cards = app.buttons.matching(identifier: "history.row")
        XCTAssertTrue(cards.firstMatch.waitForExistence(timeout: 5), "No workout cards")
        snap("activity-\(appearance)")

        // Records lists the best sets per exercise
        app.buttons["activity.shortcut.records"].tap()
        let record = app.descendants(matching: .any)["records.barbell-bench-press.heaviestWeight"]
        XCTAssertTrue(record.waitForExistence(timeout: 5), "No bench press record")
        XCTAssertTrue(record.label.contains("62.5"), "Bench record was \(record.label)")
        snap("activity-records-\(appearance)")
    }
}
