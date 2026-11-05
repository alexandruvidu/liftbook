import XCTest

@MainActor
final class SupersetUITests: XCTestCase {
    func testSupersetLight() { superset(appearance: "light") }
    func testSupersetDark() { superset(appearance: "dark") }

    private func chooseOption(_ title: String, forExercise index: Int, in app: XCUIApplication) {
        let option = app.buttons[title]
        XCTAssertTrue(app.buttons["live.exercise.\(index).options"].openMenu(showing: option),
                      "No \"\(title)\" in exercise \(index) options")
        option.tap()
    }

    private func logFirstSet(ofExercise index: Int, weight: String, reps: String, in app: XCUIApplication) {
        let weightField = app.textFields["live.exercise.\(index).set.0.weight"]
        XCTAssertTrue(weightField.waitForExistence(timeout: 5), "No weight field for exercise \(index)")
        weightField.enter(weight)
        let repsField = app.textFields["live.exercise.\(index).set.0.reps"]
        repsField.enter(reps)
        app.dismissKeyboard()
        app.buttons["live.exercise.\(index).set.0.check"].tap()
    }

    private func superset(appearance: String) {
        continueAfterFailure = false
        let app = XCUIApplication.launchLiftbook(appearance: appearance, seedSampleData: true)

        let routine = app.buttons["routine.row.Upper Body"]
        XCTAssertTrue(routine.waitForExistence(timeout: 10), "Seeded routine missing")
        routine.tap()
        let start = app.buttons["routine.start"]
        XCTAssertTrue(start.waitForExistence(timeout: 5), "Routine detail did not open")
        start.tap()
        XCTAssertTrue(app.buttons["live.finish"].waitForExistence(timeout: 10), "Live workout did not open")

        // Link bench press with barbell row
        chooseOption("Superset with Next Exercise", forExercise: 0, in: app)
        XCTAssertTrue(app.descendants(matching: .any)["live.exercise.0.superset"].waitForExistence(timeout: 5), "No superset label")
        XCTAssertTrue(app.descendants(matching: .any)["live.exercise.1.superset"].exists, "Second exercise not in the superset")
        XCTAssertFalse(app.descendants(matching: .any)["live.exercise.2.superset"].exists, "Third exercise wrongly linked")

        // No rest between the exercises of a superset, only after the round
        logFirstSet(ofExercise: 0, weight: "60", reps: "8", in: app)
        XCTAssertFalse(app.staticTexts["rest.remaining"].waitForExistence(timeout: 2), "Rest started mid-superset")
        logFirstSet(ofExercise: 1, weight: "50", reps: "10", in: app)
        XCTAssertTrue(app.staticTexts["rest.remaining"].waitForExistence(timeout: 5), "No rest after the superset round")
        app.swipeDown()
        snap("superset-\(appearance)")
        app.buttons["rest.skip"].tap()

        // Unlink, then remove an exercise
        chooseOption("Unlink from Next Exercise", forExercise: 0, in: app)
        XCTAssertTrue(app.descendants(matching: .any)["live.exercise.0.superset"].waitForNonExistence(timeout: 5), "Superset not removed")

        chooseOption("Remove Exercise", forExercise: 2, in: app)
        XCTAssertTrue(app.buttons["live.exercise.2.addSet"].waitForNonExistence(timeout: 5), "Exercise not removed")
        XCTAssertTrue(app.buttons["live.exercise.1.addSet"].exists, "Other exercises disappeared")
    }
}
