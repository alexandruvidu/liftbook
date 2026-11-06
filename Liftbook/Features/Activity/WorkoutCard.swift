import SwiftUI

/// One finished workout in Activity: name, when, totals and its exercises.
struct WorkoutCard: View {
    let session: WorkoutSession
    let catalog: ExerciseCatalog
    @AppStorage(WeightUnit.storageKey) private var unit: WeightUnit = .kilograms

    var body: some View {
        let summary = WorkoutSummary(session: session, history: []) { catalog.exercise(id: $0)?.type ?? .weightAndReps }
        Block {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.name)
                        .font(.headline)
                    Text("\(session.startedAt.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))) · \(SetMeasurement.clock(summary.duration))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 16) { stats(summary) }
                VStack(alignment: .leading, spacing: 4) { stats(summary) }
            }
            .font(.subheadline)
            .monospacedDigit()
            exerciseLines
        }
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func stats(_ summary: WorkoutSummary) -> some View {
        if summary.volume > 0 {
            stat("Volume", unit.volumeText(kilograms: summary.volume))
        }
        stat("Sets", "\(summary.setCount)")
    }

    private func stat(_ title: String, _ value: String) -> some View {
        Text("\(Text(title).foregroundStyle(.secondary)) \(value)")
    }

    private var exerciseLines: some View {
        let exercises = session.orderedExercises
        return VStack(alignment: .leading, spacing: 3) {
            ForEach(exercises.prefix(2), id: \.stableID) { exercise in
                Text(catalog.name(for: exercise.exerciseID))
                    .lineLimit(1)
            }
            if exercises.count > 2 {
                Text("+ \(exercises.count - 2) more")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.subheadline)
    }
}
