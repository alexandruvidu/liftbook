import XCTest

@MainActor
final class WarmUpUITests: XCTestCase {
    func testWarmUpLight() { warmUp(appearance: "light") }
    func testWarmUpDark() { warmUp(appearance: "dark") }

    private func warmUp(appearance: String) {
        continueAfterFailure = false
        let app = XCUIApplication.launchLiftbook(appearance: appearance, seedSampleData: true)

        // Profile > Tools > Warm-up Calculator
        app.openTab("Profile")
        let tools = app.buttons["profile.tools"]
        XCTAssertTrue(tools.waitForExistence(timeout: 10), "No Tools tile")
        tools.tap()
        let link = app.buttons["profile.warmup"]
        XCTAssertTrue(app.scrollTo(link), "No warm-up calculator in Profile")
        link.tap()
        let working = app.textFields["warmup.working"]
        XCTAssertTrue(working.waitForExistence(timeout: 5), "Calculator did not open")
        working.enter("100")
        app.dismissKeyboard()
        let first = app.descendants(matching: .any)["warmup.step.0"]
        XCTAssertTrue(first.waitForExistence(timeout: 5), "No warm-up steps")
        XCTAssertTrue(first.label.contains("20 kg × 10"), "First step was \(first.label)")
        XCTAssertTrue(app.descendants(matching: .any)["warmup.step.3"].label.contains("80 kg × 2"))
        snap("warmup-calculator-\(appearance)")

        // In a workout: add warm-ups before the working sets
        app.openTab("Home")
        let routine = app.buttons["routine.row.Upper Body"]
        XCTAssertTrue(routine.waitForExistence(timeout: 10), "Seeded routine missing")
        routine.tap()
        app.buttons["routine.start"].tap()
        XCTAssertTrue(app.buttons["live.finish"].waitForExistence(timeout: 10), "Live workout did not open")
        app.textFields["live.exercise.0.set.0.weight"].enter("100")
        app.textFields["live.exercise.0.set.0.reps"].enter("5")
        app.dismissKeyboard()

        let option = app.buttons["Add Warm-up Sets"]
        XCTAssertTrue(app.buttons["live.exercise.0.options"].openMenu(showing: option), "No warm-up option")
        option.tap()
        let firstWeight = app.textFields["live.exercise.0.set.0.weight"]
        XCTAssertTrue(firstWeight.waitForExistence(timeout: 5))
        XCTAssertEqual(firstWeight.value as? String, "20", "First warm-up should be the bar")
        XCTAssertEqual(app.buttons["live.exercise.0.set.0.kind"].label, "Warm-up: W")
        snap("warmup-sets-\(appearance)")
        let firstWorking = app.buttons["live.exercise.0.set.4.kind"]
        app.scrollTo(firstWorking)
        XCTAssertEqual(firstWorking.label, "Normal: 1", "Working sets keep their numbers")
    }
}
