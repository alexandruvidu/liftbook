import Foundation

/// What the in-app keypad for set values offers for each field: its extra
/// key and how far − and + move a value.
enum SetKeypad {
    /// The key left of 0: the decimal separator, ":" for times, none for reps.
    static func separator(for field: SetField, locale: Locale = .current) -> String? {
        switch field {
        case .weight, .distance: locale.decimalSeparator ?? "."
        case .reps: nil
        case .duration: ":"
        }
    }

    /// How much − and + change a value, in the display unit (seconds for times).
    static func step(for field: SetField, unit: WeightUnit) -> Double {
        switch field {
        case .weight: unit == .kilograms ? 2.5 : 5
        case .reps: 1
        case .duration: 15
        case .distance: 0.5
        }
    }

    /// "2.5", "1", "15s": shown on the − and + keys.
    static func stepLabel(for field: SetField, unit: WeightUnit, locale: Locale = .current) -> String {
        let step = step(for: field, unit: unit)
        return field == .duration ? "\(Int(step))s" : SetMeasurement.decimal(step, locale: locale)
    }

    /// `text`, or `placeholder` (last time's value) when it's empty, moved one
    /// step up or down; never below zero or above the field's maximum.
    static func stepped(_ text: String, placeholder: String?, field: SetField, unit: WeightUnit,
                        up: Bool, locale: Locale = .current) -> String {
        let start = value(text, field: field) ?? placeholder.flatMap { value($0, field: field) } ?? 0
        let step = step(for: field, unit: unit)
        let moved = min(max(0, start + (up ? step : -step)), SetInput.maximum(for: field))
        switch field {
        case .weight, .distance: return SetMeasurement.decimal(moved, locale: locale)
        case .reps: return String(Int(moved.rounded()))
        case .duration: return SetMeasurement.clock(moved)
        }
    }

    private static func value(_ text: String, field: SetField) -> Double? {
        switch field {
        case .weight, .distance: SetInput.decimal(text)
        case .reps: SetInput.reps(text).map(Double.init)
        case .duration: SetInput.duration(text)
        }
    }
}
