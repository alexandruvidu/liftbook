import XCTest

@MainActor
final class BodyMeasurementsUITests: XCTestCase {
    func testBodyMeasurementsLight() { bodyMeasurements(appearance: "light") }
    func testBodyMeasurementsDark() { bodyMeasurements(appearance: "dark") }

    private func log(_ value: String, in app: XCUIApplication) {
        app.buttons["body.add"].tap()
        let field = app.textFields["body.value"]
        XCTAssertTrue(field.waitForExistence(timeout: 5), "Log sheet did not open")
        field.enter(value)
        app.buttons["body.save"].tap()
        XCTAssertTrue(field.waitForNonExistence(timeout: 5), "Log sheet did not close")
    }

    private func bodyMeasurements(appearance: String) {
        continueAfterFailure = false
        let app = XCUIApplication.launchLiftbook(appearance: appearance)
        app.openTab("Profile")
        let body = app.buttons["profile.body"]
        XCTAssertTrue(body.waitForExistence(timeout: 10), "No body measurements link")
        body.tap()

        // Built-in metrics are there; log body weight twice
        let weight = app.buttons["body.metric.Body Weight"]
        XCTAssertTrue(weight.waitForExistence(timeout: 5), "No Body Weight metric")
        XCTAssertTrue(app.buttons["body.metric.Body Fat"].exists, "No Body Fat metric")
        weight.tap()
        XCTAssertTrue(app.staticTexts["body.empty"].waitForExistence(timeout: 5), "No empty state")
        log("82.4", in: app)
        log("81.6", in: app)
        let latest = app.descendants(matching: .any)["body.latest"]
        XCTAssertTrue(latest.waitForExistence(timeout: 5), "No latest value")
        XCTAssertTrue(latest.label.contains("81.6 kg"), "Latest was \(latest.label)")
        XCTAssertTrue(latest.label.contains("−0.8 kg"), "Change was \(latest.label)")
        XCTAssertTrue(app.descendants(matching: .any)["body.chart"].exists, "No chart with two entries")
        snap("body-weight-\(appearance)")

        // A custom metric
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["body.addMetric"].tap()
        let name = app.textFields["body.metricName"]
        XCTAssertTrue(name.waitForExistence(timeout: 5), "New metric sheet did not open")
        name.enter("Waist")
        app.buttons["body.saveMetric"].tap()
        let waist = app.buttons["body.metric.Waist"]
        XCTAssertTrue(waist.waitForExistence(timeout: 5), "Custom metric not added")
        XCTAssertTrue(app.buttons["body.metric.Body Weight"].label.contains("81.6 kg"), "List shows the latest weight")
        snap("body-metrics-\(appearance)")
    }
}
