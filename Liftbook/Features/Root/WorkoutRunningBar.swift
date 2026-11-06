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
                    Text(session.name)
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
        .accessibilityLabel("Workout in progress: \(session.name). Open")
        .accessibilityIdentifier("runningBar")
    }
}

extension View {
    /// Shows the running workout above the tab bar: the iOS 26 bottom
    /// accessory where available, otherwise a bar inset above the tab bar.
    @ViewBuilder
    func workoutRunningAccessory(session: WorkoutSession?, open: @escaping (WorkoutSession) -> Void) -> some View {
        if #available(iOS 26.1, *) {
            tabViewBottomAccessory(isEnabled: session != nil) {
                if let session { WorkoutRunningBar(session: session) { open(session) } }
            }
        } else {
            modifier(RunningBarInset(session: session, open: open))
        }
    }
}

/// Fallback before iOS 26.1: the bar floats just above the tab bar.
private struct RunningBarInset: ViewModifier {
    let session: WorkoutSession?
    let open: (WorkoutSession) -> Void

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if let session {
                WorkoutRunningBar(session: session) { open(session) }
                    .padding(.vertical, 8)
                    .background(.regularMaterial, in: Capsule())
                    .padding(.horizontal, 16)
                    .padding(.bottom, 60)
            }
        }
    }
}
