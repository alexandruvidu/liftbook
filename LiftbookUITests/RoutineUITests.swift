import XCTest

@MainActor
final class RoutineUITests: XCTestCase {
    func testRoutinesInFoldersLight() { buildRoutine(appearance: "light") }
    func testRoutinesInFoldersDark() { buildRoutine(appearance: "dark") }

    func testDuplicateFolderNameIsRefused() {
        continueAfterFailure = false
        let app = XCUIApplication.launchLiftbook()
        // A list section header can show up more than once to accessibility,
        // so compare against the count after the first folder.
        var menusAfterFirst = 0
        for name in ["Push", "push"] {
            XCTAssertTrue(app.buttons["workout.add"].waitForExistence(timeout: 10))
            app.buttons["workout.add"].tap()
            app.buttons["workout.newFolder"].firstMatch.tap()
            let field = app.alerts.textFields.firstMatch
            XCTAssertTrue(field.waitForExistence(timeout: 5))
            field.enter(name)
            app.alerts.buttons["Create"].tap()
            if name == "Push" {
                XCTAssertTrue(app.buttons["folder.menu.Push"].waitForExistence(timeout: 5))
                menusAfterFirst = app.buttons.matching(identifier: "folder.menu.Push").count
            }
        }
        let duplicate = app.alerts["You already have a folder called push"]
        XCTAssertTrue(duplicate.waitForExistence(timeout: 5))
        duplicate.buttons["OK"].tap()
        XCTAssertEqual(app.buttons.matching(identifier: "folder.menu.Push").count, menusAfterFirst)
        XCTAssertFalse(app.buttons["folder.menu.push"].exists)
    }

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
        folderName.enter("Push")
        app.alerts.buttons["Create"].tap()
        XCTAssertTrue(app.staticTexts["No routines in this folder yet."].waitForExistence(timeout: 5))

        // Routine
        app.buttons["workout.add"].tap()
        app.buttons["workout.newRoutine"].firstMatch.tap()
        let name = app.textFields["routine.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.enter("Push Day")
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
            search.enter(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 30) + query)
            let row = app.buttons["picker.row.\(id)"]
            XCTAssertTrue(row.waitForExistence(timeout: 5), "Missing \(id)")
            row.tap()
        }
        let add = app.buttons["picker.add"]
        XCTAssertTrue(add.waitForExistence(timeout: 5))
        XCTAssertEqual(add.label, "Add 3 Exercises")
        snap("exercise-picker-\(appearance)")
        add.tap()

        // Each exercise is a block whose header opens the exercise page
        let first = app.buttons["routine.entry.0.page"]
        XCTAssertTrue(first.waitForExistence(timeout: 5))
        XCTAssertTrue(first.label.contains("Barbell Bench Press"), first.label)
        XCTAssertTrue(app.buttons["routine.entry.2.page"].label.contains("Incline Dumbbell Press"))
        XCTAssertTrue(app.descendants(matching: .any)["routine.entry.0.set.2"].exists, "No set rows")
        snap("routine-editor-\(appearance)")
        app.buttons["routine.save"].tap()

        // Listed under its folder
        let row = app.buttons["routine.row.Push Day"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["No routines in this folder yet."].exists)
        snap("routines-list-\(appearance)")

        // Re-open and check order survived the save
        row.tap()
        let names = ["Barbell Bench Press", "Overhead Press", "Incline Dumbbell Press"]
        XCTAssertTrue(app.buttons["routine.detail.exercise.2"].waitForExistence(timeout: 5))
        for (index, name) in names.enumerated() {
            let label = app.buttons["routine.detail.exercise.\(index)"].label
            XCTAssertTrue(label.contains(name), "Exercise \(index) is \(label), not \(name)")
        }

        // An exercise opens its page
        app.buttons["routine.detail.exercise.1"].tap()
        XCTAssertTrue(app.navigationBars["Overhead Press"].waitForExistence(timeout: 5)
                      || app.staticTexts["Overhead Press"].waitForExistence(timeout: 2), "Exercise page did not open")
    }
}
