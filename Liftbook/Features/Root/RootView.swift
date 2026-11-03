import SwiftUI

enum AppInfo {
    static let name = "Liftbook"
}

struct RootView: View {
    var body: some View {
        Text(AppInfo.name)
            .font(.largeTitle.bold())
            .accessibilityIdentifier("root.title")
    }
}

#Preview {
    RootView()
}
