import SwiftUI

struct ExercisesHomeView: View {
    var library: ExerciseLibrary = .bundled

    var body: some View {
        NavigationStack {
            List {
                ForEach(library.sections) { section in
                    Section(section.letter) {
                        ForEach(section.exercises) { exercise in
                            NavigationLink(value: exercise) {
                                ExerciseRow(exercise: exercise)
                            }
                            .accessibilityIdentifier("exercise.row.\(exercise.id)")
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(AppTab.exercises.title)
            .navigationDestination(for: LibraryExercise.self) { exercise in
                ExerciseDetailView(exercise: exercise)
            }
        }
    }
}

struct ExerciseRow: View {
    let exercise: LibraryExercise

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(exercise.name)
                .font(.body)
            Text(exercise.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    ExercisesHomeView()
}
