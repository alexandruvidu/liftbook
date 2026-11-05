import XCTest

@MainActor
final class ProgressPhotosUITests: XCTestCase {
    func testProgressPhotosLight() { progressPhotos(appearance: "light") }
    func testProgressPhotosDark() { progressPhotos(appearance: "dark") }

    func testEmptyState() {
        let app = XCUIApplication.launchLiftbook()
        app.tabBars.buttons["Profile"].tap()
        let link = app.buttons["profile.photos"]
        XCTAssertTrue(link.waitForExistence(timeout: 10), "No progress photos link")
        link.tap()
        XCTAssertTrue(app.descendants(matching: .any)["photos.empty"].waitForExistence(timeout: 5), "No empty state")
        XCTAssertTrue(app.buttons["photos.add"].exists, "No add button")
    }

    private func progressPhotos(appearance: String) {
        continueAfterFailure = false
        let app = XCUIApplication.launchLiftbook(appearance: appearance, seedPhotos: true)
        app.tabBars.buttons["Profile"].tap()
        let link = app.buttons["profile.photos"]
        XCTAssertTrue(link.waitForExistence(timeout: 10), "No progress photos link")
        link.tap()

        let items = app.buttons.matching(identifier: "photos.item")
        XCTAssertTrue(items.firstMatch.waitForExistence(timeout: 5), "No photos in the grid")
        XCTAssertEqual(items.count, 2)
        snap("progress-photos-\(appearance)")

        items.element(boundBy: 0).tap()
        XCTAssertTrue(app.images["photo.image"].waitForExistence(timeout: 5), "Photo did not open")
        snap("progress-photo-detail-\(appearance)")

        app.buttons["photo.delete"].tap()
        let confirm = app.buttons.matching(NSPredicate(
            format: "identifier == 'photo.confirmDelete' OR (label == 'Delete Photo' AND identifier != 'photo.delete')"
        )).firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), "No delete confirmation")
        confirm.tap()
        XCTAssertTrue(items.firstMatch.waitForExistence(timeout: 5), "Not back on the grid")
        expectation(for: NSPredicate(format: "count == 1"), evaluatedWith: items)
        waitForExpectations(timeout: 5)
    }
}
