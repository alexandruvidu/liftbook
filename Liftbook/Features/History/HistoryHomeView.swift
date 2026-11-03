import SwiftUI

struct HistoryHomeView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("No sessions logged", systemImage: AppTab.history.systemImage)
            } description: {
                Text("Finished workouts land here, newest first, so you can look back at what you lifted.")
            }
            .accessibilityIdentifier("history.empty")
            .navigationTitle(AppTab.history.title)
        }
    }
}

#Preview {
    HistoryHomeView()
}
