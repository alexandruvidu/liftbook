import SwiftUI

/// A routine's name, folder and notes, like a workout's title area.
struct RoutineDetailsBlock: View {
    @Binding var draft: RoutineDraft
    let folders: [RoutineFolder]

    var body: some View {
        Block {
            TextField("Routine name", text: $draft.name)
                .font(.title3.weight(.bold))
                .textInputAutocapitalization(.words)
                .accessibilityIdentifier("routine.name")
            Divider()
            LabeledContent {
                Picker("Folder", selection: $draft.folderID) {
                    Text("None").tag(UUID?.none)
                    ForEach(folders) { Text($0.name).tag(Optional($0.folderID)) }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .accessibilityIdentifier("routine.folder")
            } label: {
                Label("Folder", systemImage: "folder")
            }
            Divider()
            TextField("Notes (optional)", text: $draft.notes, axis: .vertical)
                .lineLimit(1...6)
                .accessibilityIdentifier("routine.notes")
        }
    }
}
