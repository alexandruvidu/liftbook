import XCTest

@MainActor
final class RoutineFromWorkoutUITests: XCTestCase {
    func testSaveWorkoutAsRoutineLight() { saveWorkoutAsRoutine(appearance: "light") }
    func testSaveWorkoutAsRoutineDark() { saveWorkoutAsRoutine(appearance: "dark") }
    func testExercisePageFromLiveWorkout() { exercisePageFromLiveWorkout() }

    private func saveWorkoutAsRoutine(appearance: String) {
        continueAfterFailure = false
        let app = XCUIApplication.launchLiftbook(appearance: appearance, seedHistory: true)
        app.openTab("Activity")
        let workout = app.buttons["history.row"].firstMatch
        XCTAssertTrue(workout.waitForExistence(timeout: 10), "No history")
        workout.tap()

        // An exercise in the workout opens its page
        let exercise = app.buttons["detail.exercise.0.page"]
        XCTAssertTrue(exercise.waitForExistence(timeout: 5), "Exercise isn't a link")
        let name = exercise.label.components(separatedBy: ",").first ?? ""
        exercise.tap()
        XCTAssertTrue(app.navigationBars[name].waitForExistence(timeout: 5), "Exercise page did not open for \(name)")
        app.navigationBars.buttons.firstMatch.tap()

        // Save it as a routine: the editor opens filled in, like a workout
        let save = app.buttons["detail.saveRoutine"]
        XCTAssertTrue(app.scrollTo(save), "No Save as Routine")
        save.tap()
        let routineName = app.textFields["routine.name"]
        XCTAssertTrue(routineName.waitForExistence(timeout: 5), "Routine editor did not open")
        XCTAssertEqual(routineName.value as? String, "Upper Body")
        let first = app.buttons["routine.entry.0.page"]
        XCTAssertTrue(first.label.contains(name), "First exercise is \(first.label)")
        XCTAssertTrue(app.buttons["routine.save"].isEnabled, "Copied routine can't be saved")

        // Sets: add one, then swipe one away
        let sets = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'routine.entry.0.set.'"))
        let before = sets.count
        app.buttons["routine.entry.0.addSet"].tap()
        XCTAssertEqual(sets.count, before + 1, "Add Set did nothing")
        snap("routine-from-workout-\(appearance)")
        if #available(iOS 27, *) {
            app.descendants(matching: .any)["routine.entry.0.set.0"].swipeLeft()
            let delete = app.buttons.matching(NSPredicate(
                format: "identifier == 'routine.entry.0.set.0.delete' OR label == 'Delete Set'")).firstMatch
            XCTAssertTrue(delete.waitForExistence(timeout: 5), "Swiping a planned set showed no delete")
            delete.tap()
            XCTAssertEqual(sets.count, before, "Set not deleted")
        }

        app.buttons["routine.save"].tap()
        app.openTab("Home")
        XCTAssertTrue(app.buttons["routine.row.Upper Body"].waitForExistence(timeout: 5), "Routine not saved")
    }

    private func exercisePageFromLiveWorkout() {
        continueAfterFailure = false
        let app = XCUIApplication.launchLiftbook(seedSampleData: true)
        app.openTab("Start")
        app.buttons["quickStart.routine.Upper Body"].tap()
        XCTAssertTrue(app.buttons["live.finish"].waitForExistence(timeout: 10), "Live workout did not open")

        app.buttons["live.exercise.2.options"].tap()
        let view = app.buttons["View Exercise"]
        XCTAssertTrue(view.waitForExistence(timeout: 5), "No View Exercise option")
        view.tap()
        XCTAssertTrue(app.navigationBars["Overhead Press"].waitForExistence(timeout: 5), "Exercise page did not open")
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.buttons["live.finish"].waitForExistence(timeout: 5), "Didn't return to the workout")

        // A lone set can't be swiped away: remove sets down to one, then try
        guard #available(iOS 27, *) else { return }
        let delete = app.buttons.matching(NSPredicate(format: "label == 'Delete Set'")).firstMatch
        for _ in 0..<2 {
            app.textFields["live.exercise.2.set.0.reps"].firstMatch.swipeLeft()
            if delete.waitForExistence(timeout: 3) { delete.tap() }
        }
        XCTAssertTrue(app.buttons["live.exercise.2.collapse"].label.contains("0 / 1 set"),
                      app.buttons["live.exercise.2.collapse"].label)
        app.textFields["live.exercise.2.set.0.reps"].swipeLeft()
        XCTAssertFalse(delete.waitForExistence(timeout: 2), "The only set could be swiped away")
    }
}
