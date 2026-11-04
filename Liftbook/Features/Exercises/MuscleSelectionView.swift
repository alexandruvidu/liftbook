import SwiftUI

/// Multi-select list of muscles. Muscles in `unavailable` are shown disabled.
struct MuscleSelectionView: View {
    let title: String
    @Binding var selection: Set<Muscle>
    var unavailable: Set<Muscle> = []

    var body: some View {
        List(Muscle.allCases) { muscle in
            let isSelected = selection.contains(muscle)
            let isUnavailable = unavailable.contains(muscle)
            Button {
                if isSelected {
                    selection.remove(muscle)
                } else {
                    selection.insert(muscle)
                }
            } label: {
                HStack {
                    Text(muscle.displayName)
                        .foregroundStyle(isUnavailable ? Color.secondary : Color.primary)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark")
                            .fontWeight(.semibold)
                            .foregroundStyle(.tint)
                    }
                }
                .contentShape(Rectangle())
            }
            .disabled(isUnavailable)
            .accessibilityIdentifier("muscle.\(muscle.rawValue)")
            .accessibilityAddTraits(isSelected ? .isSelected : [])
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
