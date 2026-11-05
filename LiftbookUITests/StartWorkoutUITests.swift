import XCTest

@MainActor
final class StartWorkoutUITests: XCTestCase {
    func testEmptyWorkoutLight() { emptyWorkout(appearance: "light") }
    func testEmptyWorkoutDark() { emptyWorkout(appearance: "dark") }
    func testWorkoutFromRoutineLight() { workoutFromRoutine(appearance: "light") }
    func testWorkoutFromRoutineDark() { workoutFromRoutine(appearance: "dark") }

    /// LabeledContent merges "Set 1" and its value into one element.
    private func notLogged(in app: XCUIApplication) -> XCUIElementQuery {
        app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS 'Not logged'"))
    }

    private func emptyWorkout(appearance: String) {
        continueAfterFailure = false
        let app = XCUIApplication.launchLiftbook(appearance: appearance)

        app.buttons["workout.startEmpty"].tap()
        XCTAssertTrue(app.buttons["live.finish"].waitForExistence(timeout: 10), "Live workout did not open")
        XCTAssertTrue(app.staticTexts["Add your first exercise to start logging sets."].exists, "No empty hint")
        snap("live-workout-empty-\(appearance)")

        // Add an exercise (retry the tap once if the sheet is slow to appear)
        let search = app.searchFields.firstMatch
        app.buttons["live.addExercises"].tap()
        if !search.waitForExistence(timeout: 5) {
            app.buttons["live.addExercises"].tap()
        }
        XCTAssertTrue(search.waitForExistence(timeout: 10), "Exercise picker did not open")
        search.tap()
        search.typeText("plank")
        XCTAssertTrue(app.buttons["picker.row.plank"].waitForExistence(timeout: 5), "Plank not in picker")
        app.buttons["picker.row.plank"].tap()
        app.buttons["picker.add"].tap()
        XCTAssertTrue(notLogged(in: app).firstMatch.waitForExistence(timeout: 5), "Added exercise has no set")

        // Minimize, then resume from the banner
        app.buttons["live.minimize"].tap()
        let resume = app.buttons["workout.resume"]
        XCTAssertTrue(resume.waitForExistence(timeout: 5), "No resume banner after minimizing")
        XCTAssertFalse(app.buttons["workout.startEmpty"].exists, "Start button shown while a workout runs")
        snap("workout-resume-\(appearance)")
        resume.tap()

        // Discard (retry the tap once if the cover was still animating in)
        let discard = app.buttons["live.discard"]
        XCTAssertTrue(discard.waitForExistence(timeout: 10), "Live workout did not reopen")
        let confirm = app.buttons.matching(NSPredicate(
            format: "identifier == 'live.confirmDiscard' OR (label == 'Discard Workout' AND identifier != 'live.discard')"
        )).firstMatch
        discard.tap()
        if !confirm.waitForExistence(timeout: 4) {
            discard.tap()
        }
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), "No discard confirmation")
        confirm.tap()
        XCTAssertTrue(app.buttons["workout.startEmpty"].waitForExistence(timeout: 10), "Discard did not end the workout")
    }

    private func workoutFromRoutine(appearance: String) {
        continueAfterFailure = false
        let app = XCUIApplication.launchLiftbook(appearance: appearance, seedSampleData: true)

        let routine = app.buttons["routine.row.Upper Body"]
        XCTAssertTrue(routine.waitForExistence(timeout: 10), "Seeded routine missing")
        routine.tap()
        let start = app.buttons["routine.start"]
        XCTAssertTrue(start.waitForExistence(timeout: 5), "Routine detail did not open")
        snap("routine-detail-\(appearance)")
        start.tap()

        let finish = app.buttons["live.finish"]
        XCTAssertTrue(finish.waitForExistence(timeout: 10), "Live workout did not open from routine")
        XCTAssertTrue(app.staticTexts["Bent-Over Barbell Row"].exists, "Routine exercises not copied")
        XCTAssertTrue(notLogged(in: app).firstMatch.waitForExistence(timeout: 5), "No empty sets")
        XCTAssertGreaterThanOrEqual(notLogged(in: app).count, 3, "Bench press should have 3 sets")
        snap("live-workout-routine-\(appearance)")

        // Starting again while one is running asks what to do
        app.buttons["live.minimize"].tap()
        XCTAssertTrue(start.waitForExistence(timeout: 5), "Not back on routine detail after minimizing")
        start.tap()
        let alert = app.alerts["A workout is already in progress"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5), "No conflict alert")
        alert.buttons["Resume Current"].tap()

        // Finish ends it
        XCTAssertTrue(finish.waitForExistence(timeout: 10), "Resume Current did not reopen the workout")
        finish.tap()
        XCTAssertTrue(start.waitForExistence(timeout: 10), "Finish did not close the workout")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.buttons["workout.startEmpty"].waitForExistence(timeout: 10), "Workout still active after Finish")
    }
}
