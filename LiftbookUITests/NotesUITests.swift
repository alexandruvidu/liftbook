import XCTest

@MainActor
final class NotesUITests: XCTestCase {
    func testNotesLight() { notes(appearance: "light") }
    func testNotesDark() { notes(appearance: "dark") }

    /// Multi-line text fields can surface as text fields or text views.
    private func field(_ id: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    private func notes(appearance: String) {
        continueAfterFailure = false
        let app = XCUIApplication.launchLiftbook(appearance: appearance, seedSampleData: true)

        let routine = app.buttons["routine.row.Upper Body"]
        XCTAssertTrue(routine.waitForExistence(timeout: 10), "Seeded routine missing")
        routine.tap()
        let start = app.buttons["routine.start"]
        XCTAssertTrue(start.waitForExistence(timeout: 5), "Routine detail did not open")
        start.tap()
        let finish = app.buttons["live.finish"]
        XCTAssertTrue(finish.waitForExistence(timeout: 10), "Live workout did not open")

        let workoutNote = field("live.notes", in: app)
        XCTAssertTrue(workoutNote.waitForExistence(timeout: 5), "No workout notes field")
        workoutNote.enter("Slept well, felt strong")

        let exerciseNote = field("live.exercise.0.notes", in: app)
        XCTAssertTrue(exerciseNote.exists, "No exercise notes field")
        exerciseNote.enter("Wide grip, pause on chest")
        app.dismissKeyboard()

        XCTAssertEqual(workoutNote.value as? String, "Slept well, felt strong")
        XCTAssertEqual(exerciseNote.value as? String, "Wide grip, pause on chest")
        snap("notes-\(appearance)")

        // Next time, the exercise shows the last note as a hint
        finish.tap()
        XCTAssertTrue(start.waitForExistence(timeout: 10), "Finish did not close the workout")
        start.tap()
        XCTAssertTrue(finish.waitForExistence(timeout: 10), "Second workout did not open")
        let nextNote = field("live.exercise.0.notes", in: app)
        XCTAssertTrue(nextNote.waitForExistence(timeout: 5), "No exercise notes field")
        XCTAssertEqual(nextNote.placeholderValue, "Last note: Wide grip, pause on chest")
        XCTAssertEqual(field("live.exercise.1.notes", in: app).placeholderValue, "Exercise note")
    }
}
