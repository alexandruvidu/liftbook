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
        let done = buttons["keyboard.done"]
        if done.waitForExistence(timeout: 2) { done.tap() }
        XCTAssertTrue(keyboards.firstMatch.waitForNonExistence(timeout: 5), "Keyboard did not close")
    }
}

extension XCUIElement {
    var hasKeyboardFocus: Bool { (value(forKey: "hasKeyboardFocus") as? Bool) ?? false }

    /// Taps the field, waits until it has keyboard focus (tapping again if a
    /// scroll swallowed the first tap), then types the text.
    @MainActor
    func enter(_ text: String) {
        XCTAssertTrue(waitForExistence(timeout: 5), "Field \(self) missing")
        for _ in 0..<3 where !hasKeyboardFocus {
            tap()
            let focused = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hasKeyboardFocus == true"), object: self)
            if XCTWaiter().wait(for: [focused], timeout: 2) == .completed { break }
        }
        XCTAssertTrue(hasKeyboardFocus, "Field \(self) never got keyboard focus")
        typeText(text)
    }
}

extension XCUIApplication {
    /// Swipes up until the element exists and is on screen (lists only build
    /// visible rows). Returns whether it was found.
    @MainActor
    @discardableResult
    func scrollTo(_ element: XCUIElement, maxSwipes: Int = 6) -> Bool {
        for _ in 0..<maxSwipes {
            if element.exists && element.isHittable { return true }
            swipeUp()
        }
        return element.exists && element.isHittable
    }
}

extension XCUIApplication {
    /// Taps Finish, then Done on the summary that follows.
    @MainActor
    func finishWorkout() {
        buttons["live.finish"].tap()
        let done = buttons["summary.done"]
        XCTAssertTrue(done.waitForExistence(timeout: 10), "No workout summary after Finish")
        done.tap()
    }
}
