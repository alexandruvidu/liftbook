import SwiftUI
import Testing
@testable import Liftbook

struct AppTabTests {
    @Test func tabsAreInExpectedOrder() {
        #expect(AppTab.allCases == [.home, .exercises, .activity, .profile, .start])
        #expect(AppTab.allCases.map(\.title) == ["Home", "Exercises", "Activity", "Profile", "Start"])
    }

    @Test func tabsHaveUniqueIDsAndIcons() {
        #expect(Set(AppTab.allCases.map(\.id)).count == AppTab.allCases.count)
        #expect(Set(AppTab.allCases.map(\.systemImage)).count == AppTab.allCases.count)
    }

    @Test func uiTestAppearanceParsing() {
        #expect(UITestOverrides.appearance(from: "dark") == .dark)
        #expect(UITestOverrides.appearance(from: "light") == .light)
        #expect(UITestOverrides.appearance(from: nil) == nil)
        #expect(UITestOverrides.appearance(from: "sepia") == nil)
    }
}
