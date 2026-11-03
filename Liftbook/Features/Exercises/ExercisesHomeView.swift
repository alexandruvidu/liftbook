import SwiftUI

struct ExercisesHomeView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("Exercise library", systemImage: AppTab.exercises.systemImage)
            } description: {
                Text("Browse movements by muscle and equipment, or add your own.")
            }
            .accessibilityIdentifier("exercises.empty")
            .navigationTitle(AppTab.exercises.title)
        }
    }
}

#Preview {
    ExercisesHomeView()
}
