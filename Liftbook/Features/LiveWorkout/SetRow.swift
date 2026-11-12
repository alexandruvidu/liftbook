import SwiftUI

/// Column widths shared by the set rows and their header.
private enum SetColumns {
    static let number: CGFloat = 28
    static let last: CGFloat = 66
    static let rpe: CGFloat = 40
    static let check: CGFloat = 40
}

/// Column titles above an exercise's sets.
struct SetHeaderRow: View {
    let type: ExerciseType
    @AppStorage(WeightUnit.storageKey) private var unit: WeightUnit = .kilograms

    var body: some View {
        HStack(spacing: 8) {
            Text("Set").frame(width: SetColumns.number)
            Text("Last").frame(width: SetColumns.last)
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
        // Narrow columns: shrink titles rather than break them letter by letter.
        .lineLimit(1)
        .minimumScaleFactor(0.5)
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
    /// Removes the set; nil when it's the only one.
    var onRemove: (() -> Void)?
    @AppStorage(WeightUnit.storageKey) private var unit: WeightUnit = .kilograms
    /// Called when the set is checked off (not when un-checked).
    var onCompleted: () -> Void = {}

    var body: some View {
        HStack(spacing: 8) {
            SetKindMenu(set: set, label: label, onRemove: onRemove)
                .frame(width: SetColumns.number)
                .accessibilityIdentifier("\(identifier).kind")

            lastTime
                .frame(width: SetColumns.last)

            ForEach(type.fieldSpecs, id: \.self) { spec in
                SetValueField(set: set, spec: spec, unit: unit,
                              placeholder: previous.map { $0.inputText(for: spec.field, unit: unit) },
                              accessibilityName: "Set \(number) \(spec.label.lowercased())")
                    .accessibilityIdentifier("\(identifier).\(spec.field.rawValue)")
            }

            RPEPicker(set: set, number: number)
                .frame(width: SetColumns.rpe)
                .accessibilityIdentifier("\(identifier).rpe")

            checkButton
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(set.isCompleted ? Color.accentColor.opacity(0.14) : Color.clear,
                    in: RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, -6)
        .dynamicTypeSize(...Self.largestTextSize)
        .onChange(of: set.measurement) { set.uncheckIfIncomplete(for: type) }
    }

    /// Last time's values for this set; tapping copies them in.
    @ViewBuilder
    private var lastTime: some View {
        if let previous {
            Button {
                set.measurement = previous
            } label: {
                Text(previous.compactText(for: type, unit: unit))
                    .font(.subheadline)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    // Buttons tint their label; keep this a quiet gray.
                    .foregroundStyle(Color.secondary)
                    .frame(maxWidth: .infinity, minHeight: 36)
            }
            .buttonStyle(.borderless)
            .disabled(set.isCompleted)
            .accessibilityLabel("Last time: \(previous.formatted(for: type, unit: unit)). Tap to copy.")
            .accessibilityIdentifier("\(identifier).previous")
        } else {
            Text("–")
                .foregroundStyle(.tertiary)
                .accessibilityLabel("Nothing last time")
        }
    }

    private var checkButton: some View {
        let ready = set.measurement.filled(from: previous ?? SetMeasurement(), fields: type.fieldSpecs.map(\.field))
            .isComplete(for: type)
        return Button {
            if set.toggleCompleted(for: type, placeholder: previous) { onCompleted() }
        } label: {
            Image(systemName: "checkmark")
                .font(.headline.weight(.bold))
                .foregroundStyle(set.isCompleted ? Color.accentForeground : Color.secondary)
                .frame(width: SetColumns.check, height: 36)
                .background(set.isCompleted ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.fill.tertiary),
                            in: RoundedRectangle(cornerRadius: 10))
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .disabled(!set.isCompleted && !ready)
        .accessibilityLabel(set.isCompleted ? "Set \(number) done" : "Mark set \(number) done")
        .accessibilityRemoveTraits(set.isCompleted ? [] : .isSelected)
        .accessibilityIdentifier("\(identifier).check")
        .sensoryFeedback(.success, trigger: set.isCompleted) { _, done in done }
    }
}
