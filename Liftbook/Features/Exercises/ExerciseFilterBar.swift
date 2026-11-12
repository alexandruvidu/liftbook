import SwiftUI

/// Muscle and equipment filter menus above the exercise grid, then the
/// number of results as the grid's header.
struct ExerciseFilterBar: View {
    @Binding var filter: ExerciseFilter
    let resultCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Menu {
                        Picker("Muscle", selection: $filter.muscle) {
                            Text("Any Muscle").tag(Muscle?.none)
                            ForEach(Muscle.allCases) { muscle in
                                Text(muscle.displayName).tag(Optional(muscle))
                            }
                        }
                    } label: {
                        chipLabel(filter.muscle?.displayName ?? "Muscle")
                    }
                    .chipStyle(isActive: filter.muscle != nil)
                    .accessibilityIdentifier("exercises.filter.muscle")

                    Menu {
                        Picker("Equipment", selection: $filter.equipment) {
                            Text("Any Equipment").tag(Equipment?.none)
                            ForEach(Equipment.allCases) { equipment in
                                Text(equipment.displayName).tag(Optional(equipment))
                            }
                        }
                    } label: {
                        chipLabel(filter.equipment?.displayName ?? "Equipment")
                    }
                    .chipStyle(isActive: filter.equipment != nil)
                    .accessibilityIdentifier("exercises.filter.equipment")

                    if filter.hasMenuFilters {
                        Button("Clear", systemImage: "xmark") { filter.clearMenuFilters() }
                            .chipStyle(isActive: false)
                            .accessibilityIdentifier("exercises.filter.clear")
                    }
                }
            }
            // Lines the chips up with the grid while letting them scroll to the edge.
            .scrollClipDisabled()

            Text(resultCount == 1 ? "1 exercise" : "\(resultCount) exercises")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("exercises.resultCount")
        }
    }

    private func chipLabel(_ title: String) -> some View {
        HStack(spacing: 4) {
            Text(title)
            Image(systemName: "chevron.down")
                .font(.caption.weight(.semibold))
                .accessibilityHidden(true)
        }
    }
}

private extension View {
    /// A small glass button; tinted while its filter is on.
    @ViewBuilder
    func chipStyle(isActive: Bool) -> some View {
        let sized = controlSize(.small)
        if isActive {
            sized.prominentGlassButton()
        } else {
            sized.buttonStyle(.glass)
        }
    }
}
