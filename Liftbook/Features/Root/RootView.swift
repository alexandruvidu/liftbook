import SwiftData
import SwiftUI

struct RootView: View {
    @State private var selection: AppTab = .home
    @State private var starter = WorkoutStartController()
    @State private var isQuickStarting = false
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<WorkoutSession> { $0.endedAt == nil }, sort: \WorkoutSession.startedAt)
    private var active: [WorkoutSession]

    var body: some View {
        TabView(selection: $selection) {
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
        }
        // Above the tab bar on every tab: Start Workout, or the workout in
        // progress while one runs.
        .workoutAccessory(session: active.last) {
            isQuickStarting = true
        } open: {
            starter.resume($0)
        }
        .tabBarMinimizeBehavior(.onScrollDown)
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
        // The Live Activity follows the workout in progress: it starts with
        // one (also one left from last launch) and ends when it's finished.
        .onChange(of: active.last?.sessionID, initial: true) {
            WorkoutLiveActivity.sync(active.last, in: modelContext)
        }
        // "Start Workout" from Siri or Shortcuts.
        .onChange(of: ShortcutRequests.shared.start, initial: true) { _, request in
            guard let request else { return }
            ShortcutRequests.shared.start = nil
            switch request {
            case .empty:
                starter.start(.empty)
            case .routine(let id):
                let routines = (try? modelContext.fetch(FetchDescriptor<Routine>(predicate: #Predicate { $0.routineID == id }))) ?? []
                starter.start(routines.first.map(WorkoutStartRequest.routine) ?? .empty)
            }
        }
        // Tapping the Live Activity opens the workout.
        .onOpenURL { url in
            if url == LiftbookBrand.workoutURL, let session = active.last {
                starter.resume(session)
            }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(Persistence.makeContainer(inMemory: true))
}
