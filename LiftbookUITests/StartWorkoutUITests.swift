import XCTest

@MainActor
final class StartWorkoutUITests: XCTestCase {
    func testEmptyWorkoutLight() { emptyWorkout(appearance: "light") }
    func testEmptyWorkoutDark() { emptyWorkout(appearance: "dark") }
    func testWorkoutFromRoutineLight() { workoutFromRoutine(appearance: "light") }
    func testWorkoutFromRoutineDark() { workoutFromRoutine(appearance: "dark") }

    private func emptyWorkout(appearance: String) {
        continueAfterFailure = false
        let app = XCUIApplication.launchLiftbook(appearance: appearance)

        app.openTab("Start")
        XCTAssertTrue(app.buttons["quickStart.empty"].waitForExistence(timeout: 5), "Start sheet did not open")
        snap("quick-start-\(appearance)")
        app.buttons["quickStart.empty"].tap()
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
        search.enter("plank")
        XCTAssertTrue(app.buttons["picker.row.plank"].waitForExistence(timeout: 5), "Plank not in picker")
        app.buttons["picker.row.plank"].tap()
        app.buttons["picker.add"].tap()
        XCTAssertTrue(app.textFields["live.exercise.0.set.0.duration"].waitForExistence(timeout: 5), "Added exercise has no set")

        // Minimize, then resume from the running bar
        app.buttons["live.minimize"].tap()
        let resume = app.runningBar
        XCTAssertTrue(resume.waitForExistence(timeout: 5), "No running bar after minimizing")
        snap("workout-resume-\(appearance)")
        resume.tap()
        XCTAssertTrue(app.buttons["live.finish"].waitForExistence(timeout: 10), "Running bar did not open the workout")

        // The start button also reopens the running workout
        app.buttons["live.minimize"].tap()
        app.openTab("Start")

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
        XCTAssertTrue(app.runningBar.waitForNonExistence(timeout: 10), "Discard did not end the workout")
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
        XCTAssertTrue(app.buttons["live.exercise.1.collapse"].label.contains("Bent-Over Barbell Row"), "Routine exercises not copied")
        XCTAssertTrue(app.textFields["live.exercise.0.set.2.weight"].waitForExistence(timeout: 5), "Bench press should have 3 sets")
        XCTAssertFalse(app.textFields["live.exercise.0.set.3.weight"].exists, "Bench press has more than 3 sets")
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
        app.finishWorkout()
        XCTAssertTrue(start.waitForExistence(timeout: 10), "Finish did not close the workout")
        XCTAssertTrue(app.runningBar.waitForNonExistence(timeout: 10), "Workout still active after Finish")
    }
}
