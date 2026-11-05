import XCTest

@MainActor
final class ExerciseTypeUITests: XCTestCase {
    private static let cases: [(id: String, query: String, example: String, shot: String)] = [
        ("barbell-bench-press", "bench", "60 kg × 8", "weight-reps"),
        ("pull-up", "pull-up", "12 reps", "bodyweight"),
        ("assisted-pull-up", "assisted", "8 reps · 20 kg assist", "assisted"),
        ("plank", "plank", "1:00", "duration"),
        ("running", "running", "5 km in 25:00", "distance"),
    ]

    /// Every type in light mode; dark mode uses the same layout, so one type is enough.
    func testTypeDetailsLight() { showTypes(Self.cases, appearance: "light") }
    func testTypeDetailsDark() { showTypes(Self.cases.filter { $0.shot == "assisted" }, appearance: "dark") }

    private func showTypes(_ items: [(id: String, query: String, example: String, shot: String)], appearance: String) {
        continueAfterFailure = false
        for item in items {
            let app = XCUIApplication.launchLiftbook(appearance: appearance)
            app.tabBars.buttons["Exercises"].tap()

            let search = app.searchFields.firstMatch
            XCTAssertTrue(search.waitForExistence(timeout: 10))
            search.enter(item.query)

            let row = app.buttons["exercise.row.\(item.id)"]
            XCTAssertTrue(row.waitForExistence(timeout: 5), "No row for \(item.id)")
            row.tap()

            let example = app.descendants(matching: .any)["exercise.detail.example"]
            // Scroll to the bottom so the set section clears the floating tab bar.
            let list = app.collectionViews.firstMatch
            XCTAssertTrue(list.waitForExistence(timeout: 5))
            list.swipeUp()
            list.swipeUp()
            XCTAssertTrue(example.waitForExistence(timeout: 5), "No example for \(item.id)")
            let shown = app.descendants(matching: .any)
                .matching(NSPredicate(format: "label CONTAINS %@", item.example)).firstMatch
            XCTAssertTrue(shown.exists, "Expected example \(item.example)")
            snap("exercise-type-\(item.shot)-\(appearance)")
            app.terminate()
        }
    }
}
