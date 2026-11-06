import SwiftData
import SwiftUI

/// Shown after finishing: duration, volume, sets and any new records.
struct FinishSummaryView: View {
    let session: WorkoutSession
    let summary: WorkoutSummary
    let catalog: ExerciseCatalog
    @AppStorage(WeightUnit.storageKey) private var unit: WeightUnit = .kilograms
    @Query private var machines: [Machine]
    let onDone: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(Color.accentColor)
                        .accessibilityHidden(true)
                    Text("Workout Complete")
                        .font(.title.bold())
                    Text("\(session.name) · \(session.startedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)

                HStack(spacing: 12) {
                    StatTile(title: "Duration", value: SetMeasurement.clock(summary.duration), identifier: "summary.duration")
                    StatTile(title: "Volume", value: unit.volumeText(kilograms: summary.volume), identifier: "summary.volume")
                    StatTile(title: "Sets", value: "\(summary.setCount)", identifier: "summary.sets")
                }

                if !summary.records.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("New Records", systemImage: "trophy.fill")
                            .font(.headline)
                        ForEach(Array(summary.records.enumerated()), id: \.element) { index, record in
                            HStack(alignment: .firstTextBaseline) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(catalog.name(for: record.exerciseID))
                                        .font(.subheadline.weight(.semibold))
                                    Text(recordTitle(record))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(recordValue(record))
                                    .font(.subheadline.weight(.semibold))
                                    .monospacedDigit()
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityIdentifier("summary.record.\(index)")
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
                } else if summary.setCount == 0 {
                    Text("No sets were checked off, so this workout won't count towards your totals.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Text("Saved to your history.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
        }
        .safeAreaInset(edge: .bottom) {
            Button(action: onDone) {
                Text("Done")
                    .font(.headline)
                    .foregroundStyle(Color.accentForeground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .padding(16)
            .accessibilityIdentifier("summary.done")
        }
        .background(Color(.systemGroupedBackground))
    }

    /// "Heaviest weight", or "Heaviest weight on Plate-loaded" for a machine.
    private func recordTitle(_ record: WorkoutSummary.Record) -> String {
        guard let machine = machines.name(for: record.machineID) else { return record.kind.title }
        return "\(record.kind.title) on \(machine)"
    }

    private func recordValue(_ record: WorkoutSummary.Record) -> String {
        record.kind.formatted(record.value, unit: unit)
    }
}
