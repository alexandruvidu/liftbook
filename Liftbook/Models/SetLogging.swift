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

    /// RPE choices offered when logging a set.
    static let rpeOptions: [Double] = Array(stride(from: 6.0, through: 10.0, by: 0.5))
}

extension SetMeasurement {
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
        if isCompleted {
            isCompleted = false
            completedAt = nil
        } else if measurement.isComplete(for: type) {
            isCompleted = true
            completedAt = date
        }
        return isCompleted
    }
}
