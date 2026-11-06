import XCTest

@MainActor
final class LiveActivityUITests: XCTestCase {
    /// Notification Center follows the simulator's system appearance (light),
    /// not the app's forced one, so a single run covers it.
    func testRestLiveActivity() {
        let appearance = "light"
        continueAfterFailure = false
        let app = XCUIApplication.launchLiftbook(appearance: appearance, seedSampleData: true)
        app.buttons["routine.row.Upper Body"].tap()
        let start = app.buttons["routine.start"]
        XCTAssertTrue(start.waitForExistence(timeout: 5), "Routine detail did not open")
        start.tap()

        // Check off a set to start a rest
        let weight = app.textFields["live.exercise.0.set.0.weight"]
        XCTAssertTrue(weight.waitForExistence(timeout: 10), "No weight field")
        weight.enter("60")
        app.textFields["live.exercise.0.set.0.reps"].enter("8")
        app.dismissKeyboard()
        app.buttons["live.exercise.0.set.0.check"].tap()
        XCTAssertTrue(app.staticTexts["rest.remaining"].waitForExistence(timeout: 5), "Rest did not start")

        // Leave the app and pull down Notification Center, which shows
        // Live Activities like the Lock Screen does.
        XCUIDevice.shared.press(.home)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let top = springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.005))
        top.press(forDuration: 0.1, thenDragTo: springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.7)))
        let activity = springboard.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS[c] %@", "Barbell Bench Press")).firstMatch
        XCTAssertTrue(activity.waitForExistence(timeout: 10), "Rest Live Activity not shown")
        snap("live-activity-\(appearance)")

        // Back to the app: skipping the rest removes the activity.
        app.activate()
        XCTAssertTrue(app.buttons["rest.skip"].waitForExistence(timeout: 10), "Rest timer not shown after returning")
        app.buttons["rest.skip"].tap()
    }
}
