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

    func testTypeDetailsLight() { showTypes(appearance: "light") }
    func testTypeDetailsDark() { showTypes(appearance: "dark") }

    private func showTypes(appearance: String) {
        continueAfterFailure = false
        for item in Self.cases {
            let app = XCUIApplication.launchLiftbook(appearance: appearance)
            app.tabBars.buttons["Exercises"].tap()

            let search = app.searchFields.firstMatch
            XCTAssertTrue(search.waitForExistence(timeout: 10))
            search.tap()
            search.typeText(item.query)

            let row = app.buttons["exercise.row.\(item.id)"]
            XCTAssertTrue(row.waitForExistence(timeout: 5), "No row for \(item.id)")
            row.tap()

            let example = app.descendants(matching: .any)["exercise.detail.example"]
            let list = app.collectionViews.firstMatch
            var swipes = 0
            while !(example.exists && example.isHittable) && swipes < 4 {
                list.swipeUp()
                swipes += 1
            }
            XCTAssertTrue(example.exists, "No example for \(item.id)")
            let shown = app.descendants(matching: .any)
                .matching(NSPredicate(format: "label CONTAINS %@", item.example)).firstMatch
            XCTAssertTrue(shown.exists, "Expected example \(item.example)")
            snap("exercise-type-\(item.shot)-\(appearance)")
            app.terminate()
        }
    }
}
