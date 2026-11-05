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

    var body: some View {
        List {
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

            RecordsSection(exercise: exercise)

            SetFieldsSection(type: exercise.type)
        }
        .listStyle(.insetGrouped)
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
