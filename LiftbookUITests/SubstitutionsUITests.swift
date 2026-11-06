import XCTest

@MainActor
final class SubstitutionsUITests: XCTestCase {
    func testSubstitutionsLight() { substitutions(appearance: "light") }
    func testSubstitutionsDark() { substitutions(appearance: "dark") }

    private func substitutions(appearance: String) {
        continueAfterFailure = false
        let app = XCUIApplication.launchLiftbook(appearance: appearance, seedSampleData: true)

        // Alternatives on an exercise page
        app.openTab("Exercises")
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 10), "No search field")
        search.enter("barbell bench")
        let bench = app.buttons["exercise.row.barbell-bench-press"]
        XCTAssertTrue(bench.waitForExistence(timeout: 5), "Bench press not listed")
        bench.tap()
        let alternatives = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'exercise.alternative.'"))
        XCTAssertTrue(app.scrollTo(alternatives.firstMatch), "No alternatives on the bench press page")
        snap("exercise-alternatives-\(appearance)")

        // Swap during a workout
        app.openTab("Home")
        let routine = app.buttons["routine.row.Upper Body"]
        XCTAssertTrue(routine.waitForExistence(timeout: 10), "Seeded routine missing")
        routine.tap()
        app.buttons["routine.start"].tap()
        XCTAssertTrue(app.buttons["live.finish"].waitForExistence(timeout: 10), "Live workout did not open")
        let swap = app.buttons["Swap Exercise"]
        XCTAssertTrue(app.buttons["live.exercise.0.options"].openMenu(showing: swap), "No swap option")
        swap.tap()
        let options = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'swap.option.'"))
        XCTAssertTrue(options.firstMatch.waitForExistence(timeout: 5), "No suggestions")
        snap("swap-exercise-\(appearance)")
        let choice = options.firstMatch
        let name = String(choice.label.split(separator: ",").first ?? "")
        choice.tap()
        XCTAssertTrue(options.firstMatch.waitForNonExistence(timeout: 5), "Sheet did not close")
        let header = app.buttons["live.exercise.0.collapse"]
        XCTAssertTrue(header.waitForExistence(timeout: 5), "No exercise header")
        XCTAssertTrue(header.label.contains(name), "Exercise not swapped to \(name): \(header.label)")
    }
}
