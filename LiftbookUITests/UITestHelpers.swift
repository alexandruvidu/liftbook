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

extension XCUIApplication {
    /// Opens a tab by title; "Start" taps the floating start button.
    @MainActor
    func openTab(_ title: String) {
        if title == "Start" {
            // The start button floats on the Home tab only.
            if !buttons["startButton"].exists { openTab("Home") }
            let start = buttons["startButton"]
            XCTAssertTrue(start.waitForExistence(timeout: 10), "No start button")
            start.tap()
            return
        }
        let inBar = tabBars.buttons[title]
        // The tab bar shrinks to the current tab after scrolling down;
        // scrolling back up brings the other tabs back.
        if !inBar.waitForExistence(timeout: 3) {
            swipeDown()
            swipeDown()
        }
        if inBar.waitForExistence(timeout: 10) {
            inBar.tap()
        } else {
            let anywhere = buttons[title].firstMatch
            XCTAssertTrue(anywhere.waitForExistence(timeout: 5), "No tab \(title)")
            anywhere.tap()
        }
    }

    /// Opens the start sheet and starts an empty workout.
    @MainActor
    func startEmptyWorkout() {
        openTab("Start")
        let empty = buttons["quickStart.empty"]
        XCTAssertTrue(empty.waitForExistence(timeout: 5), "Start sheet did not open")
        empty.tap()
        XCTAssertTrue(buttons["live.finish"].waitForExistence(timeout: 10), "Live workout did not open")
    }

    /// The bar above the tab bar that shows a workout in progress.
    var runningBar: XCUIElement { buttons["runningBar"].firstMatch }
}

extension XCUIApplication {
    /// Closes the search keyboard if one is showing (its key is "search").
    @MainActor
    func dismissKeyboardIfPresent() {
        guard keyboards.firstMatch.exists else { return }
        let search = keyboards.buttons["search"]
        if search.exists { search.tap() } else { swipeDown() }
    }
}

extension XCUIApplication {
    /// The first exercise in the library grid, whatever it is.
    var firstExerciseRow: XCUIElement {
        buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'exercise.row.'")).firstMatch
    }
}
