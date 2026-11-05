import XCTest

@MainActor
final class CustomExerciseUITests: XCTestCase {
    func testCreateEditDeleteLight() { createEditDelete(appearance: "light") }
    func testCreateEditDeleteDark() { createEditDelete(appearance: "dark") }

    private func customRows(in app: XCUIApplication) -> XCUIElementQuery {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'exercise.row.custom-'"))
    }

    private func createEditDelete(appearance: String) {
        continueAfterFailure = false
        let app = XCUIApplication.launchLiftbook(appearance: appearance)
        app.tabBars.buttons["Exercises"].tap()

        // Create
        app.buttons["exercises.add"].tap()
        let name = app.textFields["editor.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.enter("Sandbag Carry")
        let save = app.buttons["editor.save"]
        XCTAssertFalse(save.isEnabled, "Save should need a primary muscle")

        app.buttons["editor.primary"].tap()
        XCTAssertTrue(app.buttons["muscle.forearms"].waitForExistence(timeout: 5))
        app.buttons["muscle.forearms"].tap()
        app.buttons["muscle.traps"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        XCTAssertTrue(save.isEnabled)
        snap("custom-exercise-editor-\(appearance)")
        save.tap()

        // Find it in the library
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.enter("sandbag")
        let row = customRows(in: app).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        snap("custom-exercise-list-\(appearance)")

        // Edit
        row.tap()
        XCTAssertTrue(app.navigationBars["Sandbag Carry"].waitForExistence(timeout: 5))
        app.buttons["exercise.edit"].tap()
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.enter(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 20) + "Heavy Sandbag Carry")
        save.tap()
        XCTAssertTrue(app.navigationBars["Heavy Sandbag Carry"].waitForExistence(timeout: 5))
        snap("custom-exercise-detail-\(appearance)")

        // Delete
        app.buttons["exercise.edit"].tap()
        let delete = app.buttons["editor.delete"]
        XCTAssertTrue(delete.waitForExistence(timeout: 5))
        delete.tap()
        confirmDelete(in: app)

        XCTAssertTrue(app.buttons["exercises.clearFilters"].waitForExistence(timeout: 10))
        XCTAssertEqual(customRows(in: app).count, 0)
    }

    /// Taps the destructive button in the confirmation dialog.
    private func confirmDelete(in app: XCUIApplication) {
        let byID = app.buttons["editor.confirmDelete"].firstMatch
        if byID.waitForExistence(timeout: 3) {
            byID.tap()
            return
        }
        // Fallback: the dialog's button is the last "Delete Exercise" on screen.
        let buttons = app.buttons.matching(NSPredicate(format: "label == 'Delete Exercise'"))
        XCTAssertGreaterThan(buttons.count, 1, "Confirmation dialog did not appear")
        buttons.element(boundBy: buttons.count - 1).tap()
    }
}
