import SwiftUI

/// Drag-to-reorder for a workout's exercise blocks (iOS 27): press and hold
/// a block, then drag it. Before iOS 27 the order stays as added.
extension DynamicViewContent {
    @ViewBuilder
    func reorderableIfAvailable() -> some View {
        if #available(iOS 27, *) {
            reorderable()
        } else {
            self
        }
    }
}

extension View {
    /// The container for blocks made `reorderableIfAvailable()`; moves are
    /// applied to `session`, keeping supersets consistent.
    @ViewBuilder
    func reordersExercises(of session: WorkoutSession, onMove: @escaping () -> Void = {}) -> some View {
        if #available(iOS 27, *) {
            reorderContainer(for: WorkoutExercise.self, itemID: \.stableID) { difference in
                let ordered = session.orderedExercises
                let moving = ordered.filter { difference.sources.contains($0.stableID) }
                let target: WorkoutExercise? = switch difference.destination.position {
                case .before(let id): ordered.first { $0.stableID == id }
                case .end: nil
                }
                withAnimation(.snappy) { session.moveExercises(moving, before: target) }
                onMove()
            }
        } else {
            self
        }
    }
}
