import SwiftData
import SwiftUI

/// A pending create / rename / delete action on a routine folder.
enum FolderAction: Identifiable {
    case create
    case rename(RoutineFolder)
    case delete(RoutineFolder)

    var id: String {
        switch self {
        case .create: "create"
        case .rename(let folder): "rename-\(folder.folderID)"
        case .delete(let folder): "delete-\(folder.folderID)"
        }
    }
}

/// Section header for a folder, with a menu to rename or delete it.
struct FolderHeader: View {
    let folder: RoutineFolder
    let perform: (FolderAction) -> Void

    var body: some View {
        HStack {
            Label(folder.name, systemImage: "folder")
            Spacer()
            Menu {
                Button("Rename Folder", systemImage: "pencil") { perform(.rename(folder)) }
                Button("Delete Folder", systemImage: "trash", role: .destructive) { perform(.delete(folder)) }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .imageScale(.large)
                    .accessibilityLabel("Folder options")
            }
            .accessibilityIdentifier("folder.menu.\(folder.name)")
        }
    }
}

private struct FolderActionsModifier: ViewModifier {
    @Binding var action: FolderAction?
    let folderCount: Int

    @Environment(\.modelContext) private var modelContext
    @State private var name = ""

    private var isNaming: Binding<Bool> {
        Binding(
            get: { if case .delete = action { false } else { action != nil } },
            set: { if !$0 { action = nil } }
        )
    }

    private var isDeleting: Binding<Bool> {
        Binding(
            get: { if case .delete = action { true } else { false } },
            set: { if !$0 { action = nil } }
        )
    }

    func body(content: Content) -> some View {
        content
            .onChange(of: action?.id) {
                if case .rename(let folder) = action { name = folder.name } else { name = "" }
            }
            .alert(isRenaming ? "Rename Folder" : "New Folder", isPresented: isNaming) {
                TextField("Folder name", text: $name)
                    .accessibilityIdentifier("folder.name")
                Button("Cancel", role: .cancel) {}
                Button(isRenaming ? "Save" : "Create", action: saveName)
                    .disabled(trimmedName.isEmpty)
            }
            .confirmationDialog("Delete this folder?", isPresented: isDeleting, titleVisibility: .visible) {
                Button("Delete Folder", role: .destructive, action: deleteFolder)
            } message: {
                Text("Routines inside it are kept and move to Other Routines.")
            }
    }

    private var isRenaming: Bool {
        if case .rename = action { true } else { false }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func saveName() {
        guard !trimmedName.isEmpty else { return }
        switch action {
        case .create: modelContext.insert(RoutineFolder(name: trimmedName, sortIndex: folderCount))
        case .rename(let folder): folder.name = trimmedName
        default: break
        }
        action = nil
    }

    private func deleteFolder() {
        if case .delete(let folder) = action {
            modelContext.delete(folder)
        }
        action = nil
    }
}

extension View {
    func folderActions(_ action: Binding<FolderAction?>, folderCount: Int) -> some View {
        modifier(FolderActionsModifier(action: action, folderCount: folderCount))
    }
}
