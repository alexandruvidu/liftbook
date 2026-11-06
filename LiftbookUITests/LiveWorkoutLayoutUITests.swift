import XCTest

@MainActor
final class LiveWorkoutLayoutUITests: XCTestCase {
    func testLiveWorkoutLayoutLight() { layout(appearance: "light") }
    func testLiveWorkoutLayoutDark() { layout(appearance: "dark") }

    private func layout(appearance: String) {
        continueAfterFailure = false
        // Seeded Upper Body: bench press 62.5 kg × 8 yesterday
        let app = XCUIApplication.launchLiftbook(appearance: appearance, seedSampleData: true, seedHistory: true)
        let routine = app.buttons["routine.row.Upper Body"]
        XCTAssertTrue(routine.waitForExistence(timeout: 10), "Seeded routine missing")
        routine.tap()
        app.buttons["routine.start"].tap()
        XCTAssertTrue(app.buttons["live.finish"].waitForExistence(timeout: 10), "Live workout did not open")

        // Last time sits in its own column; the empty fields show it too
        let last = app.buttons["live.exercise.0.set.0.previous"]
        XCTAssertTrue(last.waitForExistence(timeout: 5), "No last-time column")
        XCTAssertTrue(last.label.contains("62.5 kg × 8"), "Last time was \(last.label)")
        XCTAssertEqual(app.textFields["live.exercise.0.set.0.weight"].placeholderValue, "62.5")

        // Done without typing logs last time's values
        let check = app.buttons["live.exercise.0.set.0.check"]
        check.tap()
        XCTAssertEqual(check.label, "Set 1 done", "Placeholder set not checked off")
        XCTAssertEqual(app.textFields["live.exercise.0.set.0.weight"].value as? String, "62.5")
        let sets = app.descendants(matching: .any)["live.stat.sets"]
        XCTAssertTrue(sets.label.contains("1 / 8"), "Sets tile was \(sets.label)")
        snap("live-workout-\(appearance)")

        // Collapsing hides the sets but keeps the header and its count
        let header = app.buttons["live.exercise.0.collapse"]
        header.tap()
        XCTAssertTrue(app.textFields["live.exercise.0.set.0.weight"].waitForNonExistence(timeout: 5), "Sets still shown")
        XCTAssertTrue(header.label.contains("1 / 3 sets"), "Header was \(header.label)")
        snap("live-collapsed-\(appearance)")
        header.tap()
        XCTAssertTrue(app.textFields["live.exercise.0.set.0.weight"].waitForExistence(timeout: 5), "Did not expand")
    }
}
