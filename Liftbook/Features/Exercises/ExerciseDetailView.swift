import SwiftData
import SwiftUI

struct ExerciseDetailView: View {
    let exerciseID: String
    var library: ExerciseLibrary = .bundled

    @Query private var customExercises: [CustomExercise]
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    @State private var wasDeleted = false

    private var custom: CustomExercise? {
        customExercises.first { $0.exerciseID == exerciseID }
    }

    private var exercise: LibraryExercise? {
        library.exercise(id: exerciseID) ?? custom?.asLibraryExercise
    }

    var body: some View {
        Group {
            if let exercise {
                ExerciseDetailList(exercise: exercise)
                    .navigationTitle(exercise.name)
            } else {
                ContentUnavailableView("Exercise not found", systemImage: "questionmark.circle")
            }
        }
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if custom != nil {
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") { isEditing = true }
                        .accessibilityIdentifier("exercise.edit")
                }
            }
        }
        .sheet(isPresented: $isEditing, onDismiss: { if wasDeleted { dismiss() } }) {
            if let custom {
                ExerciseEditorView(editing: custom) { wasDeleted = true }
            }
        }
    }
}

private struct ExerciseDetailList: View {
    let exercise: LibraryExercise
    @Query(filter: #Predicate<WorkoutSession> { $0.endedAt != nil })
    private var sessions: [WorkoutSession]
    @Query private var customExercises: [CustomExercise]
    @Query(sort: \Machine.createdAt) private var allMachines: [Machine]
    /// Which machine's charts and records to show.
    @State private var machineFilter: MachineFilter = .all

    var body: some View {
        // Once the exercise has been logged, progress comes first.
        let logged = !PersonalRecords.loggedSets(of: exercise.id, in: sessions).isEmpty
        List {
            if logged {
                progressSections
            }

            if !exercise.details.isEmpty {
                Section("How to do it") {
                    Text(exercise.details)
                        .accessibilityIdentifier("exercise.detail.description")
                }
            }

            Section("Muscles") {
                LabeledContent("Primary", value: muscleList(exercise.primaryMuscles))
                if !exercise.secondaryMuscles.isEmpty {
                    LabeledContent("Secondary", value: muscleList(exercise.secondaryMuscles))
                }
            }

            Section("Details") {
                LabeledContent("Equipment", value: exercise.equipment.displayName)
                if exercise.isCustom {
                    LabeledContent("Source", value: "Created by you")
                }
            }

            if !logged {
                progressSections
            }

            MachinesSection(exerciseID: exercise.id)

            SetFieldsSection(type: exercise.type)

            alternativesSection
        }
        .listStyle(.insetGrouped)
    }

    @ViewBuilder private var alternativesSection: some View {
        let catalog = ExerciseCatalog(custom: customExercises.map(\.asLibraryExercise))
        let alternatives = Substitutions.suggestions(for: exercise, among: catalog.exercises)
        if !alternatives.isEmpty {
            Section {
                ForEach(alternatives) { alternative in
                    NavigationLink {
                        ExerciseDetailView(exerciseID: alternative.id)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(alternative.name)
                            Text(alternative.summary)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityIdentifier("exercise.alternative.\(alternative.id)")
                }
            } header: {
                Text("Alternatives")
            } footer: {
                Text("Exercises that train the same main muscles, for when equipment is busy or you want variety.")
            }
        }
    }

    @ViewBuilder private var progressSections: some View {
        let machines = allMachines.of(exercise.id)
        if !machines.isEmpty {
            Section {
                MachineSwitcher(machines: machines,
                                hasUnassigned: !PersonalRecords.loggedSets(of: exercise.id, machine: .none, in: sessions).isEmpty,
                                selection: $machineFilter)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .listRowBackground(Color.clear)
            }
        }
        if exercise.type == .weightAndReps {
            ExerciseProgressChart(exerciseID: exercise.id, machine: machineFilter)
        }
        RecordsSection(exercise: exercise, machine: machineFilter)
    }

    private func muscleList(_ muscles: [Muscle]) -> String {
        muscles.map(\.displayName).joined(separator: ", ")
    }
}

#Preview {
    NavigationStack {
        ExerciseDetailView(exerciseID: "barbell-bench-press")
    }
    .modelContainer(Persistence.makeContainer(inMemory: true))
}
