import SwiftUI

struct ProfileHomeView: View {
    @AppStorage(RestTimer.defaultSecondsKey) private var defaultRest = RestTimer.fallbackSeconds
    @AppStorage(RestTimer.soundKey) private var restSound = true
    @AppStorage(WeightUnit.storageKey) private var unit: WeightUnit = .kilograms
    @AppStorage(WeeklyGoal.storageKey) private var weeklyGoal = WeeklyGoal.defaultGoal

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    NavigationLink {
                        BodyMeasurementsView()
                    } label: {
                        Label("Body Measurements", systemImage: "figure")
                    }
                    .accessibilityIdentifier("profile.body")
                    NavigationLink {
                        ProgressPhotosView()
                    } label: {
                        Label("Progress Photos", systemImage: "photo.on.rectangle")
                    }
                    .accessibilityIdentifier("profile.photos")
                }

                Section("Data") {
                    NavigationLink {
                        DataTransferView()
                    } label: {
                        Label("Export & Import", systemImage: "arrow.up.arrow.down.square")
                    }
                    .accessibilityIdentifier("profile.data")
                }

                Section("Tools") {
                    NavigationLink {
                        PlateCalculatorView()
                    } label: {
                        Label("Plate Calculator", systemImage: "scalemass")
                    }
                    .accessibilityIdentifier("profile.plates")
                    NavigationLink {
                        WarmUpCalculatorView()
                    } label: {
                        Label("Warm-up Calculator", systemImage: "flame")
                    }
                    .accessibilityIdentifier("profile.warmup")
                }

                Section {
                    Picker("Weight", selection: $unit) {
                        Text("Kilograms (kg)").tag(WeightUnit.kilograms)
                        Text("Pounds (lb)").tag(WeightUnit.pounds)
                    }
                    .accessibilityIdentifier("settings.unit")
                } header: {
                    Text("Units")
                } footer: {
                    Text("Changes how weights and distances are shown and entered. Your logged sets stay the same.")
                }

                Section {
                    Stepper(value: $weeklyGoal, in: WeeklyGoal.range) {
                        LabeledContent("Workouts per Week", value: "\(weeklyGoal)")
                    }
                    .accessibilityIdentifier("settings.goal")
                } header: {
                    Text("Weekly Goal")
                } footer: {
                    Text("Used for your weekly progress and streak on the Progress tab.")
                }

                Section {
                    Picker("Default Rest", selection: $defaultRest) {
                        ForEach(RestTimer.options, id: \.self) { seconds in
                            Text(RestTimer.label(seconds: seconds)).tag(seconds)
                        }
                    }
                    .accessibilityIdentifier("settings.restDefault")
                    Toggle("Sound When Rest Ends", isOn: $restSound)
                        .accessibilityIdentifier("settings.restSound")
                } header: {
                    Text("Rest Timer")
                } footer: {
                    Text("The timer starts when you check off a set. Each exercise can use its own rest from the live workout. If you leave the app, a notification tells you when rest is over.")
                }

                Section {
                    Label("Everything you log stays on this iPhone.", systemImage: "lock.iphone")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(AppTab.profile.title)
        }
    }
}

#Preview {
    ProfileHomeView()
}
