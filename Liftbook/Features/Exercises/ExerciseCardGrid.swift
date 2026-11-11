import SwiftData
import SwiftUI

/// Exercises as photo cards in a grid, as in the Exercises tab. `item` wraps
/// each card, e.g. in a navigation link or a selection button.
struct ExerciseCardGrid<Item: View>: View {
    let exercises: [LibraryExercise]
    @ViewBuilder let item: (LibraryExercise, ExerciseCard) -> Item

    @Environment(\.dynamicTypeSize) private var typeSize
    @Query private var media: [ExerciseMedia]
    @Query private var machines: [Machine]

    var body: some View {
        let cover = Dictionary(grouping: media, by: \.exerciseID).compactMapValues { $0.display(for: $0[0].exerciseID).first }
        let machineCounts = Dictionary(grouping: machines, by: \.exerciseID).mapValues(\.count)
        // One column at accessibility sizes: two cut every name to "Barbell Bench…".
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12),
                                 count: typeSize.isAccessibilitySize ? 1 : 2), spacing: 12) {
            ForEach(exercises) { exercise in
                item(exercise, ExerciseCard(exercise: exercise, cover: cover[exercise.id],
                                            machineCount: machineCounts[exercise.id] ?? 0))
            }
        }
    }
}
