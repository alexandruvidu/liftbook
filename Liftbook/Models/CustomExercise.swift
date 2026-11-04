import Foundation
import SwiftData

/// An exercise the user created. Stored with SwiftData; shown alongside the
/// bundled library by converting to `LibraryExercise`.
@Model
final class CustomExercise {
    static let idPrefix = "custom-"

    @Attribute(.unique) var exerciseID: String
    var name: String
    var primaryMuscleIDs: [String]
    var secondaryMuscleIDs: [String]
    var equipmentID: String
    var typeID: String
    var details: String
    var createdAt: Date

    init(draft: ExerciseDraft, createdAt: Date = .now) {
        exerciseID = Self.idPrefix + UUID().uuidString.lowercased()
        name = ""
        primaryMuscleIDs = []
        secondaryMuscleIDs = []
        equipmentID = Equipment.none.rawValue
        typeID = ExerciseType.weightAndReps.rawValue
        details = ""
        self.createdAt = createdAt
        update(from: draft)
    }

    func update(from draft: ExerciseDraft) {
        name = draft.trimmedName
        primaryMuscleIDs = draft.orderedPrimaryMuscles.map(\.rawValue)
        secondaryMuscleIDs = draft.orderedSecondaryMuscles.map(\.rawValue)
        equipmentID = draft.equipment.rawValue
        typeID = draft.type.rawValue
        details = draft.details.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var primaryMuscles: [Muscle] { primaryMuscleIDs.compactMap(Muscle.init(rawValue:)) }
    var secondaryMuscles: [Muscle] { secondaryMuscleIDs.compactMap(Muscle.init(rawValue:)) }
    var equipment: Equipment { Equipment(rawValue: equipmentID) ?? .other }
    var type: ExerciseType { ExerciseType(rawValue: typeID) ?? .weightAndReps }

    var asLibraryExercise: LibraryExercise {
        LibraryExercise(
            id: exerciseID,
            name: name,
            primaryMuscles: primaryMuscles,
            secondaryMuscles: secondaryMuscles,
            equipment: equipment,
            type: type,
            details: details
        )
    }
}

extension LibraryExercise {
    var isCustom: Bool { id.hasPrefix(CustomExercise.idPrefix) }
}
