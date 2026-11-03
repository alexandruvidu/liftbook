import SwiftUI

struct RootView: View {
    @State private var selection: AppTab = .workout

    var body: some View {
        TabView(selection: $selection) {
            Tab(AppTab.workout.title, systemImage: AppTab.workout.systemImage, value: AppTab.workout) {
                WorkoutHomeView()
            }
            Tab(AppTab.history.title, systemImage: AppTab.history.systemImage, value: AppTab.history) {
                HistoryHomeView()
            }
            Tab(AppTab.exercises.title, systemImage: AppTab.exercises.systemImage, value: AppTab.exercises) {
                ExercisesHomeView()
            }
            Tab(AppTab.progress.title, systemImage: AppTab.progress.systemImage, value: AppTab.progress) {
                ProgressHomeView()
            }
            Tab(AppTab.profile.title, systemImage: AppTab.profile.systemImage, value: AppTab.profile) {
                ProfileHomeView()
            }
        }
    }
}

#Preview {
    RootView()
}
