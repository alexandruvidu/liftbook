import XCTest

extension XCTestCase {
    /// Takes a screenshot, attaches it to the test result, and, when the
    /// `SCREENSHOT_DIR` environment variable is set (CI passes it through
    /// `TEST_RUNNER_SCREENSHOT_DIR`), writes `<name>.png` into that folder.
    @MainActor
    func snap(_ name: String) {
        let screenshot = XCUIScreen.main.screenshot()

        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        guard let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"], !dir.isEmpty else {
            return
        }
        let folder = URL(fileURLWithPath: dir, isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try screenshot.pngRepresentation.write(to: folder.appendingPathComponent("\(name).png"))
        } catch {
            XCTFail("Could not write screenshot \(name): \(error)")
        }
    }
}
