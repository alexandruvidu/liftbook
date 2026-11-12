import Charts
import SwiftUI

/// "This week": workouts against the goal, the streak, and a bar per day
/// whose height shows the volume lifted.
struct WeekStrip: View {
    let week: WeekActivity

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline) {
                    title
                    Spacer(minLength: 8)
                    status
                }
                VStack(alignment: .leading, spacing: 4) {
                    title
                    status
                }
            }
            Chart(week.days, id: \.date) { day in
                BarMark(x: .value("Day", day.date, unit: .day),
                        y: .value("Volume", day.volume))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(.rect(cornerRadius: 4))
                    .accessibilityLabel(day.date.formatted(.dateTime.weekday(.wide)))
                    .accessibilityValue(day.volume > 0 ? "Trained" : "Rest day")
            }
            .chartXAxis {
                AxisMarks(values: week.days.map(\.date)) { value in
                    AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
                        .font(.caption2.weight(isToday(value) ? .bold : .regular))
                        .foregroundStyle(isToday(value) ? Color.primary : Color.secondary)
                }
            }
            .chartYAxis(.hidden)
            .frame(height: 72)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("activity.week")
    }

    private var title: some View {
        Text("This week")
            .font(.headline)
    }

    private var status: some View {
        HStack(spacing: 6) {
            Text("\(week.workouts) of \(week.goal) workouts")
                .accessibilityIdentifier("goal.thisWeek")
            if week.streak > 0 {
                Text("· \(week.streak)-week streak")
                    .accessibilityIdentifier("goal.streak")
            }
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.tint)
    }

    private func isToday(_ value: AxisValue) -> Bool {
        guard let date = value.as(Date.self) else { return false }
        return week.days.first { Calendar.current.isDate($0.date, inSameDayAs: date) }?.isToday ?? false
    }
}
