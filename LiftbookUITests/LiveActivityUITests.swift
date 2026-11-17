import XCTest

/// The workout's Live Activity on the Lock Screen: Log Set checks off the
/// next set in the app and starts a rest that says what's next; +30s adds to
/// it and Skip ends it.
@MainActor
final class LiveActivityUITests: XCTestCase {
    private let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

    override func tearDown() async throws {
        // Leave the simulator unlocked for the next test: wake it, then
        // swipe up (simulators have no passcode).
        // Retried once: a test that starts while it's still locked (often the
        // unit tests' host app) hangs before connecting.
        await MainActor.run {
            for _ in 0..<2 {
                XCUIDevice.shared.press(.home)
                let bottom = springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.98))
                bottom.press(forDuration: 0.1, thenDragTo: springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2)))
                if springboard.icons.firstMatch.waitForExistence(timeout: 5) { break }
            }
        }
    }

    func testLogSetFromTheLockScreen() {
        continueAfterFailure = false
        // History gives bench press last time's values, so a set can be logged without typing.
        let liftbook = XCUIApplication.launchLiftbook(seedSampleData: true, seedHistory: true, extraArguments: ["-uiTestLiveActivity", "YES"])

        let routine = liftbook.buttons["routine.row.Upper Body"]
        XCTAssertTrue(routine.waitForExistence(timeout: 10))
        routine.tap()
        liftbook.buttons["routine.start"].tap()
        let progress = liftbook.staticTexts["live.exercise.0.progress"]
        XCTAssertTrue(progress.waitForExistence(timeout: 10), "Live workout did not open")
        XCTAssertTrue(progress.label.hasPrefix("0 /"), progress.label)

        XCUIDevice.shared.perform(NSSelectorFromString("pressLockButton"))
        let logSet = springboard.buttons["Log Set"]
        XCTAssertTrue(logSet.waitForExistence(timeout: 15), "No Live Activity on the Lock Screen")
        snap("live-activity-set")
        logSet.tap()

        let skip = springboard.buttons["Skip"]
        XCTAssertTrue(skip.waitForExistence(timeout: 10), "Logging a set didn't start the rest")
        let next = springboard.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Next: '")).firstMatch
        XCTAssertTrue(next.exists, "The rest doesn't say what's next")
        XCTAssertTrue(next.label.contains("Set 2 of 3"), next.label)
        snap("live-activity-rest")
        let addRest = springboard.buttons["Add 30 Seconds"]
        XCTAssertTrue(addRest.exists, "No +30s button")
        addRest.tap()
        XCTAssertTrue(skip.waitForExistence(timeout: 10), "Adding rest ended it")
        skip.tap()
        XCTAssertTrue(springboard.buttons["Log Set"].waitForExistence(timeout: 10), "Skip didn't end the rest")

        XCUIDevice.shared.press(.home)
        liftbook.activate()
        XCTAssertTrue(progress.waitForExistence(timeout: 10))
        XCTAssertTrue(progress.label.hasPrefix("1 /"), "The set wasn't logged: \(progress.label)")
        // Ends the Live Activity too: left running, it kept the next test
        // run's host app from connecting.
        liftbook.finishWorkout()
    }
}
