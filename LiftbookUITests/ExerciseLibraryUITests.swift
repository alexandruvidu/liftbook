import XCTest

@MainActor
final class ExerciseLibraryUITests: XCTestCase {
    func testLibraryListAndDetailLight() {
        browseLibrary(appearance: "light")
    }

    func testLibraryListAndDetailDark() {
        browseLibrary(appearance: "dark")
    }

    private func browseLibrary(appearance: String) {
        continueAfterFailure = false
        let app = XCUIApplication.launchLiftbook(appearance: appearance)

        app.openTab("Exercises")
        XCTAssertTrue(app.navigationBars["Exercises"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.firstExerciseRow.waitForExistence(timeout: 5))
        snap("exercise-list-\(appearance)")

        // Thousands of exercises: search rather than scroll.
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.enter("barbell bench press")
        let row = app.buttons["exercise.row.barbell-bench-press"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()

        XCTAssertTrue(app.navigationBars["Barbell Bench Press"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["exercise.detail.description"].exists)
        snap("exercise-detail-\(appearance)")
    }
}
