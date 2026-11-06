import XCTest

@MainActor
final class WeeklyMusclesUITests: XCTestCase {
    func testWeeklyMusclesLight() { weeklyMuscles(appearance: "light") }
    func testWeeklyMusclesDark() { weeklyMuscles(appearance: "dark") }

    private func weeklyMuscles(appearance: String) {
        continueAfterFailure = false
        // Seeded workouts 1, 2 and 9 days ago
        let app = XCUIApplication.launchLiftbook(appearance: appearance, seedHistory: true)
        app.openTab("Activity")
        let muscles = app.buttons["activity.shortcut.muscles"]
        XCTAssertTrue(muscles.waitForExistence(timeout: 10), "No Muscles shortcut")
        muscles.tap()

        let title = app.staticTexts["weekly.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 10), "No weekly chart section")
        XCTAssertEqual(title.label, "This Week")
        XCTAssertFalse(app.buttons["weekly.next"].isEnabled, "Can move past this week")

        // Find a week with sets (yesterday may fall in last week)
        let chart = app.descendants(matching: .any)["weekly.chart"]
        if !chart.exists { app.buttons["weekly.previous"].tap() }
        XCTAssertTrue(chart.waitForExistence(timeout: 5), "No bars for the latest workout's week")
        snap("weekly-muscles-\(appearance)")

        app.segmentedControls.buttons["Volume"].tap()
        XCTAssertTrue(chart.exists, "Volume chart missing")

        // Far enough back there's nothing logged
        for _ in 0..<3 { app.buttons["weekly.previous"].tap() }
        XCTAssertTrue(app.descendants(matching: .any)["weekly.empty"].waitForExistence(timeout: 5), "No empty state")
        XCTAssertTrue(app.buttons["weekly.next"].isEnabled, "Can't move forward again")
    }
}
