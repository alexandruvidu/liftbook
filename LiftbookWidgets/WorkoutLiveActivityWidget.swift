import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

/// The workout in progress on the Lock Screen and in the Dynamic Island:
/// the next set with a button to log it, or the rest countdown with Skip.
struct WorkoutLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            LockScreenView(state: context.state)
                .padding(16)
                // Always the dark card: left to the system, the first frame
                // could draw light-mode (black) text on the dark background.
                .environment(\.colorScheme, .dark)
                .activityBackgroundTint(Color.black.opacity(0.7))
                .activitySystemActionForegroundColor(.white)
                .widgetURL(LiftbookBrand.workoutURL)
        } dynamicIsland: { context in
            let state = context.state
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(state.workoutName, systemImage: "figure.strengthtraining.traditional")
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                        .foregroundStyle(LiftbookBrand.accent)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(state.completedSets)/\(state.totalSets) sets")
                        .font(.caption.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    NextStepView(state: state, compact: true)
                }
            } compactLeading: {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundStyle(LiftbookBrand.accent)
            } compactTrailing: {
                if let end = state.restEndsAt, end > .now {
                    Text(timerInterval: Date.now...end, countsDown: true)
                        .monospacedDigit()
                        .frame(maxWidth: 44)
                        .foregroundStyle(LiftbookBrand.accent)
                } else {
                    Text("\(state.completedSets)/\(state.totalSets)")
                        .monospacedDigit()
                }
            } minimal: {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundStyle(LiftbookBrand.accent)
            }
            .widgetURL(LiftbookBrand.workoutURL)
            .keylineTint(LiftbookBrand.accent)
        }
    }
}

private struct LockScreenView: View {
    let state: WorkoutActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(state.workoutName, systemImage: "figure.strengthtraining.traditional")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(LiftbookBrand.accent)
                    .lineLimit(1)
                Spacer()
                // A timer interval keeps "12:34"; `style: .timer` turned into "1 minute" here.
                Text(timerInterval: state.startedAt...Date.distantFuture, countsDown: false)
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 80, alignment: .trailing)
            }
            NextStepView(state: state, compact: false)
            ProgressView(value: Double(state.completedSets), total: Double(max(state.totalSets, 1))) {
                EmptyView()
            } currentValueLabel: {
                Text("\(state.completedSets) of \(state.totalSets) sets")
            }
            .font(.caption)
            .tint(LiftbookBrand.accent)
        }
    }
}

/// Resting: the countdown and Skip. Otherwise: the next set and Log Set.
private struct NextStepView: View {
    let state: WorkoutActivityAttributes.ContentState
    let compact: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            if let end = state.restEndsAt, let start = state.restStartedAt, end > .now {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Rest")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(timerInterval: Date.now...end, countsDown: true)
                        .font(compact ? .title3.weight(.semibold) : .title.weight(.semibold))
                        .monospacedDigit()
                    ProgressView(timerInterval: start...end, countsDown: true) {
                        EmptyView()
                    } currentValueLabel: {
                        EmptyView()
                    }
                    .tint(LiftbookBrand.accent)
                }
                Spacer(minLength: 8)
                Button(intent: SkipRestIntent()) {
                    Label("Skip", systemImage: "forward.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(LiftbookBrand.accent)
                .foregroundStyle(LiftbookBrand.onAccent)
            } else if let exercise = state.exerciseName {
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise)
                        .font(compact ? .subheadline.weight(.semibold) : .headline)
                        .lineLimit(1)
                    Text(state.target.isEmpty ? state.setLabel : "\(state.setLabel) · \(state.target)")
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
                    Text("Open to enter")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Label("All sets done. Finish in the app.", systemImage: "checkmark.seal.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(LiftbookBrand.accent)
            }
        }
    }
}
