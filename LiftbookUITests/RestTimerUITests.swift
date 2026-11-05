import XCTest

@MainActor
final class RestTimerUITests: XCTestCase {
    func testRestTimerLight() { restTimer(appearance: "light") }
    func testRestTimerDark() { restTimer(appearance: "dark") }

    /// Seconds shown on the rest timer ("1:58" → 118).
    private func remainingSeconds(_ app: XCUIApplication) -> Int {
        let parts = app.staticTexts["rest.remaining"].label.split(separator: ":").compactMap { Int($0) }
        return parts.count == 2 ? parts[0] * 60 + parts[1] : -1
    }

    private func restTimer(appearance: String) {
        continueAfterFailure = false
        let app = XCUIApplication.launchLiftbook(appearance: appearance, seedSampleData: true)

        // Default rest is set in Profile
        app.tabBars.buttons["Profile"].tap()
        let twoMinutes = app.buttons["2 min"]
        XCTAssertTrue(app.buttons["settings.restDefault"].openMenu(showing: twoMinutes), "Default rest picker did not open")
        twoMinutes.tap()
        XCTAssertTrue(app.buttons["settings.restDefault"].label.contains("2 min"), "Default rest not saved")
        snap("settings-rest-\(appearance)")

        app.tabBars.buttons["Workout"].tap()
        let routine = app.buttons["routine.row.Upper Body"]
        XCTAssertTrue(routine.waitForExistence(timeout: 10), "Seeded routine missing")
        routine.tap()
        let start = app.buttons["routine.start"]
        XCTAssertTrue(start.waitForExistence(timeout: 5), "Routine detail did not open")
        start.tap()
        XCTAssertTrue(app.buttons["live.finish"].waitForExistence(timeout: 10), "Live workout did not open")

        // Checking off a set starts the default rest
        let weight = app.textFields["live.exercise.0.set.0.weight"]
        XCTAssertTrue(weight.waitForExistence(timeout: 5), "No weight field")
        weight.tap()
        weight.typeText("60")
        let reps = app.textFields["live.exercise.0.set.0.reps"]
        reps.tap()
        reps.typeText("8")
        app.dismissKeyboard()
        let check = app.buttons["live.exercise.0.set.0.check"]
        check.tap()

        XCTAssertTrue(app.staticTexts["rest.remaining"].waitForExistence(timeout: 5), "Rest timer did not start")
        let first = remainingSeconds(app)
        XCTAssertTrue((100...120).contains(first), "Rest started at \(first)s, expected about 2 min")

        app.buttons["rest.plus"].tap()
        XCTAssertGreaterThan(remainingSeconds(app), first, "+15s did not add time")
        snap("rest-timer-\(appearance)")

        app.buttons["rest.skip"].tap()
        XCTAssertTrue(app.staticTexts["rest.remaining"].waitForNonExistence(timeout: 5), "Skip did not stop the timer")

        // Rest can be turned off for one exercise
        let off = app.buttons["Off"]
        XCTAssertTrue(app.buttons["live.exercise.0.rest"].openMenu(showing: off), "Rest menu did not open")
        off.tap()
        XCTAssertEqual(app.buttons["live.exercise.0.rest"].label, "Rest: Off")
        check.tap() // un-check
        check.tap() // check again
        XCTAssertEqual(check.label, "Set 1 done", "Set was not checked off again")
        XCTAssertFalse(app.staticTexts["rest.remaining"].waitForExistence(timeout: 2), "Timer started with rest off")
    }
}
