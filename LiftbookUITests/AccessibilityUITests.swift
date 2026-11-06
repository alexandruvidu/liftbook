import XCTest

@MainActor
final class AccessibilityUITests: XCTestCase {
    private var issues: [String] = []

    /// Runs the system accessibility audit for missing descriptions and
    /// records every issue, so one run lists them all.
    private func audit(_ screen: String, in app: XCUIApplication) throws {
        try app.performAccessibilityAudit(for: [.sufficientElementDescription]) { issue in
            let element = issue.element.map { "\($0.elementType.rawValue) '\($0.identifier)' '\($0.label)'" } ?? "no element"
            self.issues.append("\(screen): \(issue.compactDescription) — \(element)")
            return true
        }
    }

    func testMainScreensAtLargeTextSize() throws {
        continueAfterFailure = false
        let app = XCUIApplication.launchLiftbook(appearance: "dark", seedSampleData: true, seedHistory: true,
                                                 textSize: "UICTContentSizeCategoryAccessibilityL")

        XCTAssertTrue(app.buttons["routine.row.Upper Body"].waitForExistence(timeout: 10), "Home tab did not load")
        snap("accessibility-workout-dark")
        try audit("Home", in: app)

        app.openTab("Activity")
        XCTAssertTrue(app.buttons.matching(identifier: "history.row").firstMatch.waitForExistence(timeout: 5))
        snap("accessibility-history-dark")
        try audit("Activity", in: app)

        app.buttons["activity.shortcut.muscles"].tap()
        XCTAssertTrue(app.staticTexts["weekly.title"].waitForExistence(timeout: 5))
        try audit("Muscles", in: app)

        app.openTab("Exercises")
        XCTAssertTrue(app.searchFields.firstMatch.waitForExistence(timeout: 5))
        try audit("Exercises", in: app)

        app.openTab("Home")
        app.buttons["routine.row.Upper Body"].tap()
        app.buttons["routine.start"].tap()
        XCTAssertTrue(app.buttons["live.finish"].waitForExistence(timeout: 10), "Live workout did not open")
        let weight = app.textFields["live.exercise.0.set.0.weight"]
        XCTAssertTrue(weight.waitForExistence(timeout: 5))
        XCTAssertEqual(weight.label, "Set 1 weight", "Set fields should say which set they belong to")
        snap("accessibility-live-dark")
        try audit("Live workout", in: app)

        XCTAssertTrue(issues.isEmpty, "Accessibility issues:\n" + issues.joined(separator: "\n"))
    }
}
