import XCTest

@MainActor
final class PreviousPerformanceUITests: XCTestCase {
    func testPreviousPerformanceLight() { previousPerformance(appearance: "light") }
    func testPreviousPerformanceDark() { previousPerformance(appearance: "dark") }

    private func previousPerformance(appearance: String) {
        continueAfterFailure = false
        let app = XCUIApplication.launchLiftbook(appearance: appearance, seedSampleData: true)

        let routine = app.buttons["routine.row.Upper Body"]
        XCTAssertTrue(routine.waitForExistence(timeout: 10), "Seeded routine missing")
        routine.tap()
        let start = app.buttons["routine.start"]
        XCTAssertTrue(start.waitForExistence(timeout: 5), "Routine detail did not open")
        start.tap()

        // First workout: log one bench press set and finish
        let finish = app.buttons["live.finish"]
        XCTAssertTrue(finish.waitForExistence(timeout: 10), "Live workout did not open")
        XCTAssertFalse(app.buttons["live.exercise.0.set.0.previous"].exists, "Previous shown on the first workout")
        let weight = app.textFields["live.exercise.0.set.0.weight"]
        XCTAssertTrue(weight.waitForExistence(timeout: 5), "No weight field")
        weight.tap()
        weight.typeText("62.5")
        let reps = app.textFields["live.exercise.0.set.0.reps"]
        reps.tap()
        reps.typeText("6")
        app.buttons["live.keyboardDone"].tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 5), "Keyboard did not close")
        app.buttons["live.exercise.0.set.0.check"].tap()
        finish.tap()

        // Second workout shows what was done last time
        XCTAssertTrue(start.waitForExistence(timeout: 10), "Finish did not close the workout")
        start.tap()
        XCTAssertTrue(finish.waitForExistence(timeout: 10), "Second workout did not open")
        let previous = app.buttons["live.exercise.0.set.0.previous"]
        XCTAssertTrue(previous.waitForExistence(timeout: 5), "No previous performance")
        XCTAssertTrue(previous.label.contains("62.5 kg × 6"), "Previous was \(previous.label)")
        XCTAssertFalse(app.buttons["live.exercise.0.set.1.previous"].exists, "Unlogged set has a previous value")
        XCTAssertFalse(app.buttons["live.exercise.1.set.0.previous"].exists, "Other exercise has a previous value")

        // Tapping it copies the values into the set
        previous.tap()
        XCTAssertEqual(app.textFields["live.exercise.0.set.0.weight"].value as? String, "62.5")
        XCTAssertEqual(app.textFields["live.exercise.0.set.0.reps"].value as? String, "6")
        snap("previous-performance-\(appearance)")
    }
}
