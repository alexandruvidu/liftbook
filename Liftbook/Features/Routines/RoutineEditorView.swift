import SwiftData
import SwiftUI

/// Sheet for creating or editing a routine, laid out like the workout
/// screen: a block per exercise with its sets, then Add Exercises.
struct RoutineEditorView: View {
    let routine: Routine?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \RoutineFolder.sortIndex) private var folders: [RoutineFolder]
    @Query private var customExercises: [CustomExercise]
    @Query(sort: \Machine.createdAt) private var machines: [Machine]
    @Query(filter: #Predicate<WorkoutSession> { $0.endedAt != nil }, sort: \WorkoutSession.startedAt, order: .reverse)
    private var finishedSessions: [WorkoutSession]
    @State private var draft: RoutineDraft
    @State private var isPicking = false
    @State private var isConfirmingDelete = false
    @State private var isConfirmingDiscard = false
    /// The routine as it was when the sheet opened, to spot unsaved changes.
    private let original: RoutineDraft

    /// Edits `routine`, or makes a new, empty one when it's nil.
    init(routine: Routine?) {
        self.routine = routine
        original = routine.map(RoutineDraft.init(routine:)) ?? RoutineDraft()
        _draft = State(initialValue: original)
    }

    /// A new routine starting from `draft`, e.g. a copy of a past workout.
    init(newFrom draft: RoutineDraft) {
        routine = nil
        original = RoutineDraft()
        _draft = State(initialValue: draft)
    }

    private var hasChanges: Bool { draft != original }

    var body: some View {
        let catalog = ExerciseCatalog(custom: customExercises.map(\.asLibraryExercise))
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    detailsBlock

                    if draft.entries.isEmpty {
                        Text("Add the exercises you want to do, then set how many sets of each.")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                    }

                    VStack(spacing: 12) {
                        ForEach(draft.entries) { entry in
                            let index = draft.entries.firstIndex { $0.id == entry.id } ?? 0
                            RoutineExerciseBlock(entry: binding(for: entry.id),
                                                 info: catalog.exercise(id: entry.exerciseID),
                                                 name: catalog.name(for: entry.exerciseID),
                                                 machines: machines.of(entry.exerciseID),
                                                 history: finishedSessions,
                                                 identifier: "routine.entry.\(index)",
                                                 canMoveUp: index > 0,
                                                 canMoveDown: index < draft.entries.count - 1,
                                                 move: { move(entry.id, by: $0) },
                                                 remove: { withAnimation(.snappy) { draft.entries.removeAll { $0.id == entry.id } } })
                        }
                        .reorderableIfAvailable()
                    }
                    .reordersEntries(of: $draft)

                    Button {
                        isPicking = true
                    } label: {
                        Label("Add Exercises", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.pillProminent)
                    .accessibilityIdentifier("routine.addExercises")

                    if routine != nil {
                        Button("Delete Routine", role: .destructive) { isConfirmingDelete = true }
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .accessibilityIdentifier("routine.delete")
                            .confirmationDialog("Delete \(draft.trimmedName)?", isPresented: $isConfirmingDelete,
                                                titleVisibility: .visible) {
                                Button("Delete Routine", role: .destructive, action: delete)
                                Button("Cancel", role: .cancel) {}
                            } message: {
                                Text("Past workouts started from it are not affected.")
                            }
                    }
                }
                .padding(16)
            }
            .swipeActionsContainerIfAvailable()
            .blockScreenBackground()
            .scrollDismissesKeyboard(.interactively)
            .exercisePageDestination()
            .navigationTitle(routine == nil ? "New Routine" : "Edit Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if hasChanges { isConfirmingDiscard = true } else { dismiss() }
                    }
                    .accessibilityIdentifier("routine.cancel")
                    // An alert, not a dialog: anchored to a toolbar button, a dialog
                    // shows as a bare popover without its title or cancel button.
                    .alert("Discard your changes?", isPresented: $isConfirmingDiscard) {
                        Button("Discard Changes", role: .destructive) { dismiss() }
                            .accessibilityIdentifier("routine.discardChanges")
                        Button("Keep Editing", role: .cancel) {}
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .buttonStyle(.borderedProminent)
                        .foregroundStyle(Color.accentForeground)
                        .disabled(!draft.problems.isEmpty)
                        .accessibilityIdentifier("routine.save")
                }
            }
            .sheet(isPresented: $isPicking) {
                ExercisePickerView(catalog: catalog) { ids in withAnimation(.snappy) { draft.add(ids) } }
            }
        }
        // Swiping the sheet away would silently lose a half-made routine.
        .interactiveDismissDisabled(hasChanges)
    }

    /// Name, folder and notes, like a workout's title area.
    private var detailsBlock: some View {
        Block {
            TextField("Routine name", text: $draft.name)
                .font(.title3.weight(.bold))
                .textInputAutocapitalization(.words)
                .accessibilityIdentifier("routine.name")
            Divider()
            HStack {
                Label("Folder", systemImage: "folder")
                    .foregroundStyle(.secondary)
                Spacer()
                Menu {
                    Picker("Folder", selection: $draft.folderID) {
                        Text("None").tag(UUID?.none)
                        ForEach(folders) { Text($0.name).tag(Optional($0.folderID)) }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(folders.first { $0.folderID == draft.folderID }?.name ?? "None")
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption.weight(.semibold))
                    }
                }
                .accessibilityIdentifier("routine.folder")
            }
            Divider()
            TextField("Notes (optional)", text: $draft.notes, axis: .vertical)
                .lineLimit(1...6)
                .accessibilityIdentifier("routine.notes")
        }
    }

    private func binding(for id: UUID) -> Binding<RoutineDraft.Entry> {
        Binding {
            draft.entries.first { $0.id == id } ?? RoutineDraft.Entry(exerciseID: "")
        } set: { newValue in
            guard let index = draft.entries.firstIndex(where: { $0.id == id }) else { return }
            draft.entries[index] = newValue
        }
    }

    /// One place up (-1) or down (+1): the menu's way to reorder, which
    /// also works where dragging blocks isn't available.
    private func move(_ id: UUID, by offset: Int) {
        guard let index = draft.entries.firstIndex(where: { $0.id == id }) else { return }
        let destination = index + offset
        guard draft.entries.indices.contains(destination) else { return }
        withAnimation(.snappy) { draft.entries.swapAt(index, destination) }
    }

    private func save() {
        guard draft.problems.isEmpty else { return }
        let target = routine ?? Routine()
        if routine == nil {
            modelContext.insert(target)
        }
        let folder = folders.first { $0.folderID == draft.folderID }
        target.apply(draft, folder: folder, in: modelContext)
        dismiss()
    }

    private func delete() {
        if let routine {
            modelContext.delete(routine)
        }
        dismiss()
    }
}

private extension View {
    /// Drag-to-reorder for the editor's exercise blocks (iOS 27).
    @ViewBuilder
    func reordersEntries(of draft: Binding<RoutineDraft>) -> some View {
        if #available(iOS 27, *) {
            reorderContainer(for: RoutineDraft.Entry.self) { difference in
                let target: UUID? = switch difference.destination.position {
                case .before(let id): id
                case .end: nil
                }
                withAnimation(.snappy) { draft.wrappedValue.move(difference.sources, before: target) }
            }
        } else {
            self
        }
    }
}
