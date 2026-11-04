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

        app.buttons["workout.startEmpty"].tap()
        XCTAssertTrue(app.buttons["live.finish"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Add your first exercise to start logging sets."].exists)
        snap("live-workout-empty-\(appearance)")

        app.buttons["live.addExercises"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("plank")
        app.buttons["picker.row.plank"].tap()
        app.buttons["picker.add"].tap()
        XCTAssertTrue(app.staticTexts["Not logged"].waitForExistence(timeout: 5))

        // Minimize, then resume from the banner
        app.buttons["live.minimize"].tap()
        let resume = app.buttons["workout.resume"]
        XCTAssertTrue(resume.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["workout.startEmpty"].exists)
        snap("workout-resume-\(appearance)")
        resume.tap()

        // Discard
        let discard = app.buttons["live.discard"]
        XCTAssertTrue(discard.waitForExistence(timeout: 5))
        discard.tap()
        let confirm = app.buttons.matching(NSPredicate(format: "label == 'Discard Workout'"))
        XCTAssertTrue(confirm.element(boundBy: 1).waitForExistence(timeout: 5))
        confirm.element(boundBy: confirm.count - 1).tap()
        XCTAssertTrue(app.buttons["workout.startEmpty"].waitForExistence(timeout: 10))
    }

    private func workoutFromRoutine(appearance: String) {
        continueAfterFailure = false
        let app = XCUIApplication.launchLiftbook(appearance: appearance, seedSampleData: true)

        let routine = app.buttons["routine.row.Upper Body"]
        XCTAssertTrue(routine.waitForExistence(timeout: 10))
        routine.tap()
        XCTAssertTrue(app.buttons["routine.start"].waitForExistence(timeout: 5))
        snap("routine-detail-\(appearance)")
        app.buttons["routine.start"].tap()

        XCTAssertTrue(app.buttons["live.finish"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Bent-Over Barbell Row"].exists)
        // Rows below the fold may not be loaded yet, so only check the first exercise's sets.
        XCTAssertGreaterThanOrEqual(app.staticTexts.matching(NSPredicate(format: "label == 'Not logged'")).count, 3)
        snap("live-workout-routine-\(appearance)")

        // Starting again while one is running asks what to do
        app.buttons["live.minimize"].tap()
        XCTAssertTrue(app.buttons["routine.start"].waitForExistence(timeout: 5))
        app.buttons["routine.start"].tap()
        let alert = app.alerts["A workout is already in progress"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["Resume Current"].tap()

        // Finish ends it
        XCTAssertTrue(app.buttons["live.finish"].waitForExistence(timeout: 10))
        app.buttons["live.finish"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.buttons["workout.startEmpty"].waitForExistence(timeout: 10))
    }
}
