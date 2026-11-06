import Charts
import SwiftData
import SwiftUI

/// Line chart of an exercise over time: estimated 1RM, max weight or volume.
/// One series in the accent color, touch a point to read its exact value.
struct ExerciseProgressChart: View {
    let exerciseID: String
    var machine: MachineFilter = .all

    @Query(filter: #Predicate<WorkoutSession> { $0.endedAt != nil })
    private var sessions: [WorkoutSession]
    @AppStorage(WeightUnit.storageKey) private var unit: WeightUnit = .kilograms
    @State private var metric: ExerciseProgress.Metric = .oneRepMax
    @State private var selectedDate: Date?

    var body: some View {
        let points = ExerciseProgress.points(for: exerciseID, metric: metric, machine: machine, in: sessions)
            .map { ExerciseProgress.Point(date: $0.date, value: unit.display(kilograms: $0.value)) }
        Section {
            Picker("Metric", selection: $metric) {
                ForEach(ExerciseProgress.Metric.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("progress.metric")

            if points.isEmpty {
                Text("Finish a workout with this exercise to start the chart.")
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("progress.chart.empty")
            } else {
                header(points)
                chart(points)
                    .frame(height: 200)
                    .accessibilityIdentifier("progress.chart")
            }
        } header: {
            Text("Progress")
        }
    }

    private func header(_ points: [ExerciseProgress.Point]) -> some View {
        let shown = selected(in: points) ?? points.last!
        return VStack(alignment: .leading, spacing: 2) {
            Text("\(format(shown.value)) \(unit.symbol)")
                .font(.title2.weight(.semibold))
                .monospacedDigit()
            HStack(spacing: 6) {
                Text(shown.date.formatted(.dateTime.day().month(.abbreviated).year()))
                if selected(in: points) == nil, let change = ExerciseProgress.change(in: points) {
                    Text("\(change >= 0 ? "+" : "−")\(format(abs(change))) \(unit.symbol) since \(points.first!.date.formatted(.dateTime.day().month(.abbreviated)))")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("progress.value")
    }

    private func chart(_ points: [ExerciseProgress.Point]) -> some View {
        Chart {
            ForEach(points) { point in
                LineMark(x: .value("Date", point.date), y: .value(metric.title, point.value))
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.monotone)
                PointMark(x: .value("Date", point.date), y: .value(metric.title, point.value))
                    .symbolSize(64)
                    .accessibilityLabel(point.date.formatted(date: .abbreviated, time: .omitted))
                    .accessibilityValue("\(format(point.value)) \(unit.symbol)")
            }
            if let selection = selected(in: points) {
                RuleMark(x: .value("Selected", selection.date))
                    .foregroundStyle(Color.secondary.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 1))
            }
        }
        .foregroundStyle(Color.accentColor)
        .chartYScale(domain: .automatic(includesZero: metric == .volume))
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
        .chartXSelection(value: $selectedDate)
        .accessibilityLabel(metric.description)
    }

    /// The point nearest the touched date.
    private func selected(in points: [ExerciseProgress.Point]) -> ExerciseProgress.Point? {
        guard let selectedDate else { return nil }
        return points.min { abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate)) }
    }

    private func format(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)))
    }
}
