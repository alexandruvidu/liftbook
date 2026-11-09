import XCTest

@MainActor
final class ExerciseSearchUITests: XCTestCase {
    func testSearchLight() { search(appearance: "light") }
    func testSearchDark() { search(appearance: "dark") }
    func testFiltersLight() { filter(appearance: "light") }
    func testFiltersDark() { filter(appearance: "dark") }

    private func openExercises(appearance: String) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication.launchLiftbook(appearance: appearance)
        app.openTab("Exercises")
        XCTAssertTrue(app.firstExerciseRow.waitForExistence(timeout: 10))
        return app
    }

    private func search(appearance: String) {
        let app = openExercises(appearance: appearance)

        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.enter("barbell curl")

        XCTAssertTrue(app.buttons["exercise.row.barbell-curl"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.firstExerciseRow.label.localizedCaseInsensitiveContains("curl"))
        snap("exercise-search-\(appearance)")
    }

    private func filter(appearance: String) {
        let app = openExercises(appearance: appearance)
        let count = app.staticTexts["exercises.resultCount"]

        choose("Chest", in: "exercises.filter.muscle", app: app)
        choose("Machine", in: "exercises.filter.equipment", app: app)
        // Every result is a chest machine; the label reads "<name>, Chest · Machine".
        let first = app.firstExerciseRow
        XCTAssertTrue(first.waitForExistence(timeout: 5))
        XCTAssertTrue(first.label.hasSuffix("· Machine"), first.label)
        XCTAssertTrue(first.label.contains("Chest"), first.label)
        XCTAssertTrue(count.label.hasSuffix("exercises"), count.label)
        snap("exercise-filter-\(appearance)")

        choose("Trap Bar", in: "exercises.filter.equipment", app: app)
        let clear = app.buttons["exercises.clearFilters"]
        XCTAssertTrue(clear.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["No matching exercises"].exists)
        snap("exercise-filter-empty-\(appearance)")

        clear.tap()
        XCTAssertTrue(app.firstExerciseRow.waitForExistence(timeout: 5))
    }

    private func choose(_ option: String, in menuID: String, app: XCUIApplication) {
        app.buttons[menuID].tap()
        let item = app.buttons[option].firstMatch
        XCTAssertTrue(item.waitForExistence(timeout: 5), "Menu option \(option) not found")
        item.tap()
    }
}
