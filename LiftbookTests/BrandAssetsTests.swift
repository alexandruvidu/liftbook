import Foundation
import Testing
import UIKit
@testable import Liftbook

/// Unit tests run hosted inside the app, so `Bundle.main` is Liftbook.app.
struct BrandAssetsTests {
    @Test func accentColorIsBundled() {
        #expect(UIColor(named: "AccentColor", in: .main, compatibleWith: nil) != nil)
    }

    @Test func accentColorDiffersBetweenLightAndDark() throws {
        let accent = try #require(UIColor(named: "AccentColor", in: .main, compatibleWith: nil))
        let light = accent.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        let dark = accent.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        #expect(light != dark)
    }

    @Test func appIconIsDeclaredInInfoPlist() throws {
        let icons = try #require(Bundle.main.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any])
        let primary = try #require(icons["CFBundlePrimaryIcon"] as? [String: Any])
        #expect(primary["CFBundleIconName"] as? String == "AppIcon")
    }
}
