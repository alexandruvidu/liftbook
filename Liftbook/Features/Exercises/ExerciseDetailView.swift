import SwiftUI

struct ExerciseDetailView: View {
    let exercise: LibraryExercise

    var body: some View {
        List {
            Section("How to do it") {
                Text(exercise.details)
                    .accessibilityIdentifier("exercise.detail.description")
            }

            Section("Muscles") {
                LabeledContent("Primary", value: muscleList(exercise.primaryMuscles))
                if !exercise.secondaryMuscles.isEmpty {
                    LabeledContent("Secondary", value: muscleList(exercise.secondaryMuscles))
                }
            }

            Section("Details") {
                LabeledContent("Equipment", value: exercise.equipment.displayName)
                LabeledContent("Logged as", value: exercise.type.displayName)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.large)
    }

    private func muscleList(_ muscles: [Muscle]) -> String {
        muscles.map(\.displayName).joined(separator: ", ")
    }
}

#Preview {
    NavigationStack {
        ExerciseDetailView(exercise: ExerciseLibrary.bundled.exercises[0])
    }
}
