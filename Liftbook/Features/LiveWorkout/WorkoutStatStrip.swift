import SwiftUI

/// Time, volume and sets for the workout in progress.
struct WorkoutStatStrip: View {
    let session: WorkoutSession
    let stats: WorkoutStats
    @AppStorage(WeightUnit.storageKey) private var unit: WeightUnit = .kilograms

    var body: some View {
        HStack(spacing: 8) {
            // A timer-style Text ticks on its own without re-rendering the
            // screen, so open menus and focused fields aren't disturbed.
            tile("Time", value: Text(session.startedAt, style: .timer), id: "live.stat.time", accent: true)
            tile("Volume", value: Text(unit.volumeText(kilograms: stats.volume)), id: "live.stat.volume")
            tile("Sets", value: Text("\(stats.completedSets) / \(stats.totalSets)"), id: "live.stat.sets")
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    private func tile(_ title: String, value: Text, id: String, accent: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            value
                .font(.title3.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(accent ? AnyShapeStyle(.tint) : AnyShapeStyle(.primary))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(id)
    }
}
