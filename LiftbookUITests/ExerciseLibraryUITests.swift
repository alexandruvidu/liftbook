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
        XCTAssertTrue(app.buttons["exercise.row.ab-wheel-rollout"].waitForExistence(timeout: 5))
        let list = app.collectionViews.firstMatch
        snap("exercise-list-\(appearance)")

        let row = app.buttons["exercise.row.barbell-bench-press"]
        var swipes = 0
        while !row.isHittable && swipes < 10 {
            list.swipeUp()
            swipes += 1
        }
        row.tap()

        XCTAssertTrue(app.navigationBars["Barbell Bench Press"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["exercise.detail.description"].exists)
        snap("exercise-detail-\(appearance)")
    }
}
