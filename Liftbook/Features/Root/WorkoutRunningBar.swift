import SwiftUI

/// "Back Day · 12:34": the workout in progress, tap to open it.
struct WorkoutRunningBar: View {
    let session: WorkoutSession
    let open: () -> Void

    var body: some View {
        Button(action: open) {
            HStack(spacing: 10) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 0) {
                    Text(session.displayName)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    // Ticks on its own without re-rendering the tab view.
                    Text(session.startedAt, style: .timer)
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.up")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Workout in progress: \(session.displayName). Open")
        .accessibilityIdentifier("runningBar")
    }
}

/// "Start Workout" in the bottom accessory while nothing is running.
/// Labelled, not a bare "+", so it isn't confused with the create buttons.
struct StartWorkoutBar: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Start Workout", systemImage: "play.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.tint)
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Start a workout")
        .accessibilityIdentifier("startButton")
    }
}

extension View {
    /// The tab bar's bottom accessory, like a mini player: the running
    /// workout if there is one, otherwise a button that starts one.
    func workoutAccessory(session: WorkoutSession?, start: @escaping () -> Void,
                          open: @escaping (WorkoutSession) -> Void) -> some View {
        tabViewBottomAccessory {
            if let session {
                WorkoutRunningBar(session: session) { open(session) }
            } else {
                StartWorkoutBar(action: start)
            }
        }
    }
}
