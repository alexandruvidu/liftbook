import ActivityKit
import SwiftUI
import WidgetKit

/// The rest countdown on the Lock Screen and in the Dynamic Island.
struct RestLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RestActivityAttributes.self) { context in
            RestLockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("Rest", systemImage: "timer")
                        .font(.headline)
                        .foregroundStyle(WidgetColors.accent)
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    RestCountdown(state: context.state, isStale: context.isStale)
                        .font(.title2.weight(.semibold))
                        .multilineTextAlignment(.trailing)
                        .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Next: \(context.state.exerciseName)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        RestProgress(state: context.state)
                    }
                    .padding(.horizontal, 4)
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .foregroundStyle(WidgetColors.accent)
            } compactTrailing: {
                RestCountdown(state: context.state, isStale: context.isStale)
                    .frame(maxWidth: 48)
                    .multilineTextAlignment(.trailing)
            } minimal: {
                Image(systemName: "timer")
                    .foregroundStyle(WidgetColors.accent)
            }
            .keylineTint(WidgetColors.accent)
        }
    }
}

/// Lock Screen and Notification Center banner.
private struct RestLockScreenView: View {
    let context: ActivityViewContext<RestActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Label(context.isStale ? "Rest is over" : "Resting", systemImage: "timer")
                        .font(.headline)
                        .foregroundStyle(WidgetColors.accent)
                    Text("\(context.attributes.workoutName) · \(context.state.exerciseName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                RestCountdown(state: context.state, isStale: context.isStale)
                    .font(.largeTitle.weight(.semibold))
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 130, alignment: .trailing)
            }
            RestProgress(state: context.state)
        }
        .padding(16)
        .activitySystemActionForegroundColor(WidgetColors.accent)
    }
}

/// Seconds left, counting down on its own without app updates.
private struct RestCountdown: View {
    let state: RestActivityAttributes.ContentState
    let isStale: Bool

    var body: some View {
        if isStale {
            Text("Go")
                .foregroundStyle(WidgetColors.accent)
        } else {
            Text(timerInterval: state.startedAt...state.endsAt, countsDown: true)
                .monospacedDigit()
        }
    }
}

private struct RestProgress: View {
    let state: RestActivityAttributes.ContentState

    var body: some View {
        ProgressView(timerInterval: state.startedAt...state.endsAt, countsDown: false) {
            EmptyView()
        } currentValueLabel: {
            EmptyView()
        }
        .tint(WidgetColors.accent)
    }
}

/// The app's accent (teal in light mode, mint in dark). The extension can't
/// read the app's asset catalog, so the values are repeated here.
enum WidgetColors {
    static let accent = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0x5E / 255, green: 0xE0 / 255, blue: 0xB5 / 255, alpha: 1)
            : UIColor(red: 0x0B / 255, green: 0x7A / 255, blue: 0x6D / 255, alpha: 1)
    })
}
