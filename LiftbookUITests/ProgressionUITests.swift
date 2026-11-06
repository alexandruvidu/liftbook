import XCTest

@MainActor
final class ProgressionUITests: XCTestCase {
    func testProgressionLight() { progression(appearance: "light") }
    func testProgressionDark() { progression(appearance: "dark") }

    private func progression(appearance: String) {
        continueAfterFailure = false
        // Seeded yesterday: bench press 3 × 8 at 62.5 kg
        let app = XCUIApplication.launchLiftbook(appearance: appearance, seedSampleData: true, seedHistory: true)
        let routine = app.buttons["routine.row.Upper Body"]
        XCTAssertTrue(routine.waitForExistence(timeout: 10), "Seeded routine missing")
        routine.tap()
        app.buttons["routine.start"].tap()
        XCTAssertTrue(app.buttons["live.finish"].waitForExistence(timeout: 10), "Live workout did not open")

        // 8–12 range: 8 reps last time → same weight, one more rep
        let suggestion = app.descendants(matching: .any)["live.exercise.0.suggestion"]
        XCTAssertTrue(suggestion.waitForExistence(timeout: 5), "No progression suggestion")
        XCTAssertTrue(suggestion.label.contains("62.5 kg × 9"), "Suggestion was \(suggestion.label)")

        // 5–8 range: 8 reps hits the top → add 2.5 kg
        let option = app.buttons["5–8 reps"]
        XCTAssertTrue(app.buttons["live.exercise.0.range"].openMenu(showing: option), "No rep range menu")
        option.tap()
        XCTAssertTrue(suggestion.label.contains("65 kg × 5"), "Suggestion after range change was \(suggestion.label)")
        snap("progression-\(appearance)")

        app.buttons["live.exercise.0.suggestion.apply"].tap()
        XCTAssertEqual(app.textFields["live.exercise.0.set.0.weight"].value as? String, "65")
        XCTAssertEqual(app.textFields["live.exercise.0.set.0.reps"].value as? String, "5")
    }
}
