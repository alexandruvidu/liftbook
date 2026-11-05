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

extension XCUIApplication {
    /// Closes the number keyboard with its Done button. When the simulator
    /// uses a hardware keyboard there's no on-screen keyboard (or Done), so
    /// this just checks nothing is left open.
    @MainActor
    func dismissKeyboard() {
        let done = buttons["live.keyboardDone"]
        if done.waitForExistence(timeout: 2) { done.tap() }
        XCTAssertTrue(keyboards.firstMatch.waitForNonExistence(timeout: 5), "Keyboard did not close")
    }
}
