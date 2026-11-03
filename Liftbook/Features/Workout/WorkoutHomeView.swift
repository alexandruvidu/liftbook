import SwiftUI

struct WorkoutHomeView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("Ready when you are", systemImage: AppTab.workout.systemImage)
            } description: {
                Text("Start a blank session or pick one of your routines. Your sets are saved on this phone as you go.")
            }
            .accessibilityIdentifier("workout.empty")
            .navigationTitle(AppTab.workout.title)
        }
    }
}

#Preview {
    WorkoutHomeView()
}
