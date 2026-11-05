import XCTest

@MainActor
final class WeeklyGoalUITests: XCTestCase {
    func testWeeklyGoalLight() { weeklyGoal(appearance: "light") }
    func testWeeklyGoalDark() { weeklyGoal(appearance: "dark") }

    private func weeklyGoal(appearance: String) {
        continueAfterFailure = false
        // Seeded workouts 1, 2 and 9 days ago
        let app = XCUIApplication.launchLiftbook(appearance: appearance, seedHistory: true)

        // Lower the goal from 3 to 1 a week in Profile
        app.tabBars.buttons["Profile"].tap()
        let stepper = app.steppers["settings.goal"]
        XCTAssertTrue(stepper.waitForExistence(timeout: 10), "No weekly goal setting")
        stepper.buttons.element(boundBy: 0).tap()
        stepper.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(stepper.label.contains("1") || (stepper.value as? String ?? "").contains("1"),
                      "Goal not lowered: \(stepper.label)")

        // Yesterday's workout is in this or last week, so the streak is at least 1
        app.tabBars.buttons["Progress"].tap()
        let streak = app.staticTexts.matching(identifier: "goal.streak").firstMatch
        XCTAssertTrue(streak.waitForExistence(timeout: 10), "No streak on Progress")
        XCTAssertTrue(streak.label.contains("-week streak"), "Streak was \(streak.label)")
        XCTAssertTrue(app.staticTexts["goal.thisWeek"].exists, "No weekly progress")
        snap("weekly-goal-\(appearance)")
    }
}
