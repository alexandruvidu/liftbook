import XCTest

@MainActor
final class PlateCalculatorUITests: XCTestCase {
    func testPlateCalculatorLight() { plateCalculator(appearance: "light") }
    func testPlateCalculatorDark() { plateCalculator(appearance: "dark") }

    private func plateCalculator(appearance: String) {
        continueAfterFailure = false
        let app = XCUIApplication.launchLiftbook(appearance: appearance, seedSampleData: true)

        // From Profile > Tools
        app.openTab("Profile")
        let link = app.buttons["profile.plates"]
        XCTAssertTrue(app.scrollTo(link), "No plate calculator in Profile")
        link.tap()
        let target = app.textFields["plates.target"]
        XCTAssertTrue(target.waitForExistence(timeout: 5), "Calculator did not open")
        target.enter("102.5")
        app.dismissKeyboard()
        let perSide = app.staticTexts["plates.perSide"]
        XCTAssertTrue(perSide.waitForExistence(timeout: 5), "No result")
        XCTAssertTrue(perSide.label.contains("25 kg, 15 kg, 1.25 kg"), "Per side was \(perSide.label)")
        snap("plate-calculator-\(appearance)")

        // Without 25 kg plates
        let toggle = app.switches["plates.toggle.25"]
        XCTAssertTrue(app.scrollTo(toggle), "No 25 kg toggle")
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        XCTAssertEqual(toggle.value as? String, "0", "25 kg plates still on")
        app.swipeDown()
        XCTAssertTrue(perSide.waitForExistence(timeout: 5), "Result gone")
        XCTAssertTrue(perSide.label.contains("20 kg, 20 kg, 1.25 kg"), "Per side without 25s was \(perSide.label)")

        // From a live workout, prefilled with the set's weight
        app.openTab("Home")
        let routine = app.buttons["routine.row.Upper Body"]
        XCTAssertTrue(routine.waitForExistence(timeout: 10), "Seeded routine missing")
        routine.tap()
        app.buttons["routine.start"].tap()
        XCTAssertTrue(app.buttons["live.finish"].waitForExistence(timeout: 10), "Live workout did not open")
        app.textFields["live.exercise.0.set.0.weight"].enter("60")
        app.dismissKeyboard()
        let option = app.buttons["Plate Calculator"]
        XCTAssertTrue(app.buttons["live.exercise.0.options"].openMenu(showing: option), "No plate calculator option")
        option.tap()
        XCTAssertTrue(target.waitForExistence(timeout: 5), "Calculator sheet did not open")
        XCTAssertEqual(target.value as? String, "60")
        XCTAssertTrue(perSide.label.contains("20 kg"), "Per side was \(perSide.label)")
        app.buttons["plates.done"].tap()
        XCTAssertTrue(target.waitForNonExistence(timeout: 5), "Sheet did not close")
    }
}
