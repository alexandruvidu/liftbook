import SwiftData
import SwiftUI

struct WorkoutHomeView: View {
    @Query(sort: \RoutineFolder.sortIndex) private var folders: [RoutineFolder]
    @Query(sort: \Routine.name) private var routines: [Routine]
    @Query private var customExercises: [CustomExercise]

    @State private var starter = WorkoutStartController()
    @State private var editorTarget: RoutineEditorTarget?
    @State private var folderAction: FolderAction?

    var body: some View {
        let catalog = ExerciseCatalog(custom: customExercises.map(\.asLibraryExercise))
        NavigationStack {
            let unfiled = routines.filter { $0.folder == nil }
            List {
                StartWorkoutSection(starter: starter)

                if routines.isEmpty && folders.isEmpty {
                    NoRoutinesSection { editorTarget = .new }
                }

                ForEach(folders) { folder in
                    Section {
                        let inFolder = routines.filter { $0.folder == folder }
                        if inFolder.isEmpty {
                            Text("No routines in this folder yet.")
                                .foregroundStyle(.secondary)
                        }
                        ForEach(inFolder) { routineLink($0, catalog: catalog) }
                    } header: {
                        FolderHeader(folder: folder) { folderAction = $0 }
                    }
                }

                if !unfiled.isEmpty {
                    Section(folders.isEmpty ? "Routines" : "Other Routines") {
                        ForEach(unfiled) { routineLink($0, catalog: catalog) }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(AppTab.workout.title)
            .navigationDestination(for: Routine.self) { routine in
                RoutineDetailView(routine: routine, catalog: catalog) { starter.start(.routine(routine)) }
            }
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
            .workoutStarting(starter)
        }
    }

    private func routineLink(_ routine: Routine, catalog: ExerciseCatalog) -> some View {
        NavigationLink(value: routine) {
            RoutineRow(routine: routine, catalog: catalog)
        }
        .accessibilityIdentifier("routine.row.\(routine.name)")
    }
}

#Preview {
    WorkoutHomeView()
        .modelContainer(Persistence.makeContainer(inMemory: true))
}
