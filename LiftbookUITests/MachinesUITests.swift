import XCTest

@MainActor
final class MachinesUITests: XCTestCase {
    func testMachinesLight() { machines(appearance: "light") }
    func testMachinesDark() { machines(appearance: "dark") }

    private func machines(appearance: String) {
        continueAfterFailure = false
        // Bench press machines "Flat bench A", "Flat bench B", "Smith";
        // a workout on A two days ago at 50 kg × 10.
        let app = XCUIApplication.launchLiftbook(appearance: appearance, seedMachines: true)
        app.startEmptyWorkout()

        // Add bench press
        let search = app.searchFields.firstMatch
        app.buttons["live.addExercises"].tap()
        if !search.waitForExistence(timeout: 5) { app.buttons["live.addExercises"].tap() }
        XCTAssertTrue(search.waitForExistence(timeout: 10), "Exercise picker did not open")
        search.enter("bench press")
        let row = app.buttons["picker.row.barbell-bench-press"]
        XCTAssertTrue(row.waitForExistence(timeout: 5), "Bench press not in picker")
        row.tap()
        app.buttons["picker.add"].tap()

        // It asks which machine, with the one used last selected
        let cardA = app.buttons["machine.card.Flat bench A"]
        XCTAssertTrue(cardA.waitForExistence(timeout: 10), "Machine picker did not open")
        XCTAssertTrue(app.buttons["machine.card.Flat bench B"].exists)
        XCTAssertTrue(app.buttons["machine.card.Smith"].exists)
        XCTAssertTrue(cardA.isSelected, "Last-used machine not preselected")
        snap("machine-picker-\(appearance)")
        cardA.tap()

        // Last time comes from that machine
        let previous = app.buttons["live.exercise.0.set.0.previous"]
        XCTAssertTrue(previous.waitForExistence(timeout: 10), "No last time on machine A")
        XCTAssertTrue(previous.label.contains("50 kg × 10"), "Last time was \(previous.label)")
        let chip = app.buttons["live.exercise.0.machine"]
        XCTAssertTrue(chip.label.contains("Flat bench A"), "Chip was \(chip.label)")

        // A machine never used has no last time
        chip.tap()
        let smith = app.buttons["machine.card.Smith"]
        XCTAssertTrue(smith.waitForExistence(timeout: 5), "Picker did not reopen")
        smith.tap()
        XCTAssertTrue(previous.waitForNonExistence(timeout: 5), "Smith shows another machine's last time")
        XCTAssertTrue(chip.label.contains("Smith"), "Chip was \(chip.label)")
        snap("machine-chip-\(appearance)")
    }
}
