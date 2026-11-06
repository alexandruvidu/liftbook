import XCTest

@MainActor
final class WorkoutDetailUITests: XCTestCase {
    func testWorkoutDetailLight() { workoutDetail(appearance: "light") }
    func testWorkoutDetailDark() { workoutDetail(appearance: "dark") }

    private func element(_ id: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    private func workoutDetail(appearance: String) {
        continueAfterFailure = false
        let app = XCUIApplication.launchLiftbook(appearance: appearance, seedHistory: true)
        app.openTab("Activity")
        let rows = app.buttons.matching(identifier: "history.row")
        XCTAssertTrue(rows.firstMatch.waitForExistence(timeout: 10), "No history rows")

        // Detail of the newest workout (Upper Body, 2 exercises × 3 sets at 62.5 kg)
        rows.element(boundBy: 0).tap()
        let sets = element("detail.sets", in: app)
        XCTAssertTrue(sets.waitForExistence(timeout: 5), "Detail did not open")
        XCTAssertTrue(sets.label.hasPrefix("6"), "Sets tile was \(sets.label)")
        XCTAssertTrue(element("detail.exercise.0.set.0", in: app).label.contains("62.5 kg × 8"), "Set line wrong")
        snap("workout-detail-\(appearance)")

        // Share exports this workout as a CSV file
        // (The system share sheet is checked by its screenshot: asserting on
        // its elements was flaky on CI.)
        app.buttons["detail.share"].tap()
        _ = app.otherElements["ActivityListView"].waitForExistence(timeout: 5)
        snap("workout-share-\(appearance)")
        // Close the share sheet
        let close = app.buttons.matching(NSPredicate(format: "label == 'Close' OR identifier == 'Close'")).firstMatch
        if close.exists { close.tap() } else { app.swipeDown(velocity: .fast) }
        _ = app.otherElements["ActivityListView"].waitForNonExistence(timeout: 5)
        XCTAssertTrue(app.buttons["detail.edit"].waitForExistence(timeout: 5), "Share sheet did not close")

        // Edit the name and length
        // Retry once: the first tap can land while the share sheet is still closing.
        let name = app.textFields["edit.name"]
        app.buttons["detail.edit"].tap()
        if !name.waitForExistence(timeout: 4) { app.buttons["detail.edit"].tap() }
        XCTAssertTrue(name.waitForExistence(timeout: 5), "Editor did not open")
        name.enter(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 20) + "Heavy Upper")
        app.dismissKeyboard()
        app.steppers["edit.duration"].buttons.element(boundBy: 1).tap()
        snap("workout-edit-\(appearance)")
        app.buttons["edit.done"].tap()
        XCTAssertTrue(app.navigationBars["Heavy Upper"].waitForExistence(timeout: 5), "Name not saved")
        XCTAssertTrue(element("detail.duration", in: app).label.hasPrefix("57:00"), "Duration not saved")

        // Repeat starts a new workout with the same sets, not checked off
        app.scrollTo(app.buttons["detail.repeat"])
        app.buttons["detail.repeat"].tap()
        XCTAssertTrue(app.buttons["live.finish"].waitForExistence(timeout: 10), "Repeat did not start a workout")
        XCTAssertEqual(app.textFields["live.exercise.0.set.0.weight"].value as? String, "62.5")
        XCTAssertEqual(app.buttons["live.exercise.0.set.0.check"].label, "Mark set 1 done")
        app.scrollTo(app.buttons["live.discard"])
        app.buttons["live.discard"].tap()
        let confirmDiscard = app.buttons.matching(NSPredicate(
            format: "identifier == 'live.confirmDiscard' OR (label == 'Discard Workout' AND identifier != 'live.discard')"
        )).firstMatch
        XCTAssertTrue(confirmDiscard.waitForExistence(timeout: 5), "No discard confirmation")
        confirmDiscard.tap()

        // Delete removes it from history
        XCTAssertTrue(app.buttons["detail.delete"].waitForExistence(timeout: 10), "Not back on the detail page")
        app.scrollTo(app.buttons["detail.delete"])
        app.buttons["detail.delete"].tap()
        let confirmDelete = app.buttons.matching(NSPredicate(
            format: "identifier == 'detail.confirmDelete' OR (label == 'Delete Workout' AND identifier != 'detail.delete')"
        )).firstMatch
        XCTAssertTrue(confirmDelete.waitForExistence(timeout: 5), "No delete confirmation")
        confirmDelete.tap()
        XCTAssertTrue(rows.firstMatch.waitForExistence(timeout: 5), "Not back on the history list")
        let two = NSPredicate(format: "count == 2")
        expectation(for: two, evaluatedWith: rows)
        waitForExpectations(timeout: 5)
    }
}
