import SwiftUI

/// Shown after finishing: duration, volume, sets and any new records.
struct FinishSummaryView: View {
    let session: WorkoutSession
    let summary: WorkoutSummary
    let catalog: ExerciseCatalog
    @AppStorage(WeightUnit.storageKey) private var unit: WeightUnit = .kilograms
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
                    StatTile(title: "Volume", value: volumeText, identifier: "summary.volume")
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
                                    Text(record.kind.title)
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

    private var volumeText: String {
        let value = unit.display(kilograms: summary.volume)
        return "\(value.formatted(.number.precision(.fractionLength(0)))) \(unit.symbol)"
    }

    private func recordValue(_ record: WorkoutSummary.Record) -> String {
        switch record.kind {
        case .heaviestWeight, .bestOneRepMax: "\(SetMeasurement.number(record.value, unit: unit)) \(unit.symbol)"
        case .mostReps: "\(Int(record.value)) reps"
        }
    }
}

private struct StatTile: View {
    let title: String
    let value: String
    let identifier: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.weight(.semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(identifier)
    }
}
