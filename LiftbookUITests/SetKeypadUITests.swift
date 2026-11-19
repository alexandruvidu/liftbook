import XCTest

/// The live workout's keypad for set values: digits, ± one step, Next to the
/// following field and Done.
@MainActor
final class SetKeypadUITests: XCTestCase {
    func testKeypadLight() { keypad(appearance: "light") }
    func testKeypadDark() { keypad(appearance: "dark") }

    private func keypad(appearance: String) {
        continueAfterFailure = false
        let app = XCUIApplication.launchLiftbook(appearance: appearance, seedSampleData: true)
        let routine = app.buttons["routine.row.Upper Body"]
        XCTAssertTrue(routine.waitForExistence(timeout: 10), "Seeded routine missing")
        routine.tap()
        app.buttons["routine.start"].tap()

        let weight = app.buttons["live.exercise.0.set.0.weight"]
        weight.enter("60")
        XCTAssertTrue(app.buttons["keypad.increase"].exists, "No keypad")
        snap("set-keypad-\(appearance)")
        app.buttons["keypad.increase"].tap()
        XCTAssertEqual(weight.value as? String, "62.5")

        app.buttons["keypad.next"].tap()
        let reps = app.buttons["live.exercise.0.set.0.reps"]
        XCTAssertTrue(reps.isSelected, "Next didn't move to reps")
        XCTAssertFalse(app.buttons["keypad.separator"].exists, "Reps have no decimal point")
        // The keypad stays its own size without the separator key.
        let keypadTop = app.buttons["keypad.key.1"].frame.minY
        XCTAssertGreaterThan(keypadTop, app.frame.height / 2, "The keypad grew to \(app.frame.height - keypadTop) pt")
        snap("set-keypad-reps-\(appearance)")
        reps.enter("8")
        XCTAssertEqual(reps.value as? String, "8")

        app.buttons["keyboard.done"].tap()
        XCTAssertTrue(app.buttons["keypad.key.0"].waitForNonExistence(timeout: 5), "Done didn't close the keypad")
        XCTAssertTrue(app.buttons["live.exercise.0.set.0.check"].isEnabled)
    }
}
