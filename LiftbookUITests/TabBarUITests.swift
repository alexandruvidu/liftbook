import XCTest

@MainActor
final class TabBarUITests: XCTestCase {
    private static let tabs: [(title: String, emptyID: String)] = [
        ("Workout", "workout.empty"),
        ("History", "history.empty"),
        ("Exercises", "exercises.empty"),
        ("Progress", "progress.empty"),
        ("Profile", "profile.empty"),
    ]

    func testEveryTabOpensInLightMode() {
        visitAllTabs(appearance: "light")
    }

    func testEveryTabOpensInDarkMode() {
        visitAllTabs(appearance: "dark")
    }

    private func visitAllTabs(appearance: String) {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments += ["-uiTestAppearance", appearance]
        app.launch()

        for tab in Self.tabs {
            let button = app.tabBars.buttons[tab.title]
            XCTAssertTrue(button.waitForExistence(timeout: 15), "Missing tab \(tab.title)")
            button.tap()
            XCTAssertTrue(app.navigationBars[tab.title].waitForExistence(timeout: 5), "No title for \(tab.title)")
            XCTAssertTrue(app.descendants(matching: .any)[tab.emptyID].exists, "No empty state on \(tab.title)")
            snap("tab-\(tab.title.lowercased())-\(appearance)")
        }
    }
}
