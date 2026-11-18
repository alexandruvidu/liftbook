import SwiftUI

/// One value of a set, typed on the screen's set keypad (`SetKeypadSession`).
/// Keeps its own text so partial input like "62." isn't reformatted while typing.
struct SetValueField: View {
    let set: WorkoutSet
    let spec: ExerciseType.FieldSpec
    let unit: WeightUnit
    /// Last time's value, shown in the empty field.
    let placeholder: String?
    /// e.g. "Set 2 weight", so VoiceOver says which set a field belongs to.
    let accessibilityName: String
    /// e.g. "live.exercise.0.set.1.weight", for UI tests.
    let identifier: String
    /// Where the field sits for the keypad's Next: exercise, set and field position.
    let order: [Int]
    @State private var text = ""
    @Environment(SetKeypadSession.self) private var keypad: SetKeypadSession?
    @Environment(\.revealField) private var revealField

    private var isFocused: Bool { keypad?.focused == order }
    private var lastTime: String? { placeholder.flatMap { $0.isEmpty ? nil : $0 } }

    var body: some View {
        HStack(spacing: 1) {
            Text(text.isEmpty && !isFocused ? (lastTime ?? spec.placeholder) : text)
                .foregroundStyle(text.isEmpty ? (lastTime == nil ? .tertiary : .secondary) : .primary)
            if isFocused {
                // The caret.
                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: 2, height: 20)
            }
        }
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .frame(maxWidth: .infinity, minHeight: 22)
        .padding(.vertical, 7)
        .background(.fill.tertiary, in: .card(minimum: 8))
        .overlay {
            if isFocused {
                RoundedRectangle(cornerRadius: 8).strokeBorder(Color.accentColor, lineWidth: 2)
            }
        }
        .contentShape(.rect)
        .onTapGesture { keypad?.focus(order) }
        .accessibilityElement()
        .accessibilityLabel(accessibilityName)
        .accessibilityValue(text.isEmpty ? (lastTime.map { "Empty, last time \($0)" } ?? "Empty") : text)
        .accessibilityAddTraits(isFocused ? [.isButton, .isSelected] : .isButton)
        .accessibilityAction { keypad?.focus(order) }
        .accessibilityIdentifier(identifier)
        .id(revealID)
        .onDisappear { keypad?.unregister(order) }
        // Reordering exercises or sets moves the field.
        .onChange(of: order) { old, _ in
            keypad?.unregister(old)
            register()
        }
        .onChange(of: isFocused) { _, focused in
            // Leaving the field tidies leftovers like "62," into "62".
            guard focused else { return text = set.measurement.inputText(for: spec.field, unit: unit) }
            guard let revealField else { return }
            Task {
                // Once the keypad is up, so the visible area is known.
                try? await Task.sleep(for: .milliseconds(300))
                revealField(revealID)
            }
        }
        .onAppear {
            text = set.measurement.inputText(for: spec.field, unit: unit)
            register()
        }
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

    private func register() {
        let field = spec.field
        keypad?.register(.init(separator: SetKeypad.separator(for: field),
                               stepLabel: SetKeypad.stepLabel(for: field, unit: unit)) { key in
            apply(key)
        }, at: order)
    }

    /// A key typed while this field is focused.
    private func apply(_ key: SetKeypadKey) {
        switch key {
        case .digit(let digit): text += "\(digit)"
        case .separator(let separator):
            // One decimal point; up to two colons ("1:02:03").
            let limit = separator == ":" ? 2 : 1
            if text.filter({ String($0) == separator }).count < limit { text += separator }
        case .delete: if !text.isEmpty { text.removeLast() }
        case .clear: text = ""
        case .step(let up):
            text = SetKeypad.stepped(text, placeholder: lastTime, field: spec.field, unit: unit, up: up)
        case .next, .done: break
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
