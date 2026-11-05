import XCTest

extension XCUIElement {
    /// Taps a menu button and waits for `item` to appear, tapping once more
    /// if the first tap only stopped a scroll or landed during an animation.
    @MainActor
    func openMenu(showing item: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        XCTAssertTrue(waitForExistence(timeout: timeout), "Menu button \(self) missing")
        tap()
        if item.waitForExistence(timeout: 3) { return true }
        tap()
        return item.waitForExistence(timeout: timeout)
    }
}
