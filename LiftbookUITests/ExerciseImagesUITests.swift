import XCTest

@MainActor
final class ExerciseImagesUITests: XCTestCase {
    func testExerciseImagesLight() { exerciseImages(appearance: "light") }
    func testExerciseImagesDark() { exerciseImages(appearance: "dark") }

    /// Opens the screen only: tests never download from the network.
    private func exerciseImages(appearance: String) {
        continueAfterFailure = false
        let app = XCUIApplication.launchLiftbook(appearance: appearance, seedMedia: true)
        app.openTab("Profile")
        let row = app.buttons["profile.images"]
        XCTAssertTrue(app.scrollTo(row), "No Exercise Images row")
        row.tap()
        XCTAssertTrue(app.buttons["images.download"].waitForExistence(timeout: 5), "No download button")
        XCTAssertFalse(app.buttons["images.remove"].exists, "Remove shown with nothing downloaded")
        snap("exercise-images-\(appearance)")

        // The library is a grid; bench press shows its photo
        app.openTab("Exercises")
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 10), "No search field")
        search.enter("press")
        XCTAssertTrue(app.buttons["exercise.row.barbell-bench-press"].waitForExistence(timeout: 5), "No bench press card")
        app.dismissKeyboardIfPresent()
        snap("exercise-grid-\(appearance)")
    }
}
