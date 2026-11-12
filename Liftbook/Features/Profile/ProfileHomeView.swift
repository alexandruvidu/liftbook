import SwiftData
import SwiftUI

/// You at a glance, then rows into body tracking, photos, tools and data,
/// and the settings.
struct ProfileHomeView: View {
    @Query(filter: #Predicate<WorkoutSession> { $0.endedAt != nil }) private var sessions: [WorkoutSession]
    @AppStorage(WeeklyGoal.storageKey) private var weeklyGoal = WeeklyGoal.defaultGoal

    var body: some View {
        let goal = WeeklyGoal()
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 8) {
                        StatTile(title: "Workouts", value: "\(sessions.count)", identifier: "profile.total")
                        StatTile(title: "This week", value: "\(goal.workouts(inWeekOf: .now, sessions: sessions))",
                                 identifier: "profile.thisWeek")
                        StatTile(title: "Week streak", value: "\(goal.currentStreak(goal: weeklyGoal, sessions: sessions))",
                                 identifier: "profile.streak")
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                Section {
                    row("Body", subtitle: "Weight and measurements", systemImage: "figure", id: "profile.body") {
                        BodyMeasurementsView()
                    }
                    row("Photos", subtitle: "Progress pictures", systemImage: "photo.on.rectangle", id: "profile.photos") {
                        ProgressPhotosView()
                    }
                    row("Tools", subtitle: "Plates and warm-ups", systemImage: "wrench.and.screwdriver", id: "profile.tools") {
                        ToolsView()
                    }
                    row("Data", subtitle: "Export and import", systemImage: "arrow.up.arrow.down", id: "profile.data") {
                        DataTransferView()
                    }
                }

                SettingsSections()

                Section {
                    // Required by the RepDB free tier: a visible link in the app.
                    Link(destination: URL(string: "https://repdb.co")!) {
                        Label("Exercise data by RepDB (repdb.co)", systemImage: "info.circle")
                    }
                    .accessibilityIdentifier("profile.credits")
                } footer: {
                    Label("Everything you log stays on this iPhone.", systemImage: "lock.iphone")
                }
            }
            .navigationTitle(AppTab.profile.title)
        }
    }

    private func row<Destination: View>(_ title: String, subtitle: String, systemImage: String, id: String,
                                        @ViewBuilder destination: @escaping () -> Destination) -> some View {
        NavigationLink(destination: destination) {
            Label {
                Text(title)
                Text(subtitle)
            } icon: {
                Image(systemName: systemImage)
                    .foregroundStyle(.tint)
            }
        }
        .accessibilityIdentifier(id)
    }
}

/// The plate and warm-up calculators.
struct ToolsView: View {
    var body: some View {
        List {
            NavigationLink {
                PlateCalculatorView()
            } label: {
                Label("Plate Calculator", systemImage: "scalemass")
            }
            .accessibilityIdentifier("profile.plates")
            NavigationLink {
                WarmUpCalculatorView()
            } label: {
                Label("Warm-up Calculator", systemImage: "flame")
            }
            .accessibilityIdentifier("profile.warmup")
        }
        .navigationTitle("Tools")
    }
}

#Preview {
    ProfileHomeView()
        .modelContainer(Persistence.makeContainer(inMemory: true))
}
