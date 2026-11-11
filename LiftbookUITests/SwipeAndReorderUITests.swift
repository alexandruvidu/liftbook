import XCTest

/// Swipe actions and drag-to-reorder outside lists (iOS 27).
@MainActor
final class SwipeAndReorderUITests: XCTestCase {
    override func setUp() async throws {
        guard #available(iOS 27, *) else { throw XCTSkip("Needs iOS 27 swipe and reorder containers") }
    }

    func testSwipeToDeleteSetLight() { swipeToDeleteSet(appearance: "light") }
    func testSwipeToDeleteSetDark() { swipeToDeleteSet(appearance: "dark") }
    func testReorderExercises() { reorderExercises() }
    func testSwipeToDeleteWorkout() { swipeToDeleteWorkout() }

    /// Starts the seeded "Upper Body" routine: bench press, barbell row, overhead press.
    private func startRoutine(appearance: String) -> XCUIApplication {
        let app = XCUIApplication.launchLiftbook(appearance: appearance, seedSampleData: true)
        app.openTab("Start")
        let routine = app.buttons["quickStart.routine.Upper Body"]
        XCTAssertTrue(routine.waitForExistence(timeout: 5), "No routine in the start sheet")
        routine.tap()
        XCTAssertTrue(app.buttons["live.finish"].waitForExistence(timeout: 10), "Live workout did not open")
        return app
    }

    private func swipeToDeleteSet(appearance: String) {
        continueAfterFailure = false
        let app = startRoutine(appearance: appearance)
        let progress = app.buttons["live.exercise.0.collapse"]
        XCTAssertTrue(progress.label.contains("0 / 3 sets"), "Unexpected start: \(progress.label)")

        // Swipe from the middle of the row; once more if the first swipe was too short.
        let reps = app.textFields["live.exercise.0.set.1.reps"]
        let delete = app.buttons.matching(NSPredicate(
            format: "identifier == 'live.exercise.0.set.1.delete' OR label == 'Delete Set'")).firstMatch
        reps.swipeLeft()
        if !delete.waitForExistence(timeout: 3) { reps.swipeLeft() }
        XCTAssertTrue(delete.waitForExistence(timeout: 5), "Swiping a set showed no delete")
        snap("swipe-delete-set-\(appearance)")
        delete.tap()
        XCTAssertTrue(progress.label.contains("0 / 2 sets"), "Set not deleted: \(progress.label)")
    }

    private func reorderExercises() {
        continueAfterFailure = false
        let app = startRoutine(appearance: "light")
        // Fold all three so they fit on screen, then drag the last to the top.
        for index in 0..<3 { app.buttons["live.exercise.\(index).collapse"].tap() }
        let last = app.buttons["live.exercise.2.collapse"]
        XCTAssertTrue(last.label.contains("Overhead Press"), "Unexpected order: \(last.label)")
        let first = app.buttons["live.exercise.0.collapse"]
        last.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 1.2,
                   thenDragTo: first.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)))
        let moved = app.buttons["live.exercise.0.collapse"]
        XCTAssertTrue(moved.waitForExistence(timeout: 5))
        XCTAssertTrue(moved.label.contains("Overhead Press"), "Drag did not reorder: \(moved.label)")
        XCTAssertTrue(app.buttons["live.exercise.1.collapse"].label.contains("Bench Press"), "Others out of order")
    }

    private func swipeToDeleteWorkout() {
        continueAfterFailure = false
        let app = XCUIApplication.launchLiftbook(seedHistory: true)
        app.openTab("Activity")
        let rows = app.buttons.matching(identifier: "history.row")
        XCTAssertTrue(rows.firstMatch.waitForExistence(timeout: 10), "No history")
        let before = rows.count
        rows.firstMatch.swipeLeft()
        let delete = app.buttons.matching(NSPredicate(
            format: "identifier == 'history.delete.0' OR label == 'Delete'")).firstMatch
        XCTAssertTrue(delete.waitForExistence(timeout: 5), "Swiping a workout showed no delete")
        delete.tap()
        let confirm = app.buttons["history.confirmDelete"].firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), "Delete did not ask first")
        confirm.tap()
        let deleted = expectation(for: NSPredicate(format: "count == %d", before - 1), evaluatedWith: rows)
        wait(for: [deleted], timeout: 5)
    }
}
