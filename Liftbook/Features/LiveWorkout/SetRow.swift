import SwiftUI

/// Column widths shared by the set rows and their header.
private enum SetColumns {
    static let number: CGFloat = 26
    static let rpe: CGFloat = 44
    static let check: CGFloat = 32
}

/// Column titles above an exercise's sets.
struct SetHeaderRow: View {
    let type: ExerciseType
    @AppStorage(WeightUnit.storageKey) private var unit: WeightUnit = .kilograms

    var body: some View {
        HStack(spacing: 8) {
            Text("Set").frame(width: SetColumns.number)
            ForEach(type.fieldSpecs, id: \.self) { spec in
                Text(spec.columnTitle(unit: unit)).frame(maxWidth: .infinity)
            }
            Text("RPE").frame(width: SetColumns.rpe)
            Image(systemName: "checkmark").frame(width: SetColumns.check)
                .accessibilityHidden(true)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .textCase(.uppercase)
        .dynamicTypeSize(...SetRow.largestTextSize)
    }
}

/// One editable set in the live workout.
struct SetRow: View {
    /// The set grid has four columns side by side; beyond this size the
    /// numbers no longer fit, so text stops growing here.
    static let largestTextSize = DynamicTypeSize.accessibility2

    let set: WorkoutSet
    let number: Int
    /// "1", "2"… for normal sets, or the kind's tag ("W", "D", "F").
    let label: String
    let type: ExerciseType
    /// Prefix for accessibility identifiers, e.g. "live.exercise.0.set.1".
    let identifier: String
    /// The set at the same position last time, if any.
    var previous: SetMeasurement?
    @AppStorage(WeightUnit.storageKey) private var unit: WeightUnit = .kilograms
    /// Called when the set is checked off (not when un-checked).
    var onCompleted: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            inputs
            if let previous {
                Button {
                    set.measurement = previous
                } label: {
                    Label("Last time: \(previous.formatted(for: type, unit: unit))",
                          systemImage: "clock.arrow.circlepath")
                        .font(.caption)
                        // Buttons tint their label; keep this a quiet gray.
                        .foregroundStyle(Color.secondary)
                        .padding(.leading, SetColumns.number + 8)
                }
                .buttonStyle(.borderless)
                .disabled(set.isCompleted)
                .accessibilityLabel("Last time: \(previous.formatted(for: type, unit: unit)). Tap to copy.")
                .accessibilityIdentifier("\(identifier).previous")
            }
        }
        .listRowBackground(set.isCompleted ? Color.accentColor.opacity(0.14) : nil)
        .dynamicTypeSize(...Self.largestTextSize)
    }

    private var inputs: some View {
        HStack(spacing: 8) {
            SetKindMenu(set: set, label: label)
                .frame(width: SetColumns.number)
                .accessibilityIdentifier("\(identifier).kind")

            ForEach(type.fieldSpecs, id: \.self) { spec in
                SetValueField(set: set, spec: spec, unit: unit,
                              accessibilityName: "Set \(number) \(spec.label.lowercased())")
                    .accessibilityIdentifier("\(identifier).\(spec.field.rawValue)")
            }

            RPEMenu(set: set)
                .frame(width: SetColumns.rpe)
                .accessibilityIdentifier("\(identifier).rpe")

            Button {
                if set.toggleCompleted(for: type) { onCompleted() }
            } label: {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(set.isCompleted ? Color.accentColor : Color.secondary)
                    .frame(width: SetColumns.check, height: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .disabled(!set.isCompleted && !set.measurement.isComplete(for: type))
            .accessibilityLabel(set.isCompleted ? "Set \(number) done" : "Mark set \(number) done")
            .accessibilityIdentifier("\(identifier).check")
            .sensoryFeedback(.success, trigger: set.isCompleted) { _, done in done }
        }
    }
}

/// A text field that edits one value of a set. Keeps its own text so partial
/// input like "62." isn't reformatted while typing.
private struct SetValueField: View {
    let set: WorkoutSet
    let spec: ExerciseType.FieldSpec
    let unit: WeightUnit
    /// e.g. "Set 2 weight", so VoiceOver says which set a field belongs to.
    let accessibilityName: String
    @State private var text = ""

    var body: some View {
        TextField(spec.placeholder, text: $text)
            .keyboardType(spec.field.keyboard)
            .multilineTextAlignment(.center)
            .monospacedDigit()
            .padding(.vertical, 7)
            .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 8))
            .accessibilityLabel(accessibilityName)
            .onAppear { text = set.measurement.inputText(for: spec.field, unit: unit) }
            .onChange(of: text) { _, newValue in
                var measurement = set.measurement
                measurement.setInput(newValue, for: spec.field, unit: unit)
                if measurement != set.measurement { set.measurement = measurement }
            }
            // Show values set from outside the field, e.g. copied from last time.
            .onChange(of: set.measurement) { _, measurement in
                var typed = measurement
                typed.setInput(text, for: spec.field, unit: unit)
                if typed != measurement { text = measurement.inputText(for: spec.field, unit: unit) }
            }
    }
}

private extension SetField {
    var keyboard: UIKeyboardType {
        switch self {
        case .weight, .distance: .decimalPad
        case .reps: .numberPad
        case .duration: .numbersAndPunctuation
        }
    }
}

extension ExerciseType.FieldSpec {
    /// Short column title, e.g. "kg", "Reps", "Time".
    func columnTitle(unit: WeightUnit) -> String {
        switch field {
        case .weight:
            switch label {
            case "Assistance": "Assist"
            case "Added weight": "+\(unit.symbol)"
            default: unit.symbol
            }
        case .reps: "Reps"
        case .duration: "Time"
        case .distance: unit.distanceSymbol
        }
    }

    /// Hint shown in an empty field.
    var placeholder: String {
        switch field {
        case .weight: isOptional ? "0" : "–"
        case .reps: "–"
        case .duration: "m:ss"
        case .distance: "–"
        }
    }
}
