import Foundation

/// Parses what the user types into a set's fields.
enum SetInput {
    /// A non-negative decimal; accepts "62.5" and "62,5".
    static func decimal(_ text: String) -> Double? {
        let cleaned = text.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        guard !cleaned.isEmpty, let value = Double(cleaned), value.isFinite, value >= 0 else { return nil }
        return value
    }

    /// A whole number of reps.
    static func reps(_ text: String) -> Int? {
        guard let value = Int(text.trimmingCharacters(in: .whitespaces)), value >= 0 else { return nil }
        return value
    }

    /// Seconds from "90", "1:30" or "1:02:03".
    static func duration(_ text: String) -> TimeInterval? {
        let parts = text.trimmingCharacters(in: .whitespaces).split(separator: ":", omittingEmptySubsequences: false)
        guard (1...3).contains(parts.count) else { return nil }
        var total = 0.0
        for (index, part) in parts.enumerated() {
            guard let value = decimal(String(part)) else { return nil }
            if index > 0 && value >= 60 { return nil }
            total = total * 60 + value
        }
        return total
    }

    /// Largest value accepted while typing, in the display unit: anything
    /// above is a typo and would break totals and the plate calculator.
    static func maximum(for field: SetField) -> Double {
        switch field {
        case .weight: 2_000
        case .reps: 1_000
        case .duration: 24 * 3600
        case .distance: 1_000
        }
    }

    /// Whether typed text is a number above the field's maximum.
    static func exceedsMaximum(_ text: String, for field: SetField) -> Bool {
        let value: Double? = switch field {
        case .weight, .distance: decimal(text)
        case .reps: reps(text).map(Double.init)
        case .duration: duration(text)
        }
        return (value ?? 0) > maximum(for: field)
    }

    /// RPE choices offered when logging a set.
    static let rpeOptions: [Double] = Array(stride(from: 6.0, through: 10.0, by: 0.5))

    /// Plain-language meaning of an RPE value, phrased as reps left in the tank.
    static func rpeDescription(_ rpe: Double) -> String {
        switch rpe {
        case 10...: "Max effort, no more reps possible"
        case 9.5..<10: "No more reps, maybe a bit more weight"
        case 9..<9.5: "Could do 1 more rep"
        case 8.5..<9: "Could do 1–2 more reps"
        case 8..<8.5: "Could do 2 more reps"
        case 7.5..<8: "Could do 2–3 more reps"
        case 7..<7.5: "Could do 3 more reps"
        case 6.5..<7: "Could do 3–4 more reps"
        default: "Could do 4+ more reps, felt easy"
        }
    }
}

extension SetMeasurement {
    /// These values with each empty field in `fields` taken from `other`.
    func filled(from other: SetMeasurement, fields: [SetField]) -> SetMeasurement {
        var result = self
        for field in fields {
            switch field {
            case .weight: result.weight = result.weight ?? other.weight
            case .reps: result.reps = result.reps ?? other.reps
            case .duration: result.duration = result.duration ?? other.duration
            case .distance: result.distance = result.distance ?? other.distance
            }
        }
        return result
    }

    /// A short form for a narrow column, without units: "62.5 × 8", "+10 × 12",
    /// "1:30", "5 · 25:00".
    func compactText(for type: ExerciseType, unit: WeightUnit = .kilograms) -> String {
        let weight = inputText(for: .weight, unit: unit)
        let reps = inputText(for: .reps, unit: unit)
        let parts: [String] = switch type {
        case .weightAndReps, .assisted: [weight, reps]
        case .bodyweight: [(self.weight ?? 0) > 0 ? "+" + weight : "", reps]
        case .duration: [inputText(for: .duration, unit: unit)]
        case .distance: [inputText(for: .distance, unit: unit), inputText(for: .duration, unit: unit)]
        }
        let shown = parts.filter { !$0.isEmpty }
        guard !shown.isEmpty else { return "–" }
        return shown.joined(separator: type == .distance ? " · " : " × ")
    }

    /// The text shown in an input field, in the display unit.
    func inputText(for field: SetField, unit: WeightUnit = .kilograms) -> String {
        switch field {
        case .weight: weight.map { Self.number($0, unit: unit) } ?? ""
        case .reps: reps.map(String.init) ?? ""
        case .duration: duration.map(Self.clock) ?? ""
        case .distance: distance.map { Self.decimal(unit.display(metres: $0)) } ?? ""
        }
    }

    /// Stores typed text for a field; empty or invalid text clears it.
    mutating func setInput(_ text: String, for field: SetField, unit: WeightUnit = .kilograms) {
        switch field {
        case .weight: weight = SetInput.decimal(text).map(unit.kilograms(fromDisplay:))
        case .reps: reps = SetInput.reps(text)
        case .duration: duration = SetInput.duration(text)
        case .distance:
            let metresPerUnit = unit == .kilograms ? 1000 : 1609.344
            distance = SetInput.decimal(text).map { $0 * metresPerUnit }
        }
    }
}

extension WorkoutExercise {
    /// Adds a set after the last one, prefilled with the values of the latest
    /// set that has any (not completed), and the last set's kind.
    @discardableResult
    func addSet() -> WorkoutSet {
        let ordered = orderedSets
        let last = ordered.last
        let source = ordered.last(where: { $0.measurement != SetMeasurement() })
        let set = WorkoutSet(position: (last?.position ?? -1) + 1,
                             kind: last?.kind ?? .normal,
                             measurement: source?.measurement ?? SetMeasurement())
        sets.append(set)
        return set
    }

    /// Removes a set and renumbers the rest.
    func removeSet(_ set: WorkoutSet) {
        sets.removeAll { $0.persistentModelID == set.persistentModelID }
        set.modelContext?.delete(set)
        for (index, remaining) in orderedSets.enumerated() { remaining.position = index }
    }
}

extension WorkoutSet {
    /// Checks the set off, or un-checks it. A set can only be checked off when
    /// it has every required value. Returns whether the set is now completed.
    @discardableResult
    func toggleCompleted(for type: ExerciseType, at date: Date = .now) -> Bool {
        toggleCompleted(for: type, placeholder: nil, at: date)
    }

    /// Like `toggleCompleted(for:at:)`, but when checking off, every field of
    /// the type that's still empty is first filled from `placeholder` (last
    /// time's values shown in the empty fields). Typed values win.
    @discardableResult
    func toggleCompleted(for type: ExerciseType, placeholder: SetMeasurement?, at date: Date = .now) -> Bool {
        if !isCompleted, let placeholder {
            let filled = measurement.filled(from: placeholder, fields: type.fieldSpecs.map(\.field))
            if filled.isComplete(for: type) { measurement = filled }
        }
        if isCompleted {
            isCompleted = false
            completedAt = nil
        } else if measurement.isComplete(for: type) {
            isCompleted = true
            completedAt = date
        }
        return isCompleted
    }

    /// Un-checks a done set whose values no longer make a complete set,
    /// e.g. after its weight was deleted, so it stops counting.
    func uncheckIfIncomplete(for type: ExerciseType) {
        guard isCompleted, !measurement.isComplete(for: type) else { return }
        isCompleted = false
        completedAt = nil
    }
}
