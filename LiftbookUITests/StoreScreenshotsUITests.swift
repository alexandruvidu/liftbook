import XCTest

/// The screenshots shown in the SideStore source. Not part of the regular
/// suite's checks; run it to refresh them:
///
///     TEST_RUNNER_SCREENSHOT_DIR="$PWD/docs/screenshots/store" scripts/test.sh StoreScreenshotsUITests
///
/// Files are named so they sort in the order the store shows them: the
/// workout and Live Activity first.
@MainActor
final class StoreScreenshotsUITests: XCTestCase {
    private let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

    override func tearDown() async throws {
        // Unlock again after the Lock Screen shot.
        await MainActor.run {
            XCUIDevice.shared.press(.home)
            springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.98))
                .press(forDuration: 0.1, thenDragTo: springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2)))
        }
    }

    func testStoreScreenshots() {
        continueAfterFailure = false
        let app = XCUIApplication.launchLiftbook(appearance: "light", seedSampleData: true, seedHistory: true,
                                                 extraArguments: ["-uiTestLiveActivity", "YES",
                                                                  // RepDB's pictures may not be republished.
                                                                  "-uiTestHideExerciseArt", "YES"])

        // 1. Routines
        let routine = app.buttons["routine.row.Upper Body"]
        XCTAssertTrue(routine.waitForExistence(timeout: 10))
        snap("6-routines")

        // 2. Activity: the week and history
        app.openTab("Activity")
        XCTAssertTrue(app.buttons.matching(identifier: "history.row").firstMatch.waitForExistence(timeout: 5))
        snap("4-activity")

        // 3. Exercise progress: chart and records
        app.openTab("Exercises")
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 10))
        snap("5-exercises")
        search.enter("bench press")
        let bench = app.buttons["exercise.row.barbell-bench-press"]
        XCTAssertTrue(bench.waitForExistence(timeout: 5))
        bench.tap()
        // One swipe from the top: past the picture to the chart and records.
        XCTAssertTrue(app.navigationBars["Barbell Bench Press"].waitForExistence(timeout: 5))
        app.swipeUp()
        snap("3-progress")

        // 5. Logging a workout, with last time's values
        app.openTab("Home")
        routine.tap()
        app.buttons["routine.start"].tap()
        let check = app.buttons["live.exercise.0.set.0.check"]
        XCTAssertTrue(check.waitForExistence(timeout: 10))
        check.tap()
        XCTAssertTrue(app.staticTexts["rest.remaining"].waitForExistence(timeout: 5))
        snap("1-workout")

        // 6. The Live Activity on the Lock Screen
        XCUIDevice.shared.perform(NSSelectorFromString("pressLockButton"))
        XCTAssertTrue(springboard.buttons["Skip"].waitForExistence(timeout: 15))
        springboard.buttons["Skip"].tap()
        XCTAssertTrue(springboard.buttons["Log Set"].waitForExistence(timeout: 10))
        // The one-time system question, answered so it isn't in the picture.
        let allow = springboard.buttons["Allow"]
        if allow.exists { allow.tap() }
        XCTAssertTrue(allow.waitForNonExistence(timeout: 5))
        snap("2-live-activity")
    }
}
