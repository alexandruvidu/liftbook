import SwiftData
import SwiftUI

/// An exercise's personal records across all finished workouts.
struct RecordsSection: View {
    let exercise: LibraryExercise

    @Query(filter: #Predicate<WorkoutSession> { $0.endedAt != nil })
    private var sessions: [WorkoutSession]
    @AppStorage(WeightUnit.storageKey) private var unit: WeightUnit = .kilograms

    var body: some View {
        if !RecordKind.kinds(for: exercise.type).isEmpty {
            let records = PersonalRecords.records(for: exercise.id, type: exercise.type, in: sessions)
            Section("Personal Records") {
                if records.isEmpty {
                    Text("Finish a workout with this exercise to set your first records.")
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("exercise.records.empty")
                }
                ForEach(records, id: \.kind) { record in
                    LabeledContent {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(record.kind.formatted(record.value, unit: unit))
                                .font(.body.weight(.semibold))
                                .monospacedDigit()
                                .foregroundStyle(.primary)
                            Text("\(record.set.formatted(for: exercise.type, unit: unit)) · \(record.date.formatted(.dateTime.day().month(.abbreviated).year()))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } label: {
                        Label(record.kind.title, systemImage: "trophy")
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("exercise.record.\(record.kind.rawValue)")
                }
            }
        }
    }
}
