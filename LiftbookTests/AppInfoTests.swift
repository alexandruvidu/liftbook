import Testing
@testable import Liftbook

struct AppInfoTests {
    @Test func appNameIsLiftbook() {
        #expect(AppInfo.name == "Liftbook")
    }
}
