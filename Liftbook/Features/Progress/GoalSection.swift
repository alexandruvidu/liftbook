import SwiftUI

/// This week's workouts against the weekly goal, and the week streak.
struct GoalSection: View {
    let sessions: [WorkoutSession]

    @AppStorage(WeeklyGoal.storageKey) private var goal = WeeklyGoal.defaultGoal
    private let model = WeeklyGoal()

    var body: some View {
        let done = model.workouts(inWeekOf: .now, sessions: sessions)
        let streak = model.currentStreak(goal: goal, sessions: sessions)
        let best = model.bestStreak(goal: goal, sessions: sessions)
        Section {
            HStack(spacing: 16) {
                Gauge(value: Double(min(done, goal)), in: 0...Double(goal)) {
                    EmptyView()
                } currentValueLabel: {
                    Text("\(done)/\(goal)")
                        .font(.headline)
                        .monospacedDigit()
                }
                .gaugeStyle(.accessoryCircularCapacity)
                .tint(Color.accentColor)
                .scaleEffect(1.2)
                .frame(width: 72, height: 72)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(done >= goal ? "Weekly goal met" : "\(goal - done) more this week")
                        .font(.headline)
                        .accessibilityIdentifier("goal.thisWeek")
                    Text("\(done) of \(goal) workouts")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Label(streakText(streak), systemImage: "flame.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(streak > 0 ? Color.orange : Color.secondary)
                        .accessibilityIdentifier("goal.streak")
                    if best > streak {
                        Text("Best: \(best) week\(best == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("goal.best")
                    }
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Weekly Goal")
        } footer: {
            Text("Change your goal in Profile. A week counts towards the streak when you reach the goal.")
        }
    }

    private func streakText(_ weeks: Int) -> String {
        weeks == 0 ? "No streak yet" : "\(weeks)-week streak"
    }
}
