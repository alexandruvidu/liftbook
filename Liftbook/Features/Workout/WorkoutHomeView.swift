import SwiftData
import SwiftUI

struct WorkoutHomeView: View {
    @Query(sort: \RoutineFolder.sortIndex) private var folders: [RoutineFolder]
    @Query(sort: \Routine.name) private var routines: [Routine]
    @Query private var customExercises: [CustomExercise]

    @State private var editorTarget: RoutineEditorTarget?
    @State private var folderAction: FolderAction?

    private var catalog: ExerciseCatalog {
        ExerciseCatalog(custom: customExercises.map(\.asLibraryExercise))
    }

    var body: some View {
        NavigationStack {
            let catalog = catalog
            let unfiled = routines.filter { $0.folder == nil }
            List {
                ForEach(folders) { folder in
                    Section {
                        let inFolder = routines.filter { $0.folder == folder }
                        if inFolder.isEmpty {
                            Text("No routines in this folder yet.")
                                .foregroundStyle(.secondary)
                        }
                        ForEach(inFolder) { routine in
                            routineButton(routine, catalog: catalog)
                        }
                    } header: {
                        FolderHeader(folder: folder) { folderAction = $0 }
                    }
                }

                if !unfiled.isEmpty {
                    Section(folders.isEmpty ? "Routines" : "Other Routines") {
                        ForEach(unfiled) { routine in
                            routineButton(routine, catalog: catalog)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .overlay {
                if routines.isEmpty && folders.isEmpty {
                    NoRoutinesView { editorTarget = .new }
                }
            }
            .navigationTitle(AppTab.workout.title)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu("Add", systemImage: "plus") {
                        Button("New Routine", systemImage: "list.bullet.rectangle") { editorTarget = .new }
                            .accessibilityIdentifier("workout.newRoutine")
                        Button("New Folder", systemImage: "folder.badge.plus") { folderAction = .create }
                            .accessibilityIdentifier("workout.newFolder")
                    }
                    .accessibilityIdentifier("workout.add")
                }
            }
            .sheet(item: $editorTarget) { target in
                RoutineEditorView(routine: target.routine)
            }
            .folderActions($folderAction, folderCount: folders.count)
        }
    }

    private func routineButton(_ routine: Routine, catalog: ExerciseCatalog) -> some View {
        Button {
            editorTarget = .edit(routine)
        } label: {
            RoutineRow(routine: routine, catalog: catalog)
        }
        .foregroundStyle(.primary)
        .accessibilityIdentifier("routine.row.\(routine.name)")
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

private struct NoRoutinesView: View {
    let create: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("No routines yet", systemImage: "list.bullet.clipboard")
        } description: {
            Text("Build a routine once, then reuse it every session. Group routines into folders like Push, Pull and Legs.")
        } actions: {
            Button(action: create) {
                Text("New Routine").foregroundStyle(Color.accentForeground)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("workout.emptyNewRoutine")
        }
    }
}

#Preview {
    WorkoutHomeView()
        .modelContainer(Persistence.makeContainer(inMemory: true))
}
