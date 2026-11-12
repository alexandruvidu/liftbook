import SwiftData
import SwiftUI

/// Opened by Start Workout: an empty workout or one of the routines.
struct QuickStartSheet: View {
    let start: (WorkoutStartRequest) -> Void
    @Query(sort: \Routine.name) private var routines: [Routine]
    @Query private var customExercises: [CustomExercise]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let catalog = ExerciseCatalog(custom: customExercises.map(\.asLibraryExercise))
        NavigationStack {
            List {
                Section {
                    Button {
                        start(.empty)
                    } label: {
                        Label("Start Empty Workout", systemImage: "play.fill")
                            .font(.headline)
                    }
                    .accessibilityIdentifier("quickStart.empty")
                }

                if !routines.isEmpty {
                    Section("Routines") {
                        ForEach(routines) { routine in
                            Button {
                                start(.routine(routine))
                            } label: {
                                HStack {
                                    RoutineRow(routine: routine, catalog: catalog)
                                        .foregroundStyle(Color.primary)
                                    Spacer(minLength: 8)
                                    Image(systemName: "play.circle.fill")
                                        .imageScale(.large)
                                        .accessibilityHidden(true)
                                }
                            }
                            .accessibilityLabel("Start \(routine.name)")
                            .accessibilityIdentifier("quickStart.routine.\(routine.name)")
                        }
                    }
                }
            }
            .navigationTitle("Start a Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
