import SwiftData
import SwiftUI

/// "Start Empty Workout" or, while a workout is running, a resume banner.
struct StartWorkoutSection: View {
    let starter: WorkoutStartController
    @Query(filter: #Predicate<WorkoutSession> { $0.endedAt == nil }, sort: \WorkoutSession.startedAt)
    private var active: [WorkoutSession]

    var body: some View {
        Section {
            if let session = active.last {
                Button {
                    starter.resume(session)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Workout in progress")
                                .font(.headline)
                            Text(session.name)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("Resume")
                            .font(.headline)
                            .foregroundStyle(.tint)
                    }
                }
                .foregroundStyle(.primary)
                .accessibilityIdentifier("workout.resume")
            } else {
                Button {
                    starter.start(.empty)
                } label: {
                    Label("Start Empty Workout", systemImage: "play.fill")
                        .font(.headline)
                        .foregroundStyle(Color.accentForeground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .accessibilityIdentifier("workout.startEmpty")
            }
        }
    }
}
