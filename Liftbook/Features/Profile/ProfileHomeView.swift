import SwiftUI

struct ProfileHomeView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("Your profile", systemImage: AppTab.profile.systemImage)
            } description: {
                Text("Units, body measurements and app settings will live here. Everything stays on this device.")
            }
            .accessibilityIdentifier("profile.empty")
            .navigationTitle(AppTab.profile.title)
        }
    }
}

#Preview {
    ProfileHomeView()
}
