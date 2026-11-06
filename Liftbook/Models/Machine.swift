import Foundation
import SwiftData

/// A specific machine (or station) an exercise can be done on, e.g. one of
/// three T-bar row machines. Each loads differently, so each keeps its own
/// history. Belongs to exactly one exercise.
@Model
final class Machine {
    @Attribute(.unique) var machineID: UUID
    var exerciseID: String
    var name: String
    /// Where it is in the gym, e.g. "back corner".
    var location: String
    /// A photo in `PhotoStore.machines`.
    var photoFileName: String?
    var createdAt: Date

    init(exerciseID: String, name: String, location: String = "", createdAt: Date = .now) {
        machineID = UUID()
        self.exerciseID = exerciseID
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.location = location.trimmingCharacters(in: .whitespacesAndNewlines)
        self.createdAt = createdAt
    }

    /// The machine used most recently for an exercise in finished workouts.
    static func lastUsed(exerciseID: String, in sessions: [WorkoutSession]) -> UUID? {
        sessions
            .filter { $0.endedAt != nil }
            .sorted { $0.startedAt > $1.startedAt }
            .lazy
            .compactMap { session in
                session.orderedExercises.first { $0.exerciseID == exerciseID && $0.machineID != nil }?.machineID
            }
            .first
    }
}

/// Which sets of an exercise a calculation looks at.
enum MachineFilter: Hashable, Sendable {
    /// Every set, whatever machine (the combined view).
    case all
    /// Only sets logged without a machine.
    case none
    /// Only sets logged on this machine.
    case machine(UUID)

    /// `.machine(id)`, or `.none` for nil.
    init(_ machineID: UUID?) {
        self = machineID.map(MachineFilter.machine) ?? .none
    }

    func matches(_ exercise: WorkoutExercise) -> Bool {
        switch self {
        case .all: true
        case .none: exercise.machineID == nil
        case .machine(let id): exercise.machineID == id
        }
    }
}

extension Array where Element == Machine {
    /// The name of the machine with this ID; nil when there's none (or it was deleted).
    func name(for id: UUID?) -> String? {
        guard let id else { return nil }
        return first { $0.machineID == id }?.name
    }

    /// This exercise's machines, oldest first.
    func of(_ exerciseID: String) -> [Machine] {
        filter { $0.exerciseID == exerciseID }.sorted { $0.createdAt < $1.createdAt }
    }
}
