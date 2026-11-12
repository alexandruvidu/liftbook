import XCTest

@MainActor
final class ExerciseArtUITests: XCTestCase {
    func testExerciseArtLight() { exerciseArt(appearance: "light") }
    func testExerciseArtDark() { exerciseArt(appearance: "dark") }

    /// The library shows each exercise's illustration, and its page shows the
    /// two poses cross-fading.
    private func exerciseArt(appearance: String) {
        continueAfterFailure = false
        let app = XCUIApplication.launchLiftbook(appearance: appearance)
        app.openTab("Exercises")
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 10), "No search field")
        search.enter("pec deck")
        let row = app.buttons["exercise.row.pec-deck"]
        XCTAssertTrue(row.waitForExistence(timeout: 5), "Pec deck not listed")
        snap("exercise-art-library-\(appearance)")
        row.tap()

        XCTAssertTrue(app.images["Exercise animation"].waitForExistence(timeout: 10), "No exercise illustration")
        snap("exercise-art-\(appearance)")
    }

    /// The RepDB free tier asks for a visible credit link.
    func testCreditInProfile() {
        continueAfterFailure = false
        let app = XCUIApplication.launchLiftbook()
        app.openTab("Profile")
        XCTAssertTrue(app.buttons["profile.body"].waitForExistence(timeout: 10), "Profile did not load")
        // Last in the list, which only builds rows as they scroll in.
        let credit = app.descendants(matching: .any)["profile.credits"]
        XCTAssertTrue(app.scrollTo(credit), "No credit link")
        snap("profile-credits-light")
    }
}
