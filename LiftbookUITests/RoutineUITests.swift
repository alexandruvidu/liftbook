import XCTest

@MainActor
final class RoutineUITests: XCTestCase {
    func testRoutinesInFoldersLight() { buildRoutine(appearance: "light") }
    func testRoutinesInFoldersDark() { buildRoutine(appearance: "dark") }

    private func buildRoutine(appearance: String) {
        continueAfterFailure = false
        let app = XCUIApplication.launchLiftbook(appearance: appearance)

        // Empty state
        XCTAssertTrue(app.buttons["workout.emptyNewRoutine"].waitForExistence(timeout: 10))
        snap("routines-empty-\(appearance)")

        // Folder
        app.buttons["workout.add"].tap()
        app.buttons["workout.newFolder"].firstMatch.tap()
        let folderName = app.alerts.textFields.firstMatch
        XCTAssertTrue(folderName.waitForExistence(timeout: 5))
        folderName.tap()
        folderName.typeText("Push")
        app.alerts.buttons["Create"].tap()
        XCTAssertTrue(app.staticTexts["No routines in this folder yet."].waitForExistence(timeout: 5))

        // Routine
        app.buttons["workout.add"].tap()
        app.buttons["workout.newRoutine"].firstMatch.tap()
        let name = app.textFields["routine.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText("Push Day")
        XCTAssertFalse(app.buttons["routine.save"].isEnabled, "Save needs an exercise")

        app.buttons["routine.folder"].tap()
        app.buttons["Push"].firstMatch.tap()

        app.buttons["routine.addExercises"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        let picks = [
            ("barbell bench", "barbell-bench-press"),
            ("overhead press", "overhead-press"),
            ("incline dumbbell press", "incline-dumbbell-press"),
        ]
        for (query, id) in picks {
            search.tap()
            search.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 30) + query)
            let row = app.buttons["picker.row.\(id)"]
            XCTAssertTrue(row.waitForExistence(timeout: 5), "Missing \(id)")
            row.tap()
        }
        let add = app.buttons["picker.add"]
        XCTAssertTrue(add.waitForExistence(timeout: 5))
        XCTAssertEqual(add.label, "Add 3 Exercises")
        snap("exercise-picker-\(appearance)")
        add.tap()

        XCTAssertTrue(app.staticTexts["Barbell Bench Press"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Incline Dumbbell Press"].exists)
        snap("routine-editor-\(appearance)")
        app.buttons["routine.save"].tap()

        // Listed under its folder
        let row = app.buttons["routine.row.Push Day"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["No routines in this folder yet."].exists)
        snap("routines-list-\(appearance)")

        // Re-open and check order survived the save
        row.tap()
        XCTAssertTrue(app.staticTexts["Overhead Press"].waitForExistence(timeout: 5))
        let bench = app.staticTexts["Barbell Bench Press"].frame.minY
        let overhead = app.staticTexts["Overhead Press"].frame.minY
        let incline = app.staticTexts["Incline Dumbbell Press"].frame.minY
        XCTAssertLessThan(bench, overhead)
        XCTAssertLessThan(overhead, incline)
    }
}
