import XCTest

/// Experiment: screenshots the tab bar declared a few ways, to see which one
/// iOS draws with Start as a separate round button. Temporary.
@MainActor
final class TabVariantUITests: XCTestCase {
    func testTabVariants() {
        for variant in 0...2 {
            let app = XCUIApplication()
            app.launchArguments += ["-uiTestAppearance", "light", "-uiTestInMemoryStore", "YES",
                                    "-uiTestTabVariant", "\(variant)"]
            app.launch()
            XCTAssertTrue(app.navigationBars["Home"].waitForExistence(timeout: 15))
            snap("tab-variant-\(variant)")
            app.terminate()
        }
    }
}
