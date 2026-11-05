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
    var unit: WeightUnit = .kilograms

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
    }
}

/// One editable set in the live workout.
struct SetRow: View {
    let set: WorkoutSet
    let number: Int
    /// "1", "2"… for normal sets, or the kind's tag ("W", "D", "F").
    let label: String
    let type: ExerciseType
    /// Prefix for accessibility identifiers, e.g. "live.exercise.0.set.1".
    let identifier: String
    var unit: WeightUnit = .kilograms

    var body: some View {
        HStack(spacing: 8) {
            SetKindMenu(set: set, label: label)
                .frame(width: SetColumns.number)
                .accessibilityIdentifier("\(identifier).kind")

            ForEach(type.fieldSpecs, id: \.self) { spec in
                SetValueField(set: set, spec: spec, unit: unit)
                    .accessibilityIdentifier("\(identifier).\(spec.field.rawValue)")
            }

            RPEMenu(set: set)
                .frame(width: SetColumns.rpe)
                .accessibilityIdentifier("\(identifier).rpe")

            Button {
                set.toggleCompleted(for: type)
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
        .listRowBackground(set.isCompleted ? Color.accentColor.opacity(0.14) : nil)
    }
}

/// A text field that edits one value of a set. Keeps its own text so partial
/// input like "62." isn't reformatted while typing.
private struct SetValueField: View {
    let set: WorkoutSet
    let spec: ExerciseType.FieldSpec
    let unit: WeightUnit
    @State private var text = ""

    var body: some View {
        TextField(spec.placeholder, text: $text)
            .keyboardType(spec.field.keyboard)
            .multilineTextAlignment(.center)
            .monospacedDigit()
            .padding(.vertical, 7)
            .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 8))
            .accessibilityLabel(spec.label)
            .onAppear { text = set.measurement.inputText(for: spec.field, unit: unit) }
            .onChange(of: text) { _, newValue in
                var measurement = set.measurement
                measurement.setInput(newValue, for: spec.field, unit: unit)
                if measurement != set.measurement { set.measurement = measurement }
            }
    }
}

/// Shows the set's number or kind tag; tapping it changes the kind.
private struct SetKindMenu: View {
    let set: WorkoutSet
    let label: String

    var body: some View {
        Menu {
            Section("Set Type") {
                ForEach(SetKind.allCases) { kind in
                    Button {
                        set.kind = kind
                    } label: {
                        if set.kind == kind {
                            Label(kind.displayName, systemImage: "checkmark")
                        } else {
                            Text(kind.displayName)
                        }
                    }
                }
            }
        } label: {
            Text(label)
                .font(.subheadline.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(set.kind == .normal ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary))
                .frame(width: 26, height: 30)
                .background(set.kind.tint.opacity(set.kind == .normal ? 0 : 0.28),
                            in: RoundedRectangle(cornerRadius: 7))
        }
        // Menus tint their label with the accent color; keep the tag readable.
        .tint(set.kind == .normal ? Color.secondary : Color.primary)
        .accessibilityLabel("\(set.kind.displayName): \(label)")
    }
}

extension SetKind {
    /// Background tint for the set's tag.
    var tint: Color {
        switch self {
        case .normal: .clear
        case .warmUp: .orange
        case .drop: .indigo
        case .failure: .red
        }
    }
}

/// Picks the set's rate of perceived exertion.
private struct RPEMenu: View {
    let set: WorkoutSet

    var body: some View {
        Menu {
            Button("No RPE") { set.rpe = nil }
            ForEach(SetInput.rpeOptions.reversed(), id: \.self) { value in
                Button("RPE \(SetMeasurement.decimal(value))") { set.rpe = value }
            }
        } label: {
            Text(set.rpe.map(SetMeasurement.decimal) ?? "–")
                .monospacedDigit()
                .frame(maxWidth: .infinity, minHeight: 34)
                .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 8))
        }
        .accessibilityLabel(set.rpe.map { "RPE \(SetMeasurement.decimal($0))" } ?? "RPE not set")
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
