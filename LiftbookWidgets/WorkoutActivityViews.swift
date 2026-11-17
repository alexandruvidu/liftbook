import AppIntents
import SwiftUI
import WidgetKit

/// Resting: the countdown, +30 s and Skip, and what comes next. Otherwise:
/// the next set and Log Set, or a way into the app when it can't be logged here.
struct NextStepView: View {
    let state: WorkoutActivityAttributes.ContentState
    let isStale: Bool
    let compact: Bool

    var body: some View {
        if let rest = state.rest(isStale: isStale) {
            restView(rest)
        } else if let exercise = state.exerciseName {
            setView(exercise)
        } else {
            HStack(spacing: 12) {
                Label("All sets done", systemImage: "checkmark.seal.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(LiftbookBrand.accent)
                Spacer(minLength: 8)
                Link(destination: LiftbookBrand.workoutURL) {
                    Label("Finish", systemImage: "flag.checkered")
                }
                .buttonStyle(.borderedProminent)
                .tint(LiftbookBrand.accent)
                .foregroundStyle(LiftbookBrand.onAccent)
            }
        }
    }

    private func restView(_ rest: ClosedRange<Date>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Rest")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(timerInterval: rest, countsDown: true)
                        .font(compact ? .title3.weight(.semibold) : .title.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(LiftbookBrand.accent)
                }
                Spacer(minLength: 8)
                Button(intent: AddRestIntent()) {
                    Text("+30s")
                        .monospacedDigit()
                }
                .buttonStyle(.bordered)
                .tint(LiftbookBrand.accent)
                .accessibilityLabel("Add 30 Seconds")
                Button(intent: SkipRestIntent()) {
                    Label("Skip", systemImage: "forward.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(LiftbookBrand.accent)
                .foregroundStyle(LiftbookBrand.onAccent)
            }
            ProgressView(timerInterval: rest, countsDown: true) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            }
            .tint(LiftbookBrand.accent)
            if let exercise = state.exerciseName {
                Text("Next: \(exercise) · \(state.setLine)")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    private func setView(_ exercise: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise)
                    .font(compact ? .subheadline.weight(.semibold) : .headline)
                    .lineLimit(1)
                Text(state.setLine)
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            if state.canLog {
                Button(intent: LogNextSetIntent()) {
                    Label("Log Set", systemImage: "checkmark")
                }
                .buttonStyle(.borderedProminent)
                .tint(LiftbookBrand.accent)
                .foregroundStyle(LiftbookBrand.onAccent)
            } else {
                // No values typed in or from last time: they're entered in the app.
                Link(destination: LiftbookBrand.workoutURL) {
                    Label("Enter in App", systemImage: "square.and.pencil")
                }
                .buttonStyle(.bordered)
                .tint(LiftbookBrand.accent)
            }
        }
    }
}
