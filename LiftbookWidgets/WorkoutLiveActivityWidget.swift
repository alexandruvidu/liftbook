import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

/// The workout in progress on the Lock Screen and in the Dynamic Island:
/// the next set with a button to log it, or the rest countdown with +30 s,
/// Skip and what comes next.
struct WorkoutLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            LockScreenView(state: context.state, isStale: context.isStale)
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
                    NextStepView(state: state, isStale: context.isStale, compact: true)
                }
            } compactLeading: {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundStyle(LiftbookBrand.accent)
            } compactTrailing: {
                if let rest = state.rest(isStale: context.isStale) {
                    Text(timerInterval: rest, countsDown: true)
                        .monospacedDigit()
                        .frame(maxWidth: 44)
                        .foregroundStyle(LiftbookBrand.accent)
                } else {
                    Text("\(state.completedSets)/\(state.totalSets)")
                        .monospacedDigit()
                }
            } minimal: {
                // Resting: a ring that empties as the rest runs out.
                if let rest = state.rest(isStale: context.isStale) {
                    ProgressView(timerInterval: rest, countsDown: true) {
                        EmptyView()
                    } currentValueLabel: {
                        EmptyView()
                    }
                    .progressViewStyle(.circular)
                    .tint(LiftbookBrand.accent)
                } else {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .foregroundStyle(LiftbookBrand.accent)
                }
            }
            .widgetURL(LiftbookBrand.workoutURL)
            .keylineTint(LiftbookBrand.accent)
        }
    }
}

private struct LockScreenView: View {
    let state: WorkoutActivityAttributes.ContentState
    let isStale: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(state.workoutName, systemImage: "figure.strengthtraining.traditional")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(LiftbookBrand.accent)
                    .lineLimit(1)
                Spacer()
                // The set count lives here, not in a bar: while resting, a second
                // bar under the rest countdown read as one.
                Text("\(state.completedSets)/\(state.totalSets) sets")
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .fixedSize()
                // A timer interval keeps "12:34"; `style: .timer` turned into "1 minute" here.
                Text(timerInterval: state.startedAt...Date.distantFuture, countsDown: false)
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 64, alignment: .trailing)
            }
            NextStepView(state: state, isStale: isStale, compact: false)
        }
    }
}
