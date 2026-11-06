import SwiftUI

/// "Next: 62.5 kg × 8" from last time's sets, with a button to fill the
/// empty sets and a menu for the exercise's rep range.
struct ProgressionRow: View {
    let exercise: WorkoutExercise
    let info: LibraryExercise
    let lastWorkingSets: [SetMeasurement]
    /// Prefix for accessibility identifiers, e.g. "live.exercise.0".
    let identifier: String

    @AppStorage private var rangeText: String
    @AppStorage(WeightUnit.storageKey) private var unit: WeightUnit = .kilograms

    init(exercise: WorkoutExercise, info: LibraryExercise, lastWorkingSets: [SetMeasurement], identifier: String) {
        self.exercise = exercise
        self.info = info
        self.lastWorkingSets = lastWorkingSets
        self.identifier = identifier
        _rangeText = AppStorage(wrappedValue: "", Progression.rangeKey(info.id), store: AppSettings.store)
    }

    private var range: ClosedRange<Int> { Progression.decode(rangeText) ?? Progression.defaultRange }

    var body: some View {
        if let suggestion = Progression.suggestion(lastSets: lastWorkingSets, exercise: info, range: range, unit: unit) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: suggestion.increasesWeight ? "arrow.up.circle.fill" : "target")
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Next: \(target(suggestion))")
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                    Text(suggestion.reason)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("\(identifier).suggestion")
                Spacer(minLength: 4)
                Menu {
                    Section("Rep Range") {
                        ForEach(Progression.ranges, id: \.self) { option in
                            Button {
                                rangeText = Progression.encode(option)
                            } label: {
                                if option == range {
                                    Label("\(option.lowerBound)–\(option.upperBound) reps", systemImage: "checkmark")
                                } else {
                                    Text("\(option.lowerBound)–\(option.upperBound) reps")
                                }
                            }
                        }
                    }
                } label: {
                    Text("\(range.lowerBound)–\(range.upperBound)")
                        .font(.caption.weight(.semibold))
                        .monospacedDigit()
                }
                .accessibilityLabel("Rep range \(range.lowerBound) to \(range.upperBound)")
                .accessibilityIdentifier("\(identifier).range")
                Button("Use") { exercise.apply(suggestion, type: info.type) }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .accessibilityIdentifier("\(identifier).suggestion.apply")
            }
            .buttonStyle(.borderless)
        }
    }

    private func target(_ suggestion: Progression.Suggestion) -> String {
        info.type == .weightAndReps
            ? "\(SetMeasurement.number(suggestion.weight, unit: unit)) \(unit.symbol) × \(suggestion.reps)"
            : "\(suggestion.reps) reps"
    }
}
