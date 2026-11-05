import Charts
import SwiftUI

/// Horizontal bars of working sets (or volume) per muscle group for a week.
/// One hue: the bars encode magnitude only, and each is labeled.
struct WeeklyMuscleChart: View {
    let sessions: [WorkoutSession]
    let catalog: ExerciseCatalog

    private let model = MuscleVolume()
    @AppStorage(WeightUnit.storageKey) private var unit: WeightUnit = .kilograms
    @State private var week = MuscleVolume().week(containing: .now)
    @State private var measure: MuscleVolume.Measure = .sets

    var body: some View {
        let entries = model.entries(for: week, in: sessions) { catalog.exercise(id: $0) }
        Section {
            weekHeader
            Picker("Measure", selection: $measure) {
                ForEach(MuscleVolume.Measure.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("weekly.measure")

            if entries.isEmpty {
                Text("No working sets logged this week.")
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("weekly.empty")
            } else {
                chart(entries)
                    .frame(height: CGFloat(entries.count) * 48)
                    .accessibilityIdentifier("weekly.chart")
            }
        } header: {
            Text("Weekly Muscle Groups")
        } footer: {
            Text("Each completed working set counts for every primary muscle of its exercise.")
        }
    }

    private var weekHeader: some View {
        HStack {
            Button("Previous Week", systemImage: "chevron.left") { week = model.week(week, offsetBy: -1) }
                .labelStyle(.iconOnly)
                .accessibilityIdentifier("weekly.previous")
            Spacer()
            Text(weekTitle)
                .font(.headline)
                .accessibilityIdentifier("weekly.title")
            Spacer()
            Button("Next Week", systemImage: "chevron.right") { week = model.week(week, offsetBy: 1) }
                .labelStyle(.iconOnly)
                .disabled(week.contains(.now))
                .accessibilityIdentifier("weekly.next")
        }
        .buttonStyle(.borderless)
    }

    private var weekTitle: String {
        if week.contains(.now) { return "This Week" }
        let last = week.end.addingTimeInterval(-1)
        return "\(week.start.formatted(.dateTime.day().month(.abbreviated))) – \(last.formatted(.dateTime.day().month(.abbreviated)))"
    }

    private func value(_ entry: MuscleVolume.Entry) -> Double {
        measure == .sets ? Double(entry.sets) : unit.display(kilograms: entry.volume)
    }

    private func label(_ entry: MuscleVolume.Entry) -> String {
        measure == .sets
            ? "\(entry.sets)"
            : "\(unit.display(kilograms: entry.volume).formatted(.number.precision(.fractionLength(0)))) \(unit.symbol)"
    }

    private func chart(_ entries: [MuscleVolume.Entry]) -> some View {
        let sorted = measure == .sets ? entries : entries.sorted { $0.volume > $1.volume }
        return Chart(sorted) { entry in
            BarMark(x: .value(measure.rawValue, value(entry)),
                    y: .value("Muscle", entry.muscle.displayName),
                    height: .fixed(16))
                .clipShape(UnevenRoundedRectangle(bottomTrailingRadius: 4, topTrailingRadius: 4))
                .foregroundStyle(Color.accentColor)
                // The muscle name sits above its bar; the value at its end.
                .annotation(position: .top, alignment: .leading, spacing: 4) {
                    Text(entry.muscle.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
                .annotation(position: .trailing, spacing: 6) {
                    Text(label(entry))
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel(entry.muscle.displayName)
                .accessibilityValue(label(entry))
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartXScale(domain: 0...(sorted.map(value).max() ?? 1) * 1.25)
    }
}
