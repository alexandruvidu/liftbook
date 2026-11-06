import SwiftUI

/// The note for the whole workout, edited in a sheet.
struct WorkoutNoteSheet: View {
    @Bindable var session: WorkoutSession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            TextField("How did it go?", text: $session.notes, axis: .vertical)
                .lineLimit(3...10)
                .padding(14)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
                .padding(16)
                .frame(maxHeight: .infinity, alignment: .top)
                .blockScreenBackground()
                .accessibilityIdentifier("live.notes")
                .navigationTitle("Workout Note")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                            .accessibilityIdentifier("live.notesDone")
                    }
                }
        }
        .presentationDetents([.medium])
    }
}
