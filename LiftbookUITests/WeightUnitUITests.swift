import XCTest

@MainActor
final class WeightUnitUITests: XCTestCase {
    func testPoundsLight() { pounds(appearance: "light") }
    func testPoundsDark() { pounds(appearance: "dark") }

    private func pounds(appearance: String) {
        continueAfterFailure = false
        let app = XCUIApplication.launchLiftbook(appearance: appearance, seedSampleData: true)

        // Switch to pounds in Profile
        app.openTab("Profile")
        let pounds = app.buttons["Pounds (lb)"]
        XCTAssertTrue(app.buttons["settings.unit"].openMenu(showing: pounds), "Unit picker did not open")
        pounds.tap()
        XCTAssertTrue(app.buttons["settings.unit"].label.contains("Pounds"), "Unit not saved")
        snap("settings-units-\(appearance)")

        // The live workout takes pounds and the summary shows them
        app.openTab("Home")
        let routine = app.buttons["routine.row.Upper Body"]
        XCTAssertTrue(routine.waitForExistence(timeout: 10), "Seeded routine missing")
        routine.tap()
        let start = app.buttons["routine.start"]
        XCTAssertTrue(start.waitForExistence(timeout: 5), "Routine detail did not open")
        start.tap()
        XCTAssertTrue(app.buttons["live.finish"].waitForExistence(timeout: 10), "Live workout did not open")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label ==[c] 'lb'")).firstMatch.exists,
                      "Column header is not in pounds")

        app.textFields["live.exercise.0.set.0.weight"].enter("135")
        app.textFields["live.exercise.0.set.0.reps"].enter("5")
        app.dismissKeyboard()
        app.buttons["live.exercise.0.set.0.check"].tap()
        snap("live-pounds-\(appearance)")

        app.buttons["live.finish"].tap()
        let volume = app.descendants(matching: .any)["summary.volume"]
        XCTAssertTrue(volume.waitForExistence(timeout: 10), "No summary")
        XCTAssertTrue(volume.label.contains("675 lb"), "Volume was \(volume.label)")
    }
}
