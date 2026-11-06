import SwiftUI

/// "This week": workouts against the goal, the streak, and a bar per day
/// whose height shows the volume lifted.
struct WeekStrip: View {
    let week: WeekActivity

    var body: some View {
        let maxVolume = week.days.map(\.volume).max() ?? 0
        Block {
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
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(week.days, id: \.date) { day in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(day.volume > 0 ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.fill.secondary))
                            .frame(height: barHeight(day.volume, max: maxVolume))
                        Text(day.date.formatted(.dateTime.weekday(.narrow)))
                            .font(.caption2.weight(day.isToday ? .bold : .regular))
                            .foregroundStyle(day.isToday ? Color.primary : Color.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 72, alignment: .bottom)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(daysDescription)
        }
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

    private func barHeight(_ volume: Double, max: Double) -> CGFloat {
        guard volume > 0, max > 0 else { return 6 }
        return 12 + 42 * CGFloat(volume / max)
    }

    private var daysDescription: String {
        let trained = week.days.filter { $0.volume > 0 }
            .map { $0.date.formatted(.dateTime.weekday(.wide)) }
        return trained.isEmpty ? "No workouts yet this week" : "Trained on " + trained.joined(separator: ", ")
    }
}
