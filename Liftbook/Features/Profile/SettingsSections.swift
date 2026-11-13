import SwiftUI

/// Units, weekly goal and rest timer, as list sections with explanatory footers.
struct SettingsSections: View {
    @AppStorage(RestTimer.defaultSecondsKey) private var defaultRest = RestTimer.fallbackSeconds
    @AppStorage(RestTimer.soundKey) private var restSound = true
    @AppStorage(RestTimer.keepScreenOnKey) private var keepScreenOn = false
    @AppStorage(WeightUnit.storageKey) private var unit: WeightUnit = .kilograms
    @AppStorage(WeeklyGoal.storageKey) private var weeklyGoal = WeeklyGoal.defaultGoal

    var body: some View {
        Section {
            Picker(selection: $unit) {
                Text("Kilograms (kg)").tag(WeightUnit.kilograms)
                Text("Pounds (lb)").tag(WeightUnit.pounds)
            } label: {
                Label("Weight", systemImage: "scalemass")
            }
            .accessibilityIdentifier("settings.unit")
            Stepper(value: $weeklyGoal, in: WeeklyGoal.range) {
                LabeledContent {
                    Text("\(weeklyGoal)")
                        .monospacedDigit()
                } label: {
                    Label("Weekly Goal", systemImage: "target")
                }
            }
            .accessibilityLabel("Workouts per week, \(weeklyGoal)")
            .accessibilityIdentifier("settings.goal")
        } header: {
            Text("Settings")
        } footer: {
            Text("Weights and distances are shown in this unit; logged sets stay the same. The weekly goal counts workouts per week for your week and streak in Activity.")
        }

        Section {
            Picker(selection: $defaultRest) {
                ForEach(RestTimer.options, id: \.self) { seconds in
                    Text(RestTimer.label(seconds: seconds)).tag(seconds)
                }
            } label: {
                Label("Default Rest", systemImage: "timer")
            }
            .accessibilityIdentifier("settings.restDefault")
            Toggle(isOn: $restSound) {
                Label("Sound When Rest Ends", systemImage: "speaker.wave.2")
            }
            .accessibilityIdentifier("settings.restSound")
            Toggle(isOn: $keepScreenOn) {
                Label("Keep Screen On", systemImage: "sun.max")
            }
            .accessibilityIdentifier("settings.keepScreenOn")
        } header: {
            Text("Workout")
        } footer: {
            Text((defaultRest == 0
                  ? "Off: no timer after a set, unless an exercise sets its own."
                  : "Rest starts when you check off a set; each exercise can set its own. Your phone also taps when it ends.")
                 + " Keep Screen On stops the screen locking while a workout is open.")
        }
    }
}
