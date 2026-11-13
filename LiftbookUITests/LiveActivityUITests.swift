import XCTest

/// The workout's Live Activity on the Lock Screen: Log Set checks off the
/// next set in the app, then Skip ends the rest it started.
@MainActor
final class LiveActivityUITests: XCTestCase {
    private let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

    override func tearDown() async throws {
        // Leave the simulator unlocked for the next test: wake it, then
        // swipe up (simulators have no passcode).
        await MainActor.run {
            XCUIDevice.shared.press(.home)
            let bottom = springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.98))
            bottom.press(forDuration: 0.1, thenDragTo: springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2)))
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
        snap("live-activity-rest")
        skip.tap()
        XCTAssertTrue(springboard.buttons["Log Set"].waitForExistence(timeout: 10), "Skip didn't end the rest")

        XCUIDevice.shared.press(.home)
        liftbook.activate()
        XCTAssertTrue(progress.waitForExistence(timeout: 10))
        XCTAssertTrue(progress.label.hasPrefix("1 /"), "The set wasn't logged: \(progress.label)")
    }
}
