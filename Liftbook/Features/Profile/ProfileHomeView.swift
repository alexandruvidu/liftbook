import SwiftUI

struct ProfileHomeView: View {
    @AppStorage(RestTimer.defaultSecondsKey) private var defaultRest = RestTimer.fallbackSeconds
    @AppStorage(RestTimer.soundKey) private var restSound = true

    var body: some View {
        NavigationStack {
            Form {
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
