import XCTest

@MainActor
final class PersonalRecordsUITests: XCTestCase {
    func testRecordsLight() { records(appearance: "light") }
    func testRecordsDark() { records(appearance: "dark") }

    private func records(appearance: String) {
        continueAfterFailure = false
        // Seeded bench press: 60 kg × 8 nine days ago, 62.5 kg × 8 yesterday
        let app = XCUIApplication.launchLiftbook(appearance: appearance, seedHistory: true)
        app.tabBars.buttons["Exercises"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 10), "No search field")
        search.enter("bench press")
        let row = app.buttons["exercise.row.barbell-bench-press"]
        XCTAssertTrue(row.waitForExistence(timeout: 5), "Bench press not listed")
        row.tap()

        let heaviest = app.descendants(matching: .any)["exercise.record.heaviestWeight"]
        app.scrollTo(heaviest)
        XCTAssertTrue(heaviest.exists, "No heaviest weight record")
        XCTAssertTrue(heaviest.label.contains("62.5 kg"), "Heaviest was \(heaviest.label)")
        snap("exercise-records-\(appearance)")
        let volume = app.descendants(matching: .any)["exercise.record.bestSetVolume"]
        app.scrollTo(volume)
        XCTAssertTrue(volume.label.contains("500 kg"), "Set volume was \(volume.label)")
        let reps = app.descendants(matching: .any)["exercise.record.mostReps"]
        app.scrollTo(reps)
        XCTAssertTrue(reps.label.contains("8 reps"), "Most reps was \(reps.label)")

        // An exercise never logged invites a first workout
        app.navigationBars.buttons.element(boundBy: 0).tap()
        search.enter(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 20) + "overhead press")
        let other = app.buttons["exercise.row.overhead-press"]
        XCTAssertTrue(other.waitForExistence(timeout: 5), "Overhead press not listed")
        other.tap()
        let empty = app.descendants(matching: .any)["exercise.records.empty"]
        app.scrollTo(empty)
        XCTAssertTrue(empty.exists, "No empty records hint")
    }
}
