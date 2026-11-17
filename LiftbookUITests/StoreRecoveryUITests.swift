import XCTest

/// The recovery screen, shown when the data store can't be opened: the app is
/// relaunched with its store file overwritten (`-uiTestCorruptStore YES`).
@MainActor
final class StoreRecoveryUITests: XCTestCase {
    private func quit(_ app: XCUIApplication) {
        XCUIDevice.shared.press(.home)
        sleep(1)
        app.terminate()
    }

    private func relaunchCorrupted(_ store: String, appearance: String) -> XCUIApplication {
        let app = XCUIApplication.launchLiftbook(appearance: appearance, storeFile: store,
                                                 extraArguments: ["-uiTestCorruptStore", "YES"])
        XCTAssertTrue(app.descendants(matching: .any)["recovery.header"].waitForExistence(timeout: 10),
                      "No recovery screen")
        return app
    }

    func testRestoreTheLatestBackup() {
        continueAfterFailure = false
        let store = "recovery-\(UUID().uuidString)"
        var app = XCUIApplication.launchLiftbook(appearance: "light", storeFile: store, seedHistory: true)
        app.openTab("Profile")
        let data = app.buttons["profile.data"]
        XCTAssertTrue(app.scrollTo(data), "No export & import link")
        data.tap()
        let backUp = app.buttons["data.backUpNow"]
        XCTAssertTrue(app.scrollTo(backUp), "No Back Up Now")
        backUp.tap()
        quit(app)

        app = relaunchCorrupted(store, appearance: "light")
        XCTAssertTrue(app.descendants(matching: .any)["recovery.latest"].exists, "The backup isn't offered")
        snap("store-recovery-light")
        app.buttons["recovery.restore"].tap()

        app.openTab("Activity")
        let cards = app.buttons.matching(identifier: "history.row")
        XCTAssertTrue(cards.firstMatch.waitForExistence(timeout: 10), "Workouts weren't restored")
        XCTAssertEqual(cards.count, 3)
    }

    func testStartEmpty() {
        continueAfterFailure = false
        let store = "recovery-\(UUID().uuidString)"
        let first = XCUIApplication.launchLiftbook(appearance: "dark", storeFile: store, seedHistory: true)
        first.openTab("Activity")
        XCTAssertTrue(first.buttons["history.row"].firstMatch.waitForExistence(timeout: 10), "No seeded workouts")
        quit(first)

        let app = relaunchCorrupted(store, appearance: "dark")
        snap("store-recovery-dark")
        app.buttons["recovery.startEmpty"].tap()
        let confirm = app.buttons["recovery.confirmEmpty"].firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), "No confirmation")
        confirm.tap()

        app.openTab("Activity")
        XCTAssertTrue(app.descendants(matching: .any)["activity.empty"].waitForExistence(timeout: 10),
                      "The app didn't start empty")
    }
}
