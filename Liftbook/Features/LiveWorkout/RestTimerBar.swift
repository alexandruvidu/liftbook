import SwiftUI

/// Countdown shown at the bottom of the live workout while resting.
struct RestTimerBar: View {
    let session: WorkoutSession
    let exerciseName: String?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = session.restRemaining(at: context.date) ?? 0
            VStack(spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Rest")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        Text(SetMeasurement.clock(remaining.rounded(.up)))
                            .font(.title2.weight(.semibold))
                            .monospacedDigit()
                            .contentTransition(.numericText(countsDown: true))
                            .accessibilityIdentifier("rest.remaining")
                    }
                    if let exerciseName {
                        Text("after \(exerciseName)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Spacer()
                    }
                    controls
                }
                ProgressView(value: session.restProgress(at: context.date))
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
        .accessibilityElement(children: .contain)
    }

    private var controls: some View {
        HStack(spacing: 8) {
            Button("-\(Int(RestTimer.step))s") { session.adjustRest(by: -RestTimer.step) }
                .accessibilityLabel("\(Int(RestTimer.step)) seconds less")
                .accessibilityIdentifier("rest.minus")
            Button("+\(Int(RestTimer.step))s") { session.adjustRest(by: RestTimer.step) }
                .accessibilityLabel("\(Int(RestTimer.step)) seconds more")
                .accessibilityIdentifier("rest.plus")
            Button("Skip") { session.stopRest() }
                .buttonStyle(.borderedProminent)
                .foregroundStyle(Color.accentForeground)
                .accessibilityIdentifier("rest.skip")
        }
        .buttonStyle(.bordered)
        .font(.subheadline.weight(.semibold))
        .monospacedDigit()
    }
}

/// Picks how long to rest after each set of an exercise.
struct RestSecondsMenu: View {
    let exercise: WorkoutExercise
    let defaultSeconds: Int

    var body: some View {
        let current = exercise.effectiveRestSeconds(default: defaultSeconds)
        Menu {
            Section("Rest After Each Set") {
                ForEach(RestTimer.options, id: \.self) { seconds in
                    Button {
                        exercise.restSeconds = seconds
                    } label: {
                        if seconds == current {
                            Label(RestTimer.label(seconds: seconds), systemImage: "checkmark")
                        } else {
                            Text(RestTimer.label(seconds: seconds))
                        }
                    }
                }
            }
        } label: {
            Label("Rest \(RestTimer.label(seconds: current))", systemImage: "timer")
                .font(.subheadline)
        }
        .accessibilityLabel("Rest: \(RestTimer.label(seconds: current))")
    }
}
