import SwiftUI

/// Muscle and equipment filter chips shown above the exercise list.
struct ExerciseFilterBar: View {
    @Binding var filter: ExerciseFilter
    let resultCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
                        FilterChip(title: filter.muscle?.displayName ?? "Muscle", isActive: filter.muscle != nil)
                    }
                    .accessibilityIdentifier("exercises.filter.muscle")

                    Menu {
                        Picker("Equipment", selection: $filter.equipment) {
                            Text("Any Equipment").tag(Equipment?.none)
                            ForEach(Equipment.allCases) { equipment in
                                Text(equipment.displayName).tag(Optional(equipment))
                            }
                        }
                    } label: {
                        FilterChip(title: filter.equipment?.displayName ?? "Equipment", isActive: filter.equipment != nil)
                    }
                    .accessibilityIdentifier("exercises.filter.equipment")

                    if filter.hasMenuFilters {
                        Button {
                            filter.clearMenuFilters()
                        } label: {
                            Label("Clear", systemImage: "xmark")
                                .font(.subheadline.weight(.medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.tint)
                        .accessibilityIdentifier("exercises.filter.clear")
                    }
                }
                .padding(.horizontal, 20)
            }

            Text(resultCount == 1 ? "1 exercise" : "\(resultCount) exercises")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
                .accessibilityIdentifier("exercises.resultCount")
        }
    }
}

private struct FilterChip: View {
    let title: String
    let isActive: Bool

    var body: some View {
        HStack(spacing: 4) {
            Text(title)
            Image(systemName: "chevron.down")
                .font(.caption.weight(.semibold))
        }
        .font(.subheadline.weight(.medium))
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .foregroundStyle(isActive ? Color.accentForeground : Color.primary)
        .background(
            Capsule().fill(isActive ? Color.accentColor : Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            Capsule().strokeBorder(Color(.separator), lineWidth: isActive ? 0 : 0.5)
        )
        .contentShape(Capsule())
    }
}
