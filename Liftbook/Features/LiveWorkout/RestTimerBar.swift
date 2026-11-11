import SwiftUI

/// Countdown shown at the bottom of the live workout while resting.
struct RestTimerBar: View {
    let session: WorkoutSession
    let exerciseName: String?

    var body: some View {
        // Timer-style Text and ProgressView count down on their own, without
        // re-rendering every second (which closed menus and dropped focus).
        let end = session.restEndsAt ?? .now
        let begin = end.addingTimeInterval(-max(session.restDuration, 1))
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(exerciseName.map { "Rest after \($0)" } ?? "Rest")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    Text(timerInterval: Date.now...max(end, .now), countsDown: true)
                        .font(.title2.weight(.semibold))
                        .monospacedDigit()
                        // Seconds left when last drawn; refreshed on every change.
                        .accessibilityValue("\(Int((session.restRemaining() ?? 0).rounded()))")
                        .accessibilityIdentifier("rest.remaining")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                controls
                    .fixedSize()
            }
            ProgressView(timerInterval: begin...max(end, begin), countsDown: false) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            }
            .accessibilityHidden(true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        // Thick enough that the set rows scrolling underneath don't show through.
        .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 20))
        // An edge, so it stands apart from same-gray cards in dark mode.
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Color(.separator)))
        .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
        .accessibilityElement(children: .contain)
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
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
        .controlSize(.small)
        .lineLimit(1)
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
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.primary)
                .padding(.horizontal, 14)
                .frame(minHeight: 34)
                .background(.fill.tertiary, in: Capsule())
        }
        .accessibilityLabel("Rest: \(RestTimer.label(seconds: current))")
    }
}
