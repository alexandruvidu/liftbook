import SwiftUI

struct ProgressHomeView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("Nothing to chart yet", systemImage: AppTab.progress.systemImage)
            } description: {
                Text("Log a few workouts and your strength trends, records and weekly volume will show up here.")
            }
            .accessibilityIdentifier("progress.empty")
            .navigationTitle(AppTab.progress.title)
        }
    }
}

#Preview {
    ProgressHomeView()
}
