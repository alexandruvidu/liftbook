import Charts
import SwiftData
import SwiftUI

/// One metric over time: a chart and every entry, newest first.
struct BodyMetricDetailView: View {
    let metric: BodyMetric

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BodyMeasurement.date) private var measurements: [BodyMeasurement]
    @AppStorage(WeightUnit.storageKey) private var unit: WeightUnit = .kilograms
    @State private var isAdding = false

    var body: some View {
        let history = BodyMetrics.history(of: metric.metricID, in: measurements)
        List {
            if history.isEmpty {
                Section {
                    Text("No entries yet. Tap + to log your first.")
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("body.empty")
                }
            } else {
                Section {
                    summary(history)
                    if history.count > 1 {
                        chart(history)
                            .frame(height: 180)
                            .accessibilityIdentifier("body.chart")
                    }
                }
                Section("Entries") {
                    ForEach(Array(history.reversed().enumerated()), id: \.element.persistentModelID) { index, entry in
                        LabeledContent(entry.date.formatted(date: .abbreviated, time: .omitted),
                                       value: metric.kind.formatted(entry.value, unit: unit))
                            .monospacedDigit()
                            .accessibilityIdentifier("body.entry.\(index)")
                    }
                    .onDelete { offsets in
                        let newestFirst = Array(history.reversed())
                        offsets.forEach { modelContext.delete(newestFirst[$0]) }
                        try? modelContext.save()
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(metric.name)
        .toolbar {
            Button("Log \(metric.name)", systemImage: "plus") { isAdding = true }
                .accessibilityIdentifier("body.add")
        }
        .sheet(isPresented: $isAdding) {
            AddBodyMeasurementView(metric: metric, last: history.last?.value)
        }
    }

    private func summary(_ history: [BodyMeasurement]) -> some View {
        let latest = history[history.count - 1]
        let change = BodyMetrics.lastChange(of: metric.metricID, in: measurements)
        return VStack(alignment: .leading, spacing: 2) {
            Text(metric.kind.formatted(latest.value, unit: unit))
                .font(.title2.weight(.semibold))
                .monospacedDigit()
            if let change {
                let shown = metric.kind.display(abs(change), unit: unit)
                Text("\(change >= 0 ? "+" : "−")\(SetMeasurement.decimal(shown)) \(metric.kind.symbol(unit: unit)) since the entry before")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("body.latest")
    }

    private func chart(_ history: [BodyMeasurement]) -> some View {
        Chart(history) { entry in
            let value = metric.kind.display(entry.value, unit: unit)
            LineMark(x: .value("Date", entry.date), y: .value(metric.name, value))
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.monotone)
            PointMark(x: .value("Date", entry.date), y: .value(metric.name, value))
                .symbolSize(64)
        }
        .foregroundStyle(Color.accentColor)
        .chartYScale(domain: .automatic(includesZero: false))
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) {
                AxisGridLine().foregroundStyle(Color.secondary.opacity(0.15))
                AxisValueLabel(format: .dateTime.day().month(.abbreviated))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) {
                AxisGridLine().foregroundStyle(Color.secondary.opacity(0.15))
                AxisValueLabel()
            }
        }
        .accessibilityLabel("\(metric.name) over time")
    }
}

/// Logs one value with a date.
private struct AddBodyMeasurementView: View {
    let metric: BodyMetric
    let last: Double?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage(WeightUnit.storageKey) private var unit: WeightUnit = .kilograms
    @State private var text = ""
    @State private var date = Date.now

    var body: some View {
        let value = SetInput.decimal(text)
        NavigationStack {
            Form {
                Section {
                    HStack {
                        TextField(last.map { SetMeasurement.decimal(metric.kind.display($0, unit: unit)) } ?? "Value", text: $text)
                            .keyboardType(.decimalPad)
                            .font(.title2)
                            .monospacedDigit()
                            .accessibilityIdentifier("body.value")
                        Text(metric.kind.symbol(unit: unit))
                            .foregroundStyle(.secondary)
                    }
                    DatePicker("Date", selection: $date, in: ...Date.now)
                        .accessibilityIdentifier("body.date")
                }
            }
            .keyboardDoneButton()
            .navigationTitle("Log \(metric.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let value else { return }
                        modelContext.insert(BodyMeasurement(metricID: metric.metricID,
                                                            value: metric.kind.stored(fromDisplay: value, unit: unit),
                                                            date: date))
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(value == nil)
                    .accessibilityIdentifier("body.save")
                }
            }
        }
    }
}
