import Foundation

/// A muscle group used to tag and filter exercises.
enum Muscle: String, Codable, CaseIterable, Identifiable, Sendable {
    case chest, lats, upperBack, traps, lowerBack, shoulders
    case biceps, triceps, forearms
    case abs, obliques
    case glutes, quads, hamstrings, adductors, abductors, calves
    case fullBody

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .chest: "Chest"
        case .lats: "Lats"
        case .upperBack: "Upper Back"
        case .traps: "Traps"
        case .lowerBack: "Lower Back"
        case .shoulders: "Shoulders"
        case .biceps: "Biceps"
        case .triceps: "Triceps"
        case .forearms: "Forearms"
        case .abs: "Abs"
        case .obliques: "Obliques"
        case .glutes: "Glutes"
        case .quads: "Quads"
        case .hamstrings: "Hamstrings"
        case .adductors: "Adductors"
        case .abductors: "Abductors"
        case .calves: "Calves"
        case .fullBody: "Full Body"
        }
    }
}

/// The main piece of equipment an exercise needs.
enum Equipment: String, Codable, CaseIterable, Identifiable, Sendable {
    case none, barbell, dumbbell, kettlebell, machine, cable, band
    case smithMachine, ezBar, trapBar, plate, medicineBall, cardioMachine, other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: "No Equipment"
        case .barbell: "Barbell"
        case .dumbbell: "Dumbbell"
        case .kettlebell: "Kettlebell"
        case .machine: "Machine"
        case .cable: "Cable"
        case .band: "Resistance Band"
        case .smithMachine: "Smith Machine"
        case .ezBar: "EZ Bar"
        case .trapBar: "Trap Bar"
        case .plate: "Weight Plate"
        case .medicineBall: "Medicine Ball"
        case .cardioMachine: "Cardio Machine"
        case .other: "Other"
        }
    }
}

/// How sets of an exercise are recorded.
enum ExerciseType: String, Codable, CaseIterable, Identifiable, Sendable {
    case weightAndReps, bodyweight, assisted, duration, distance

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .weightAndReps: "Weight & Reps"
        case .bodyweight: "Bodyweight Reps"
        case .assisted: "Assisted"
        case .duration: "Duration"
        case .distance: "Distance"
        }
    }
}

/// An exercise from the read-only library bundled with the app.
struct LibraryExercise: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let primaryMuscles: [Muscle]
    let secondaryMuscles: [Muscle]
    let equipment: Equipment
    let type: ExerciseType
    let details: String

    private enum CodingKeys: String, CodingKey {
        case id, name, primaryMuscles, secondaryMuscles, equipment, type
        case details = "description"
    }

    /// Short line for list rows, e.g. "Chest · Barbell".
    var summary: String {
        let muscles = primaryMuscles.map(\.displayName).joined(separator: ", ")
        return "\(muscles) · \(equipment.displayName)"
    }
}
