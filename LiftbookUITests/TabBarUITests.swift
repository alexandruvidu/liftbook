import XCTest

@MainActor
final class TabBarUITests: XCTestCase {
    private static let tabs: [(title: String, contentID: String)] = [
        ("Home", "workout.emptyNewRoutine"),
        ("Exercises", "exercise.row.ab-wheel-rollout"),
        ("Activity", "activity.week"),
        ("Profile", "profile.body"),
    ]

    func testEveryTabOpensInLightMode() {
        visitAllTabs(appearance: "light")
    }

    func testEveryTabOpensInDarkMode() {
        visitAllTabs(appearance: "dark")
    }

    private func visitAllTabs(appearance: String) {
        continueAfterFailure = false
        let app = XCUIApplication.launchLiftbook(appearance: appearance)

        for tab in Self.tabs {
            app.openTab(tab.title)
            XCTAssertTrue(app.navigationBars[tab.title].waitForExistence(timeout: 5), "No title for \(tab.title)")
            XCTAssertTrue(app.descendants(matching: .any)[tab.contentID].waitForExistence(timeout: 5), "No content on \(tab.title)")
            snap("tab-\(tab.title.lowercased())-\(appearance)")
        }

        // The start button opens the quick-start sheet without leaving the tab
        app.openTab("Start")
        XCTAssertTrue(app.buttons["quickStart.empty"].waitForExistence(timeout: 5), "Start sheet did not open")
    }
}
