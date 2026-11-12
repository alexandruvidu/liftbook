import Charts
import SwiftData
import SwiftUI

/// Every body metric with its latest value. Opens from Profile.
struct BodyMeasurementsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BodyMetric.sortIndex) private var metrics: [BodyMetric]
    @Query(sort: \BodyMeasurement.date) private var measurements: [BodyMeasurement]
    @AppStorage(WeightUnit.storageKey) private var unit: WeightUnit = .kilograms
    @State private var isAddingMetric = false

    var body: some View {
        List {
            Section {
                ForEach(metrics) { metric in
                    let history = BodyMetrics.history(of: metric.metricID, in: measurements)
                    NavigationLink {
                        BodyMetricDetailView(metric: metric)
                    } label: {
                        MetricRow(metric: metric, history: history, unit: unit)
                    }
                    .accessibilityIdentifier("body.metric.\(metric.name)")
                    .swipeToDelete("Delete Metric", isEnabled: !metric.isBuiltIn,
                                   identifier: "body.metric.\(metric.name).delete") { delete(metric) }
                    .contextMenu {
                        if !metric.isBuiltIn {
                            Button("Delete Metric", systemImage: "trash", role: .destructive) { delete(metric) }
                        }
                    }
                }
            } footer: {
                Text("Track body weight, body fat or anything else, like your waist. Swipe left on a metric you added to delete it.")
            }
        }
        .navigationTitle("Body Measurements")
        .toolbar {
            Button("Add Metric", systemImage: "plus") { isAddingMetric = true }
                .accessibilityIdentifier("body.addMetric")
        }
        .sheet(isPresented: $isAddingMetric) {
            AddBodyMetricView(existing: metrics)
        }
        .task { BodyMetrics.ensureBuiltIns(in: modelContext) }
    }

    private func delete(_ metric: BodyMetric) {
        for entry in measurements where entry.metricID == metric.metricID {
            modelContext.delete(entry)
        }
        modelContext.delete(metric)
        try? modelContext.save()
    }
}

/// A metric's latest value and a small line of its history.
private struct MetricRow: View {
    let metric: BodyMetric
    let history: [BodyMeasurement]
    let unit: WeightUnit

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(metric.name)
                        .font(.headline)
                    if let latest = history.last {
                        Text(latest.date.formatted(.dateTime.day().month(.abbreviated)))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if let latest = history.last {
                    Text(metric.kind.formatted(latest.value, unit: unit))
                        .font(.title3.weight(.bold))
                        .monospacedDigit()
                } else {
                    Text("No entries")
                        .foregroundStyle(.secondary)
                }
            }
            if history.count > 1 {
                Chart(history, id: \.date) { entry in
                    LineMark(x: .value("Date", entry.date), y: .value(metric.name, entry.value))
                        .interpolationMethod(.monotone)
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .chartYScale(domain: .automatic(includesZero: false))
                .foregroundStyle(Color.accentColor)
                .frame(height: 44)
                .accessibilityHidden(true)
            }
        }
    }
}

/// Creates a custom metric with a name and a kind of value.
private struct AddBodyMetricView: View {
    let existing: [BodyMetric]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var kind: BodyMetricKind = .length

    var body: some View {
        let problem = BodyMetrics.problem(withName: name, existing: existing)
        NavigationStack {
            Form {
                Section {
                    TextField("Name, e.g. Waist", text: $name)
                        .accessibilityIdentifier("body.metricName")
                    Picker("Measured as", selection: $kind) {
                        ForEach(BodyMetricKind.allCases) { Text($0.displayName).tag($0) }
                    }
                    .accessibilityIdentifier("body.metricKind")
                } footer: {
                    if problem == .duplicateName {
                        Text("You already track something with this name.")
                    }
                }
            }
            .navigationTitle("New Metric")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let next = (existing.map(\.sortIndex).max() ?? 0) + 1
                        modelContext.insert(BodyMetric(name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                                                       kind: kind, sortIndex: next))
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(problem != nil)
                    .accessibilityIdentifier("body.saveMetric")
                }
            }
        }
    }
}
