import XCTest

@MainActor
final class ResumeWorkoutUITests: XCTestCase {
    func testResumeAfterRelaunchLight() { resumeAfterRelaunch(appearance: "light") }
    func testResumeAfterRelaunchDark() { resumeAfterRelaunch(appearance: "dark") }

    /// Sends the app to the background (so it saves) and quits it.
    private func quit(_ app: XCUIApplication) {
        XCUIDevice.shared.press(.home)
        sleep(1)
        app.terminate()
    }

    /// Finished workouts are still there after quitting and relaunching.
    func testHistorySurvivesRelaunch() {
        continueAfterFailure = false
        let store = "history-\(UUID().uuidString)"
        var app = XCUIApplication.launchLiftbook(appearance: "light", storeFile: store, seedHistory: true)
        app.openTab("Activity")
        let cards = app.buttons.matching(identifier: "history.row")
        XCTAssertTrue(cards.firstMatch.waitForExistence(timeout: 10), "No workouts before relaunch")
        XCTAssertEqual(cards.count, 3)
        quit(app)

        app = XCUIApplication.launchLiftbook(appearance: "light", storeFile: store)
        app.openTab("Activity")
        XCTAssertTrue(cards.firstMatch.waitForExistence(timeout: 10), "Workouts lost after relaunch")
        XCTAssertEqual(app.buttons.matching(identifier: "history.row").count, 3)
    }

    private func resumeAfterRelaunch(appearance: String) {
        continueAfterFailure = false
        let store = "resume-\(appearance)-\(UUID().uuidString)"
        var app = XCUIApplication.launchLiftbook(appearance: appearance, seedSampleData: true, storeFile: store)

        // Start a workout and log a set, then quit without finishing
        let routine = app.buttons["routine.row.Upper Body"]
        XCTAssertTrue(routine.waitForExistence(timeout: 10), "Seeded routine missing")
        routine.tap()
        let start = app.buttons["routine.start"]
        XCTAssertTrue(start.waitForExistence(timeout: 5), "Routine detail did not open")
        start.tap()
        XCTAssertTrue(app.buttons["live.finish"].waitForExistence(timeout: 10), "Live workout did not open")
        app.textFields["live.exercise.0.set.0.weight"].enter("70")
        app.textFields["live.exercise.0.set.0.reps"].enter("5")
        app.dismissKeyboard()
        app.buttons["live.exercise.0.set.0.check"].tap()
        quit(app)

        // Relaunch: offered to resume, and the logged set is still there
        app = XCUIApplication.launchLiftbook(appearance: appearance, seedSampleData: true, storeFile: store)
        let prompt = app.alerts["Pick Up Where You Left Off?"]
        XCTAssertTrue(prompt.waitForExistence(timeout: 10), "No resume prompt after relaunch")
        snap("resume-prompt-\(appearance)")
        prompt.buttons["Resume"].tap()
        XCTAssertTrue(app.buttons["live.finish"].waitForExistence(timeout: 10), "Resume did not open the workout")
        XCTAssertEqual(app.textFields["live.exercise.0.set.0.weight"].value as? String, "70", "Logged weight lost")
        XCTAssertEqual(app.buttons["live.exercise.0.set.0.check"].label, "Set 1 done", "Checked set lost")
        quit(app)

        // Relaunch again and discard
        app = XCUIApplication.launchLiftbook(appearance: appearance, seedSampleData: true, storeFile: store)
        XCTAssertTrue(prompt.waitForExistence(timeout: 10), "No resume prompt on the second relaunch")
        prompt.buttons["Discard Workout"].tap()
        XCTAssertTrue(app.buttons["routine.row.Upper Body"].waitForExistence(timeout: 10), "Home did not load")
        XCTAssertTrue(app.runningBar.waitForNonExistence(timeout: 10), "Discard left a workout running")
        XCTAssertEqual(app.buttons.matching(identifier: "routine.row.Upper Body").count, 1, "Routine was seeded twice")
    }
}
