import XCTest

@MainActor
final class ExerciseMediaUITests: XCTestCase {
    func testExerciseMediaLight() { exerciseMedia(appearance: "light") }
    func testExerciseMediaDark() { exerciseMedia(appearance: "dark") }

    private func exerciseMedia(appearance: String) {
        continueAfterFailure = false
        // Two photos of your own for bench press
        let app = XCUIApplication.launchLiftbook(appearance: appearance, seedMedia: true)
        app.openTab("Exercises")
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 10), "No search field")
        search.enter("bench press")
        let row = app.buttons["exercise.row.barbell-bench-press"]
        XCTAssertTrue(row.waitForExistence(timeout: 5), "Bench press not listed")
        row.tap()

        let gallery = app.descendants(matching: .any)["media.gallery"]
        XCTAssertTrue(gallery.waitForExistence(timeout: 10), "No photo gallery")
        XCTAssertTrue(app.pageIndicators.firstMatch.exists, "No page indicator for two photos")
        XCTAssertTrue(app.descendants(matching: .any)["media.add"].exists, "No add button")
        snap("exercise-media-\(appearance)")

        // The photo shows on the exercise in a workout
        app.startEmptyWorkout()
        app.buttons["live.addExercises"].tap()
        let pickerSearch = app.searchFields.firstMatch
        XCTAssertTrue(pickerSearch.waitForExistence(timeout: 10), "Exercise picker did not open")
        pickerSearch.enter("bench press")
        app.buttons["picker.row.barbell-bench-press"].tap()
        app.buttons["picker.add"].tap()
        // The thumbnail is decorative (hidden from VoiceOver): checked in the screenshot.
        XCTAssertTrue(app.buttons["live.exercise.0.collapse"].waitForExistence(timeout: 10), "Exercise not added")
        snap("exercise-thumbnail-\(appearance)")
    }
}
