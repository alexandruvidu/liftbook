import SwiftData
import SwiftUI

struct RootView: View {
    @State private var selection: AppTab = .home
    @State private var starter = WorkoutStartController()
    @State private var isQuickStarting = false
    /// The start button hides while typing: the overlay would otherwise ride
    /// up with the keyboard and cover the field's results.
    @State private var isKeyboardShown = false
    @Query(filter: #Predicate<WorkoutSession> { $0.endedAt == nil }, sort: \WorkoutSession.startedAt)
    private var active: [WorkoutSession]

    /// The floating start button: the running workout if there is one,
    /// otherwise the quick-start sheet.
    private func start() {
        if let session = active.last {
            starter.resume(session)
        } else {
            isQuickStarting = true
        }
    }

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
        // Floats just above the tab bar on Home only: on the other tabs it
        // covered cards and settings. While a workout runs, the bar above
        // the tabs takes its place.
        .overlay(alignment: .bottomTrailing) {
            if selection == .home && active.isEmpty && !isKeyboardShown {
                StartButton(action: start)
                    .padding(.trailing, 20)
                    .padding(.bottom, 66)
            }
        }
        // Room under every scrolling screen so the start button never
        // covers the last row.
        .contentMargins(.bottom, selection == .home && active.isEmpty ? 72 : 0, for: .scrollContent)
        .workoutRunningAccessory(session: active.last) { starter.resume($0) }
        .minimizesTabBarOnScroll()
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
        .task {
            for await _ in NotificationCenter.default.notifications(named: UIResponder.keyboardWillShowNotification) {
                isKeyboardShown = true
            }
        }
        .task {
            for await _ in NotificationCenter.default.notifications(named: UIResponder.keyboardWillHideNotification) {
                isKeyboardShown = false
            }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(Persistence.makeContainer(inMemory: true))
}
