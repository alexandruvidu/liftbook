import XCTest

@MainActor
final class LogSetsUITests: XCTestCase {
    func testLogSetsLight() { logSets(appearance: "light") }
    func testLogSetsDark() { logSets(appearance: "dark") }

    private func type(_ text: String, into field: XCUIElement) {
        XCTAssertTrue(field.waitForExistence(timeout: 5), "Missing field \(field)")
        field.tap()
        field.typeText(text)
    }

    private func logSets(appearance: String) {
        continueAfterFailure = false
        let app = XCUIApplication.launchLiftbook(appearance: appearance, seedSampleData: true)

        let routine = app.buttons["routine.row.Upper Body"]
        XCTAssertTrue(routine.waitForExistence(timeout: 10), "Seeded routine missing")
        routine.tap()
        let start = app.buttons["routine.start"]
        XCTAssertTrue(start.waitForExistence(timeout: 5), "Routine detail did not open")
        start.tap()
        XCTAssertTrue(app.buttons["live.finish"].waitForExistence(timeout: 10), "Live workout did not open")

        // An empty set can't be checked off
        let check = app.buttons["live.exercise.0.set.0.check"]
        XCTAssertTrue(check.waitForExistence(timeout: 5), "No check button")
        XCTAssertFalse(check.isEnabled, "Empty set can be checked off")

        // Log weight, reps and RPE, then check the set off
        type("60", into: app.textFields["live.exercise.0.set.0.weight"])
        type("8", into: app.textFields["live.exercise.0.set.0.reps"])
        app.dismissKeyboard()

        let rpe = app.buttons["RPE 8"]
        XCTAssertTrue(app.buttons["live.exercise.0.set.0.rpe"].openMenu(showing: rpe), "RPE menu did not open")
        rpe.tap()
        XCTAssertEqual(app.buttons["live.exercise.0.set.0.rpe"].label, "RPE 8")

        XCTAssertTrue(check.isEnabled, "Logged set can't be checked off")
        check.tap()
        XCTAssertEqual(check.label, "Set 1 done", "Set was not checked off")
        let progress = app.staticTexts.matching(NSPredicate(format: "label ==[c] '1/3 done'"))
        XCTAssertTrue(progress.firstMatch.exists, "Progress not updated")

        // Add Set copies the latest logged values
        app.buttons["live.exercise.0.addSet"].tap()
        let newWeight = app.textFields["live.exercise.0.set.3.weight"]
        XCTAssertTrue(newWeight.waitForExistence(timeout: 5), "Add Set did not add a row")
        XCTAssertEqual(newWeight.value as? String, "60", "New set did not copy the weight")

        snap("live-logging-\(appearance)")
    }
}
