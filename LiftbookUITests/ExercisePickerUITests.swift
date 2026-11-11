import XCTest

@MainActor
final class ExercisePickerUITests: XCTestCase {
    func testRecentAndRemoveLight() { recentAndRemove(appearance: "light") }
    func testRecentAndRemoveDark() { recentAndRemove(appearance: "dark") }

    private func recentAndRemove(appearance: String) {
        continueAfterFailure = false
        let app = XCUIApplication.launchLiftbook(appearance: appearance, seedHistory: true)
        app.startEmptyWorkout()

        // The picker opens on exercises done lately, as photo cards
        let search = app.searchFields.firstMatch
        app.buttons["live.addExercises"].tap()
        if !search.waitForExistence(timeout: 5) { app.buttons["live.addExercises"].tap() }
        XCTAssertTrue(search.waitForExistence(timeout: 10), "Exercise picker did not open")
        let recent = app.buttons["picker.recent.barbell-bench-press"]
        XCTAssertTrue(recent.waitForExistence(timeout: 5), "Bench press not under Recent")
        XCTAssertTrue(app.buttons["exercises.filter.muscle"].exists, "No muscle filter in the picker")
        recent.tap()
        XCTAssertTrue(recent.isSelected, "Recent card not selected")
        snap("picker-recent-\(appearance)")
        app.buttons["picker.add"].tap()

        // Log a set, then removing the exercise asks first
        let weight = app.textFields["live.exercise.0.set.0.weight"]
        XCTAssertTrue(weight.waitForExistence(timeout: 5), "Bench press not added")
        weight.enter("60")
        app.textFields["live.exercise.0.set.0.reps"].enter("8")
        app.dismissKeyboard()
        app.buttons["live.exercise.0.set.0.check"].tap()
        app.buttons["live.exercise.0.options"].tap()
        let remove = app.buttons["Remove Exercise"]
        XCTAssertTrue(remove.waitForExistence(timeout: 5), "No remove option")
        remove.tap()
        let confirm = app.buttons["options.confirmRemove"].firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), "Removing logged sets did not ask first")
        confirm.tap()
        XCTAssertTrue(weight.waitForNonExistence(timeout: 5), "Exercise not removed")
    }
}
