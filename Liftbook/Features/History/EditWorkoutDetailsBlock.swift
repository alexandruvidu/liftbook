import SwiftUI

/// A finished workout's name, start, length and notes while editing it.
struct EditWorkoutDetailsBlock: View {
    @Bindable var session: WorkoutSession

    var body: some View {
        Block {
            TextField("Name", text: $session.name)
                .font(.headline)
                .accessibilityIdentifier("edit.name")
            Divider()
            DatePicker("Started", selection: Binding(get: { session.startedAt }, set: { session.moveStart(to: $0) }))
                .accessibilityIdentifier("edit.start")
            Divider()
            Stepper(value: Binding(get: { session.durationMinutes }, set: { session.setDuration(minutes: $0) }),
                    in: 1...(24 * 60), step: 5) {
                LabeledContent("Duration", value: "\(session.durationMinutes) min")
            }
            .accessibilityIdentifier("edit.duration")
            Divider()
            TextField("Workout notes", text: $session.notes, axis: .vertical)
                .lineLimit(1...6)
                .accessibilityIdentifier("edit.notes")
        }
    }
}
