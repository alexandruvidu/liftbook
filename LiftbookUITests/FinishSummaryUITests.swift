import XCTest

@MainActor
final class FinishSummaryUITests: XCTestCase {
    func testFinishSummaryLight() { finishSummary(appearance: "light") }
    func testFinishSummaryDark() { finishSummary(appearance: "dark") }

    private func startRoutine(_ app: XCUIApplication) {
        let start = app.buttons["routine.start"]
        XCTAssertTrue(start.waitForExistence(timeout: 10), "Routine detail not showing")
        start.tap()
        XCTAssertTrue(app.buttons["live.finish"].waitForExistence(timeout: 10), "Live workout did not open")
    }

    private func logBenchSet(_ app: XCUIApplication, weight: String, reps: String) {
        app.textFields["live.exercise.0.set.0.weight"].enter(weight)
        app.textFields["live.exercise.0.set.0.reps"].enter(reps)
        app.dismissKeyboard()
        app.buttons["live.exercise.0.set.0.check"].tap()
    }

    private func finishSummary(appearance: String) {
        continueAfterFailure = false
        let app = XCUIApplication.launchLiftbook(appearance: appearance, seedSampleData: true)

        let routine = app.buttons["routine.row.Upper Body"]
        XCTAssertTrue(routine.waitForExistence(timeout: 10), "Seeded routine missing")
        routine.tap()

        // First workout: totals, no records yet
        startRoutine(app)
        logBenchSet(app, weight: "60", reps: "8")
        app.buttons["live.finish"].tap()
        let done = app.buttons["summary.done"]
        XCTAssertTrue(done.waitForExistence(timeout: 10), "No summary after Finish")
        XCTAssertTrue(app.descendants(matching: .any)["summary.volume"].label.contains("480 kg"), "Wrong volume")
        XCTAssertTrue(app.descendants(matching: .any)["summary.sets"].label.hasPrefix("1"), "Wrong set count")
        XCTAssertFalse(app.descendants(matching: .any)["summary.record.0"].exists, "Record on a first workout")
        done.tap()

        // Second workout beats the weight: new records
        startRoutine(app)
        logBenchSet(app, weight: "65", reps: "8")
        app.buttons["live.finish"].tap()
        XCTAssertTrue(done.waitForExistence(timeout: 10), "No summary after the second Finish")
        let record = app.descendants(matching: .any)["summary.record.0"]
        XCTAssertTrue(record.waitForExistence(timeout: 5), "No new record")
        XCTAssertTrue(record.label.contains("Heaviest weight"), "Record was \(record.label)")
        snap("finish-summary-\(appearance)")
        done.tap()

        // Back on the routine, with no workout in progress
        XCTAssertTrue(app.buttons["routine.start"].waitForExistence(timeout: 10), "Summary did not close")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.buttons["workout.startEmpty"].waitForExistence(timeout: 10), "Workout still in progress")
    }
}
