import XCTest

@MainActor
final class RestoreBackupUITests: XCTestCase {
    func testRestoreBackupLight() { restoreBackup(appearance: "light") }
    func testRestoreBackupDark() { restoreBackup(appearance: "dark") }

    private func openDataScreen(_ app: XCUIApplication) {
        app.openTab("Profile")
        let link = app.buttons["profile.data"]
        XCTAssertTrue(app.scrollTo(link), "No export & import link")
        link.tap()
        XCTAssertTrue(app.descendants(matching: .any)["data.workoutCount"].waitForExistence(timeout: 5),
                      "Data screen did not open")
    }

    private func openRestore(_ app: XCUIApplication) {
        let restore = app.buttons["data.restore"]
        XCTAssertTrue(app.scrollTo(restore), "No restore link")
        restore.tap()
        XCTAssertTrue(app.buttons["restore.chooseFile"].waitForExistence(timeout: 5), "Restore screen did not open")
    }

    private func restoreBackup(appearance: String) {
        continueAfterFailure = false
        let app = XCUIApplication.launchLiftbook(appearance: appearance, seedHistory: true)
        openDataScreen(app)
        openRestore(app)
        XCTAssertTrue(app.staticTexts["restore.empty"].exists, "UI tests should start without backups")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        let backUp = app.buttons["data.backUpNow"]
        XCTAssertTrue(app.scrollTo(backUp), "No Back Up Now")
        backUp.tap()
        openRestore(app)
        let file = app.buttons["restore.file"].firstMatch
        XCTAssertTrue(file.waitForExistence(timeout: 5), "The new backup isn't listed")
        snap("restore-backup-\(appearance)")
        file.tap()
        let confirm = app.buttons["restore.confirm"].firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), "No confirmation")
        confirm.tap()

        let alert = app.alerts["Backup Restored"]
        XCTAssertTrue(alert.waitForExistence(timeout: 10), "Restore didn't finish")
        XCTAssertTrue(alert.staticTexts["3 workouts and 0 routines."].exists, "Unexpected summary")
        alert.buttons["OK"].tap()

        // Back on the data screen with the same three workouts.
        let count = app.descendants(matching: .any)["data.workoutCount"]
        XCTAssertTrue(count.waitForExistence(timeout: 5), "Didn't return to the data screen")
        XCTAssertTrue(count.label.contains("3"), "Workout count was \(count.label)")
        openRestore(app)
        let files = app.buttons.matching(identifier: "restore.file")
        XCTAssertTrue(files.firstMatch.waitForExistence(timeout: 5) && files.count >= 2, "No safety copy listed")
        XCTAssertTrue(files.matching(NSPredicate(format: "label CONTAINS 'Before restore'")).count == 1,
                      "Safety copy isn't marked")
    }

    /// A restore brings back settings and progress photos, including the file
    /// of a photo deleted after the backup.
    func testRestoreBringsBackPhotosAndSettings() {
        continueAfterFailure = false
        let app = XCUIApplication.launchLiftbook(seedPhotos: true)
        app.openTab("Profile")
        setUnit(app, "Pounds (lb)")
        openDataScreen(app)
        let backUp = app.buttons["data.backUpNow"]
        XCTAssertTrue(app.scrollTo(backUp), "No Back Up Now")
        backUp.tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()

        // Changes after the backup: kilograms again and one photo fewer.
        setUnit(app, "Kilograms (kg)")
        let photos = openPhotos(app)
        photos.element(boundBy: 0).tap()
        app.buttons["photo.delete"].tap()
        let delete = app.buttons["photo.confirmDelete"].firstMatch
        XCTAssertTrue(delete.waitForExistence(timeout: 5), "No delete confirmation")
        delete.tap()
        expectation(for: NSPredicate(format: "count == 1"), evaluatedWith: photos)
        waitForExpectations(timeout: 5)
        app.navigationBars.buttons.element(boundBy: 0).tap()

        openDataScreen(app)
        openRestore(app)
        let file = app.buttons["restore.file"].firstMatch
        XCTAssertTrue(file.waitForExistence(timeout: 5), "The backup isn't listed")
        file.tap()
        let confirm = app.buttons["restore.confirm"].firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), "No confirmation")
        confirm.tap()
        let alert = app.alerts["Backup Restored"]
        XCTAssertTrue(alert.waitForExistence(timeout: 10), "Restore didn't finish")
        alert.buttons["OK"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["data.workoutCount"].waitForExistence(timeout: 5),
                      "Didn't return to the data screen")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        XCTAssertTrue(app.buttons["settings.unit"].waitForExistence(timeout: 5), "Not back on Profile")
        XCTAssertTrue(app.buttons["settings.unit"].label.contains("Pounds"), "Unit wasn't restored")
        let restored = openPhotos(app)
        expectation(for: NSPredicate(format: "count == 2"), evaluatedWith: restored)
        waitForExpectations(timeout: 5)
        for index in 0..<2 {
            restored.element(boundBy: index).tap()
            XCTAssertTrue(app.images["photo.image"].waitForExistence(timeout: 5), "Photo \(index) has no image")
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
    }

    private func setUnit(_ app: XCUIApplication, _ name: String) {
        let option = app.buttons[name]
        XCTAssertTrue(app.buttons["settings.unit"].openMenu(showing: option), "Unit picker did not open")
        option.tap()
    }

    private func openPhotos(_ app: XCUIApplication) -> XCUIElementQuery {
        let link = app.buttons["profile.photos"]
        XCTAssertTrue(app.scrollTo(link), "No progress photos link")
        link.tap()
        let items = app.buttons.matching(identifier: "photos.item")
        XCTAssertTrue(items.firstMatch.waitForExistence(timeout: 5), "No photos in the grid")
        return items
    }

    func testRestoreWaitsForTheRunningWorkout() {
        continueAfterFailure = false
        let app = XCUIApplication.launchLiftbook()
        app.startEmptyWorkout()
        app.buttons["live.minimize"].tap()
        openDataScreen(app)
        openRestore(app)
        XCTAssertTrue(app.descendants(matching: .any)["restore.workoutRunning"].exists, "No running-workout notice")
        XCTAssertFalse(app.buttons["restore.chooseFile"].isEnabled, "Restore should be disabled")
    }
}
