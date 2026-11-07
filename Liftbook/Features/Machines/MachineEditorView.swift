import PhotosUI
import SwiftData
import SwiftUI

/// Adds or edits a machine: its name, where it is, and a photo.
struct MachineEditorView: View {
    let exerciseID: String
    var machine: Machine?
    var onSave: (Machine) -> Void = { _ in }

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var location = ""
    @State private var photo: UIImage?
    @State private var pickerItem: PhotosPickerItem?
    @State private var isConfirmingDelete = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    photoArea
                        .listRowInsets(EdgeInsets())
                }
                Section {
                    TextField("Name, e.g. Plate-loaded", text: $name)
                        .textInputAutocapitalization(.sentences)
                        .accessibilityIdentifier("machine.name")
                    TextField("Where it is (optional)", text: $location)
                        .accessibilityIdentifier("machine.location")
                } footer: {
                    Text("Each machine keeps its own history, so last time's weights match the one you're on.")
                }
                if machine != nil {
                    Section {
                        Button("Delete Machine", role: .destructive) { isConfirmingDelete = true }
                            .accessibilityIdentifier("machine.delete")
                    } footer: {
                        Text("Workouts logged on it are kept.")
                    }
                }
            }
            .navigationTitle(machine == nil ? "New Machine" : "Edit Machine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                        .accessibilityIdentifier("machine.save")
                }
            }
            .confirmationDialog("Delete this machine?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
                Button("Delete Machine", role: .destructive) { delete() }
                    .accessibilityIdentifier("machine.confirmDelete")
            }
            .onAppear {
                guard let machine else { return }
                name = machine.name
                location = machine.location
                photo = machine.photoFileName.flatMap(PhotoStore.machines.load)
            }
            .onChange(of: pickerItem) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                        photo = image
                    }
                }
            }
        }
    }

    private var photoArea: some View {
        PhotosPicker(selection: $pickerItem, matching: .images) {
            ZStack {
                Color(.tertiarySystemFill)
                if let photo {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                } else {
                    VStack(spacing: 6) {
                        Image(systemName: "camera")
                            .font(.title)
                        Text("Add a photo")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.tint)
                }
            }
            .frame(height: 200)
            .clipped()
        }
        .accessibilityLabel(photo == nil ? "Add a photo" : "Change photo")
        .accessibilityIdentifier("machine.photo")
    }

    private func save() {
        let target = machine ?? Machine(exerciseID: exerciseID, name: name)
        target.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        target.location = location.trimmingCharacters(in: .whitespacesAndNewlines)
        if let photo, pickerItem != nil {
            if let old = target.photoFileName { PhotoStore.machines.delete(old) }
            target.photoFileName = try? PhotoStore.machines.save(photo)
        }
        if machine == nil { modelContext.insert(target) }
        try? modelContext.save()
        onSave(target)
        dismiss()
    }

    private func delete() {
        guard let machine else { return }
        try? Machine.delete(machine, in: modelContext)
        dismiss()
    }
}
