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
                    NavigationLink {
                        BodyMetricDetailView(metric: metric)
                    } label: {
                        LabeledContent {
                            if let latest = BodyMetrics.history(of: metric.metricID, in: measurements).last {
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(metric.kind.formatted(latest.value, unit: unit))
                                        .monospacedDigit()
                                        .foregroundStyle(.primary)
                                    Text(latest.date.formatted(.dateTime.day().month(.abbreviated)))
                                        .font(.caption)
                                }
                            } else {
                                Text("No entries")
                            }
                        } label: {
                            Text(metric.name)
                        }
                    }
                    .accessibilityIdentifier("body.metric.\(metric.name)")
                }
                .onDelete { offsets in
                    for metric in offsets.map({ metrics[$0] }) where !metric.isBuiltIn {
                        for entry in measurements where entry.metricID == metric.metricID {
                            modelContext.delete(entry)
                        }
                        modelContext.delete(metric)
                    }
                    try? modelContext.save()
                }
            } footer: {
                Text("Track body weight, body fat or anything else, like your waist. Swipe left to delete a metric you added.")
            }
        }
        .listStyle(.insetGrouped)
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
