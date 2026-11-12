import SwiftData
import SwiftUI

struct WorkoutHomeView: View {
    @Query(sort: \RoutineFolder.sortIndex) private var folders: [RoutineFolder]
    @Query(sort: \Routine.name) private var routines: [Routine]
    @Query private var customExercises: [CustomExercise]
    @State private var collapsedFolders: Set<UUID> = []

    @Environment(WorkoutStartController.self) private var starter
    @State private var editorTarget: RoutineEditorTarget?
    @State private var folderAction: FolderAction?

    var body: some View {
        let catalog = ExerciseCatalog(custom: customExercises.map(\.asLibraryExercise))
        NavigationStack {
            let unfiled = routines.filter { $0.folder == nil }
            List {
                if routines.isEmpty && folders.isEmpty {
                    Section {
                        NoRoutinesSection { editorTarget = .new }
                    }
                }

                // Folders collapse with the sidebar style's disclosure button.
                ForEach(folders) { folder in
                    Section(isExpanded: isExpanded(folder)) {
                        let inFolder = routines.filter { $0.folder == folder }
                        if inFolder.isEmpty {
                            Text("No routines in this folder yet.")
                                .foregroundStyle(.secondary)
                        }
                        ForEach(inFolder) { routineRow($0, catalog: catalog) }
                    } header: {
                        FolderHeader(folder: folder) { folderAction = $0 }
                    }
                }

                if !unfiled.isEmpty {
                    Section(folders.isEmpty ? "Routines" : "Other Routines") {
                        ForEach(unfiled) { routineRow($0, catalog: catalog) }
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle(AppTab.home.title)
            .navigationDestination(for: Routine.self) { routine in
                RoutineDetailView(routine: routine, catalog: catalog) { starter.start(.routine(routine)) }
            }
            .exercisePageDestination()
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

    private func isExpanded(_ folder: RoutineFolder) -> Binding<Bool> {
        Binding(get: { !collapsedFolders.contains(folder.folderID) },
                set: { expanded in
                    if expanded { collapsedFolders.remove(folder.folderID) } else { collapsedFolders.insert(folder.folderID) }
                })
    }

    /// A routine that opens its details. Starting is a swipe or the context
    /// menu, so Start Workout above the tab bar stays the one prominent button.
    private func routineRow(_ routine: Routine, catalog: ExerciseCatalog) -> some View {
        NavigationLink(value: routine) {
            RoutineRow(routine: routine, catalog: catalog)
        }
        .accessibilityIdentifier("routine.row.\(routine.name)")
        .swipeActions(edge: .leading) {
            Button("Start", systemImage: "play.fill") { starter.start(.routine(routine)) }
                .tint(.accentColor)
                .accessibilityIdentifier("routine.quickStart.\(routine.name)")
        }
        .contextMenu {
            Button("Start Workout", systemImage: "play.fill") { starter.start(.routine(routine)) }
            Button("Edit Routine", systemImage: "pencil") { editorTarget = .edit(routine) }
        }
    }
}

#Preview {
    WorkoutHomeView()
        .environment(WorkoutStartController())
        .modelContainer(Persistence.makeContainer(inMemory: true))
}
