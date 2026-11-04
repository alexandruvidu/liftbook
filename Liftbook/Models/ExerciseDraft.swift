import Foundation

/// Editable fields for creating or editing a custom exercise, plus validation.
struct ExerciseDraft: Equatable, Sendable {
    enum Problem: Equatable, Sendable {
        case missingName
        case duplicateName
        case missingPrimaryMuscle

        var message: String {
            switch self {
            case .missingName: "Give the exercise a name."
            case .duplicateName: "An exercise with this name already exists."
            case .missingPrimaryMuscle: "Pick at least one primary muscle."
            }
        }
    }

    var name = ""
    var type: ExerciseType = .weightAndReps
    var equipment: Equipment = .none
    var primaryMuscles: Set<Muscle> = []
    var secondaryMuscles: Set<Muscle> = []
    var details = ""

    init() {}

    init(exercise: LibraryExercise) {
        name = exercise.name
        type = exercise.type
        equipment = exercise.equipment
        primaryMuscles = Set(exercise.primaryMuscles)
        secondaryMuscles = Set(exercise.secondaryMuscles)
        details = exercise.details
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Primary muscles in the canonical `Muscle.allCases` order.
    var orderedPrimaryMuscles: [Muscle] {
        Muscle.allCases.filter(primaryMuscles.contains)
    }

    /// Secondary muscles, never repeating a primary one.
    var orderedSecondaryMuscles: [Muscle] {
        Muscle.allCases.filter { secondaryMuscles.contains($0) && !primaryMuscles.contains($0) }
    }

    /// Problems that block saving. `existingNames` should exclude the exercise being edited.
    func problems(existingNames: [String]) -> [Problem] {
        var problems: [Problem] = []
        if trimmedName.isEmpty {
            problems.append(.missingName)
        } else if existingNames.contains(where: { $0.caseInsensitiveCompare(trimmedName) == .orderedSame }) {
            problems.append(.duplicateName)
        }
        if primaryMuscles.isEmpty {
            problems.append(.missingPrimaryMuscle)
        }
        return problems
    }
}
