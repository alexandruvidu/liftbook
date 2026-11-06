import SwiftData
import SwiftUI

struct RootView: View {
    @State private var selection: AppTab = .home
    @State private var starter = WorkoutStartController()
    @State private var isQuickStarting = false
    @Query(filter: #Predicate<WorkoutSession> { $0.endedAt == nil }, sort: \WorkoutSession.startedAt)
    private var active: [WorkoutSession]

    /// Selecting the start tab opens the quick-start sheet (or the running
    /// workout) and stays on the current tab.
    private var tabSelection: Binding<AppTab> {
        Binding(get: { selection }, set: { tab in
            guard tab == .start else { return selection = tab }
            if let session = active.last {
                starter.resume(session)
            } else {
                isQuickStarting = true
            }
        })
    }

    var body: some View {
        TabView(selection: tabSelection) {
            Tab(AppTab.home.title, systemImage: AppTab.home.systemImage, value: AppTab.home) {
                WorkoutHomeView()
            }
            Tab(AppTab.exercises.title, systemImage: AppTab.exercises.systemImage, value: AppTab.exercises) {
                ExercisesHomeView()
            }
            Tab(AppTab.activity.title, systemImage: AppTab.activity.systemImage, value: AppTab.activity) {
                ActivityHomeView()
            }
            Tab(AppTab.profile.title, systemImage: AppTab.profile.systemImage, value: AppTab.profile) {
                ProfileHomeView()
            }
            // The search role puts this in its own round button at the end of
            // the iOS 26 tab bar; on iOS 18 it's a normal tab item.
            Tab(AppTab.start.title, systemImage: AppTab.start.systemImage, value: AppTab.start, role: .search) {
                Color.clear
            }
        }
        .workoutRunningAccessory(session: active.last) { starter.resume($0) }
        // Set explicitly: some system views (e.g. the photo picker button)
        // otherwise drop the asset-catalog accent from the tab bar.
        .tint(Color.accentColor)
        .environment(starter)
        .sheet(isPresented: $isQuickStarting) {
            QuickStartSheet { request in
                isQuickStarting = false
                starter.startAfterDismiss(request)
            }
        }
        .workoutStarting(starter, offersLeftover: true)
    }
}

#Preview {
    RootView()
        .modelContainer(Persistence.makeContainer(inMemory: true))
}
