import XCTest

@MainActor
final class HistoryUITests: XCTestCase {
    func testHistoryLight() { history(appearance: "light") }
    func testHistoryDark() { history(appearance: "dark") }

    /// The system calendar's label for a day `daysAgo` before today, e.g.
    /// "Thursday, November 5" (tests run in English, US).
    private func dayLabel(daysAgo: Int) -> String {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: -daysAgo, to: calendar.startOfDay(for: .now))!
        return date.formatted(Date.FormatStyle(locale: Locale(identifier: "en_US")).weekday(.wide).month(.wide).day())
    }

    private func history(appearance: String) {
        continueAfterFailure = false
        let app = XCUIApplication.launchLiftbook(appearance: appearance, seedHistory: true)

        app.openTab("Activity")
        let rows = app.buttons.matching(identifier: "history.row")
        XCTAssertTrue(rows.firstMatch.waitForExistence(timeout: 10), "No history rows")
        XCTAssertEqual(rows.count, 3, "Expected the three seeded workouts")
        XCTAssertTrue(rows.element(boundBy: 0).label.contains("Upper Body"), "Newest workout first")
        XCTAssertTrue(rows.element(boundBy: 0).label.contains("52:00"), "Duration missing")
        snap("history-list-\(appearance)")

        // Calendar: the system's, one button per day
        app.buttons["activity.calendar"].tap()
        let day = app.buttons.matching(NSPredicate(format: "label ENDSWITH %@", dayLabel(daysAgo: 9))).firstMatch
        if !day.waitForExistence(timeout: 3) {
            app.buttons["DatePicker.PreviousMonth"].tap()
        }
        XCTAssertTrue(day.waitForExistence(timeout: 5), "\(dayLabel(daysAgo: 9)) not in the calendar")
        day.tap()
        XCTAssertTrue(rows.firstMatch.waitForExistence(timeout: 5), "No workout listed for the day")
        XCTAssertEqual(rows.count, 1, "Only one workout on that day")
        XCTAssertTrue(rows.firstMatch.label.contains("Upper Body"))
        snap("history-calendar-\(appearance)")
    }
}
