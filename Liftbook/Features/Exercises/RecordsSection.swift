import SwiftData
import SwiftUI

/// An exercise's personal records across all finished workouts.
struct RecordsSection: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    let exercise: LibraryExercise
    var machine: MachineFilter = .all

    @Query(filter: #Predicate<WorkoutSession> { $0.endedAt != nil })
    private var sessions: [WorkoutSession]
    @AppStorage(WeightUnit.storageKey) private var unit: WeightUnit = .kilograms

    var body: some View {
        if !RecordKind.kinds(for: exercise.type).isEmpty {
            let records = PersonalRecords.records(for: exercise.id, type: exercise.type, machine: machine, in: sessions)
            Section("Personal Records") {
                if records.isEmpty {
                    Text("Finish a workout \(machine.emptyStateScope) to set your first records.")
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("exercise.records.empty")
                }
                ForEach(records, id: \.kind) { record in
                    VStack(alignment: .leading, spacing: 2) {
                        // Label above the value at accessibility sizes, where side
                        // by side split "Heaviest weight" mid-word.
                        let layout = typeSize.isAccessibilitySize
                            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
                            : AnyLayout(HStackLayout(alignment: .firstTextBaseline))
                        layout {
                            Label(record.kind.title, systemImage: "trophy")
                            if !typeSize.isAccessibilitySize { Spacer() }
                            Text(record.kind.formatted(record.value, unit: unit))
                                .font(.body.weight(.semibold))
                                .monospacedDigit()
                        }
                        Text("\(record.set.formatted(for: exercise.type, unit: unit)) · \(record.date.formatted(.dateTime.day().month(.abbreviated).year()))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: typeSize.isAccessibilitySize ? .leading : .trailing)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("exercise.record.\(record.kind.rawValue)")
                }
            }
        }
    }
}
