import SwiftUI

extension View {
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
