import SwiftUI

struct RoutineRow: View {
    let routine: Routine
    let catalog: ExerciseCatalog

    var body: some View {
        let names = routine.orderedEntries.map { catalog.name(for: $0.exerciseID) }
        VStack(alignment: .leading, spacing: 2) {
            Text(routine.name)
                .font(.body.weight(.semibold))
            Text(Self.summary(of: names))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 2)
    }

    /// "Bench Press, Squat, Row" or "Bench Press, Squat +3 more".
    static func summary(of names: [String], limit: Int = 3) -> String {
        guard names.count > limit else { return names.joined(separator: ", ") }
        return names.prefix(limit - 1).joined(separator: ", ") + " +\(names.count - limit + 1) more"
    }
}

/// Shown in place of the routine list when there are no routines or folders.
struct NoRoutinesSection: View {
    let create: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "list.bullet.clipboard")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No routines yet")
                .font(.headline)
            Text("Build a routine once, then reuse it every session. Group routines into folders like Push, Pull and Legs.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(action: create) {
                Text("New Routine").foregroundStyle(Color.accentForeground)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("workout.emptyNewRoutine")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}

/// Which routine the editor sheet is for.
enum RoutineEditorTarget: Identifiable {
    case new
    case edit(Routine)

    var id: String {
        switch self {
        case .new: "new"
        case .edit(let routine): routine.routineID.uuidString
        }
    }

    var routine: Routine? {
        if case .edit(let routine) = self { routine } else { nil }
    }
}
