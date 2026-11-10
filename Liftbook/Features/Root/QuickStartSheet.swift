import SwiftData
import SwiftUI

/// Opened by the start button: an empty workout or one of the routines.
struct QuickStartSheet: View {
    let start: (WorkoutStartRequest) -> Void
    @Query(sort: \Routine.name) private var routines: [Routine]
    @Query private var customExercises: [CustomExercise]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let catalog = ExerciseCatalog(custom: customExercises.map(\.asLibraryExercise))
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    Button {
                        start(.empty)
                    } label: {
                        Text("\(Image(systemName: "play.fill")) Start Empty Workout")
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.pillProminent)
                    .accessibilityLabel("Start Empty Workout")
                    .accessibilityIdentifier("quickStart.empty")

                    if !routines.isEmpty {
                        SectionTitle("Routines")
                        ForEach(routines) { routine in
                            Block {
                                BlockHeader(routine.name, subtitle: summary(of: routine, catalog: catalog)) {
                                    Button("Start") { start(.routine(routine)) }
                                        .buttonStyle(.pillProminent)
                                        .accessibilityIdentifier("quickStart.routine.\(routine.name)")
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
            .blockScreenBackground()
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

    private func summary(of routine: Routine, catalog: ExerciseCatalog) -> String {
        let names = routine.orderedEntries.map { catalog.name(for: $0.exerciseID) }
        return names.isEmpty ? "No exercises yet" : names.joined(separator: ", ")
    }
}
