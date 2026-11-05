import XCTest

@MainActor
final class SetTypesUITests: XCTestCase {
    func testSetTypesLight() { setTypes(appearance: "light") }
    func testSetTypesDark() { setTypes(appearance: "dark") }

    private func choose(_ kind: String, forSet index: Int, in app: XCUIApplication, snapshot: String? = nil) {
        let menu = app.buttons["live.exercise.0.set.\(index).kind"]
        XCTAssertTrue(menu.waitForExistence(timeout: 5), "No set type menu for set \(index)")
        menu.tap()
        let option = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@ AND NOT (identifier BEGINSWITH 'live.')", kind)).firstMatch
        XCTAssertTrue(option.waitForExistence(timeout: 5), "No \(kind) option")
        if let snapshot { snap(snapshot) }
        option.tap()
    }

    private func setTypes(appearance: String) {
        continueAfterFailure = false
        let app = XCUIApplication.launchLiftbook(appearance: appearance, seedSampleData: true)

        let routine = app.buttons["routine.row.Upper Body"]
        XCTAssertTrue(routine.waitForExistence(timeout: 10), "Seeded routine missing")
        routine.tap()
        let start = app.buttons["routine.start"]
        XCTAssertTrue(start.waitForExistence(timeout: 5), "Routine detail did not open")
        start.tap()
        XCTAssertTrue(app.buttons["live.finish"].waitForExistence(timeout: 10), "Live workout did not open")

        choose("Warm-up", forSet: 0, in: app)
        choose("To Failure", forSet: 2, in: app, snapshot: "set-type-menu-\(appearance)")

        // Warm-ups show "W" and don't take a number; failure sets show "F"
        let first = app.buttons["live.exercise.0.set.0.kind"]
        XCTAssertEqual(first.label, "Warm-up: W")
        XCTAssertEqual(app.buttons["live.exercise.0.set.1.kind"].label, "Normal: 1")
        XCTAssertEqual(app.buttons["live.exercise.0.set.2.kind"].label, "To Failure: F")

        // Back to normal renumbers
        choose("Normal", forSet: 0, in: app)
        XCTAssertEqual(app.buttons["live.exercise.0.set.1.kind"].label, "Normal: 2")

        choose("Drop Set", forSet: 1, in: app)
        XCTAssertEqual(app.buttons["live.exercise.0.set.1.kind"].label, "Drop Set: D")
        snap("set-types-\(appearance)")
    }
}
