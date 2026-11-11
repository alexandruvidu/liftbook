import SwiftUI

/// A text field that edits one value of a set. Keeps its own text so partial
/// input like "62." isn't reformatted while typing.
struct SetValueField: View {
    let set: WorkoutSet
    let spec: ExerciseType.FieldSpec
    let unit: WeightUnit
    /// Last time's value, shown in the empty field.
    let placeholder: String?
    /// e.g. "Set 2 weight", so VoiceOver says which set a field belongs to.
    let accessibilityName: String
    @State private var text = ""
    @FocusState private var isFocused: Bool
    @Environment(\.revealField) private var revealField

    var body: some View {
        TextField(spec.placeholder, text: $text, prompt: placeholder.flatMap { $0.isEmpty ? nil : Text($0).foregroundStyle(.secondary) })
            .keyboardType(spec.field.keyboard)
            .multilineTextAlignment(.center)
            .monospacedDigit()
            .padding(.vertical, 7)
            .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 8))
            .accessibilityLabel(accessibilityName)
            .focused($isFocused)
            .id(revealID)
            .onChange(of: isFocused) { _, focused in
                guard focused, let revealField else { return }
                Task {
                    // Once the keyboard is up, so the visible area is known.
                    try? await Task.sleep(for: .milliseconds(350))
                    revealField(revealID)
                }
            }
            .onAppear { text = set.measurement.inputText(for: spec.field, unit: unit) }
            .onChange(of: text) { oldValue, newValue in
                // Refuse typos like 999999999 kg rather than storing them.
                if SetInput.exceedsMaximum(newValue, for: spec.field) {
                    text = oldValue
                    return
                }
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

    private var revealID: String { "\(ObjectIdentifier(set).hashValue).\(spec.field.rawValue)" }
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
