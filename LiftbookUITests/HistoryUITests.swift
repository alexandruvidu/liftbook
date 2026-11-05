import XCTest

@MainActor
final class HistoryUITests: XCTestCase {
    func testHistoryLight() { history(appearance: "light") }
    func testHistoryDark() { history(appearance: "dark") }

    /// "2026-11-05" for a day `daysAgo` before today, matching the app's IDs.
    private func dayID(daysAgo: Int) -> (id: String, date: Date) {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: -daysAgo, to: calendar.startOfDay(for: .now))!
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return (String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!), date)
    }

    private func history(appearance: String) {
        continueAfterFailure = false
        let app = XCUIApplication.launchLiftbook(appearance: appearance, seedHistory: true)

        app.tabBars.buttons["History"].tap()
        let rows = app.descendants(matching: .any).matching(identifier: "history.row")
        XCTAssertTrue(rows.firstMatch.waitForExistence(timeout: 10), "No history rows")
        XCTAssertEqual(rows.count, 3, "Expected the three seeded workouts")
        XCTAssertTrue(rows.element(boundBy: 0).label.contains("Upper Body"), "Newest workout first")
        XCTAssertTrue(rows.element(boundBy: 0).label.contains("52:00"), "Duration missing")
        snap("history-list-\(appearance)")

        // Calendar: the newest workout's day is selected
        app.segmentedControls.buttons["Calendar"].tap()
        let target = dayID(daysAgo: 9)
        let day = app.buttons["calendar.day.\(target.id)"]
        if !day.waitForExistence(timeout: 3) {
            app.buttons["calendar.previous"].tap()
        }
        XCTAssertTrue(day.waitForExistence(timeout: 5), "Day \(target.id) not in the calendar")
        XCTAssertTrue(day.label.contains("workout logged"), "No workout marker on \(target.id)")
        day.tap()
        XCTAssertTrue(rows.firstMatch.waitForExistence(timeout: 5), "No workout listed for the day")
        XCTAssertEqual(rows.count, 1, "Only one workout on that day")
        XCTAssertTrue(rows.firstMatch.label.contains("Upper Body"))
        snap("history-calendar-\(appearance)")
    }
}
