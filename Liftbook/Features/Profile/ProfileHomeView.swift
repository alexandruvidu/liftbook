import SwiftData
import SwiftUI

/// You at a glance, then tiles into body tracking, photos, tools and data,
/// and one block of settings.
struct ProfileHomeView: View {
    @Query(filter: #Predicate<WorkoutSession> { $0.endedAt != nil }) private var sessions: [WorkoutSession]
    @AppStorage(WeeklyGoal.storageKey) private var weeklyGoal = WeeklyGoal.defaultGoal

    var body: some View {
        let goal = WeeklyGoal()
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        StatTile(title: "Workouts", value: "\(sessions.count)", identifier: "profile.total")
                        StatTile(title: "This week", value: "\(goal.workouts(inWeekOf: .now, sessions: sessions))",
                                 identifier: "profile.thisWeek")
                        StatTile(title: "Week streak", value: "\(goal.currentStreak(goal: weeklyGoal, sessions: sessions))",
                                 identifier: "profile.streak")
                    }

                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        tile("Body", subtitle: "Weight and measurements", systemImage: "figure", id: "profile.body") {
                            BodyMeasurementsView()
                        }
                        tile("Photos", subtitle: "Progress pictures", systemImage: "photo.on.rectangle", id: "profile.photos") {
                            ProgressPhotosView()
                        }
                        tile("Tools", subtitle: "Plates and warm-ups", systemImage: "wrench.and.screwdriver", id: "profile.tools") {
                            ToolsView()
                        }
                        tile("Data", subtitle: "Export and import", systemImage: "arrow.up.arrow.down", id: "profile.data") {
                            DataTransferView()
                        }
                    }

                    NavigationLink {
                        ExerciseImagesView()
                    } label: {
                        Block {
                            BlockHeader("Exercise Images", subtitle: "Download photos for the library",
                                        image: Image(systemName: "photo.stack")) {
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("profile.images")

                    SectionTitle("Settings")
                    SettingsBlock()

                    Label("Everything you log stays on this iPhone.", systemImage: "lock.iphone")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
                .padding(16)
            }
            .blockScreenBackground()
            .navigationTitle(AppTab.profile.title)
        }
    }

    private func tile<Destination: View>(_ title: String, subtitle: String, systemImage: String, id: String,
                                         @ViewBuilder destination: @escaping () -> Destination) -> some View {
        NavigationLink(destination: destination) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                        .lineLimit(2, reservesSpace: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
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
