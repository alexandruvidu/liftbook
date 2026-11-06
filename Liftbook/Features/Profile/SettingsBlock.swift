import SwiftUI

/// Units, weekly goal and rest timer, as compact rows in one block.
struct SettingsBlock: View {
    @AppStorage(RestTimer.defaultSecondsKey) private var defaultRest = RestTimer.fallbackSeconds
    @AppStorage(RestTimer.soundKey) private var restSound = true
    @AppStorage(WeightUnit.storageKey) private var unit: WeightUnit = .kilograms
    @AppStorage(WeeklyGoal.storageKey) private var weeklyGoal = WeeklyGoal.defaultGoal

    var body: some View {
        Block {
            row("Weight", systemImage: "scalemass",
                note: "How weights and distances are shown and entered. Logged sets stay the same.") {
                Picker("Weight", selection: $unit) {
                    Text("Kilograms (kg)").tag(WeightUnit.kilograms)
                    Text("Pounds (lb)").tag(WeightUnit.pounds)
                }
                .accessibilityIdentifier("settings.unit")
            }
            Divider()
            row("Weekly goal", systemImage: "target", note: "Workouts per week, for your week and streak in Activity.") {
                Stepper("\(weeklyGoal)", value: $weeklyGoal, in: WeeklyGoal.range)
                    .fixedSize()
                    .accessibilityLabel("Workouts per week, \(weeklyGoal)")
                    .accessibilityIdentifier("settings.goal")
            }
            Divider()
            row("Default rest", systemImage: "timer",
                note: "Starts when you check off a set; each exercise can set its own.") {
                Picker("Default Rest", selection: $defaultRest) {
                    ForEach(RestTimer.options, id: \.self) { seconds in
                        Text(RestTimer.label(seconds: seconds)).tag(seconds)
                    }
                }
                .accessibilityIdentifier("settings.restDefault")
            }
            Divider()
            Toggle(isOn: $restSound) {
                Label("Sound when rest ends", systemImage: "speaker.wave.2")
            }
            .accessibilityIdentifier("settings.restSound")
        }
        .pickerStyle(.menu)
    }

    private func row<Control: View>(_ title: String, systemImage: String, note: String,
                                    @ViewBuilder control: () -> Control) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ViewThatFits(in: .horizontal) {
                HStack {
                    Label(title, systemImage: systemImage)
                    Spacer(minLength: 8)
                    control()
                }
                VStack(alignment: .leading, spacing: 6) {
                    Label(title, systemImage: systemImage)
                    control()
                }
            }
            Text(note)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
