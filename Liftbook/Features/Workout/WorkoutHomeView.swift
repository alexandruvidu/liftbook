import SwiftData
import SwiftUI

struct WorkoutHomeView: View {
    @Query(sort: \RoutineFolder.sortIndex) private var folders: [RoutineFolder]
    @Query(sort: \Routine.name) private var routines: [Routine]
    @Query private var customExercises: [CustomExercise]
    @State private var collapsedFolders: Set<UUID> = []
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @Environment(WorkoutStartController.self) private var starter
    @State private var editorTarget: RoutineEditorTarget?
    @State private var folderAction: FolderAction?

    var body: some View {
        let catalog = ExerciseCatalog(custom: customExercises.map(\.asLibraryExercise))
        NavigationStack {
            let unfiled = routines.filter { $0.folder == nil }
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if routines.isEmpty && folders.isEmpty {
                        Block {
                            NoRoutinesSection { editorTarget = .new }
                        }
                    }

                    ForEach(folders) { folder in
                        let isCollapsed = collapsedFolders.contains(folder.folderID)
                        HStack(spacing: 8) {
                            Button {
                                withAnimation(.snappy) {
                                    if isCollapsed { collapsedFolders.remove(folder.folderID) } else { collapsedFolders.insert(folder.folderID) }
                                }
                            } label: {
                                Image(systemName: "chevron.down")
                                    .font(.subheadline.weight(.bold))
                                    .rotationEffect(.degrees(isCollapsed ? -90 : 0))
                                    .frame(width: 44, height: 44)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(isCollapsed ? "Show \(folder.name)" : "Hide \(folder.name)")
                            FolderHeader(folder: folder) { folderAction = $0 }
                                .font(.title3.weight(.bold))
                        }
                        .padding(.top, 8)
                        if !isCollapsed {
                            let inFolder = routines.filter { $0.folder == folder }
                            if inFolder.isEmpty {
                                Text("No routines in this folder yet.")
                                    .foregroundStyle(.secondary)
                                    .padding(.leading, 4)
                            }
                            ForEach(inFolder) { routineCard($0, catalog: catalog) }
                        }
                    }

                    if !unfiled.isEmpty {
                        SectionTitle(folders.isEmpty ? "Routines" : "Other Routines")
                        ForEach(unfiled) { routineCard($0, catalog: catalog) }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .blockScreenBackground()
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

    /// A routine as a card that opens its details, with a Start button.
    /// The button sits beside the link (not inside it) so it gets its own
    /// taps; at accessibility text sizes it moves below the card.
    @ViewBuilder
    private func routineCard(_ routine: Routine, catalog: ExerciseCatalog) -> some View {
        let large = dynamicTypeSize.isAccessibilitySize
        let link = NavigationLink(value: routine) {
            Block {
                VStack(alignment: .leading, spacing: 4) {
                    Text(routine.name)
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                    Text(RoutineRow.summary(of: routine.orderedEntries.map { catalog.name(for: $0.exerciseID) }))
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                        .lineLimit(large ? nil : 2)
                }
                .padding(.trailing, large ? 0 : 80)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("routine.row.\(routine.name)")
        let start = Button("Start") { starter.start(.routine(routine)) }
            .buttonStyle(.pillProminent)
            .accessibilityIdentifier("routine.quickStart.\(routine.name)")
        if large {
            VStack(alignment: .leading, spacing: 8) {
                link
                start
            }
        } else {
            link.overlay(alignment: .trailing) {
                start.padding(.trailing, 14)
            }
        }
    }
}

#Preview {
    WorkoutHomeView()
        .environment(WorkoutStartController())
        .modelContainer(Persistence.makeContainer(inMemory: true))
}
