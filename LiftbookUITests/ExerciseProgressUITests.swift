import XCTest

@MainActor
final class ExerciseProgressUITests: XCTestCase {
    func testExerciseProgressLight() { exerciseProgress(appearance: "light") }
    func testExerciseProgressDark() { exerciseProgress(appearance: "dark") }

    private func exerciseProgress(appearance: String) {
        continueAfterFailure = false
        // Seeded bench press: 60 kg × 8 nine days ago, 62.5 kg × 8 yesterday
        let app = XCUIApplication.launchLiftbook(appearance: appearance, seedHistory: true)
        app.tabBars.buttons["Progress"].tap()

        // The exercise list sits below the weekly goal and muscle chart
        XCTAssertTrue(app.staticTexts["weekly.title"].waitForExistence(timeout: 10), "Progress did not load")
        let squat = app.buttons["progress.exercise.back-squat"]
        XCTAssertTrue(app.scrollTo(squat), "Back squat not listed on Progress")
        let bench = app.buttons["progress.exercise.barbell-bench-press"]
        XCTAssertTrue(bench.exists, "Bench press not listed on Progress")
        snap("progress-exercises-\(appearance)")
        bench.tap()

        let value = app.descendants(matching: .any)["progress.value"]
        XCTAssertTrue(value.waitForExistence(timeout: 5), "No chart header")
        // Est. 1RM: 62.5 × 8 → 79.2 kg, up 3.2 from 60 × 8 → 76
        XCTAssertTrue(value.label.contains("79.2 kg"), "1RM was \(value.label)")
        XCTAssertTrue(value.label.contains("+3.2 kg"), "Change missing: \(value.label)")
        XCTAssertTrue(app.descendants(matching: .any)["progress.chart"].exists, "No chart")
        snap("exercise-progress-\(appearance)")

        app.segmentedControls.buttons["Volume"].tap()
        XCTAssertTrue(value.label.contains("1,500 kg"), "Volume was \(value.label)")
        app.segmentedControls.buttons["Max Weight"].tap()
        XCTAssertTrue(value.label.contains("62.5 kg"), "Max weight was \(value.label)")
    }
}
