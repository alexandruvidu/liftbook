import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// Pick a backup (one saved on the phone, or any JSON backup file) and
/// replace all data with it.
struct RestoreBackupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var files: [AutoBackup.File] = []
    // Fetched once, not a @Query: pushed from DataTransferView, a @Query here
    // kept invalidating the parent's @Query and the push hung in an update loop.
    @State private var isWorkoutRunning = false
    /// The listed backup or the chosen file waiting for confirmation; each
    /// anchors its own dialog so the popover points at the tapped row.
    @State private var pending: URL?
    @State private var chosen: URL?
    @State private var isChoosingFile = false
    @State private var message: (title: String, text: String, done: Bool)?

    var body: some View {
        Form {
            if isWorkoutRunning {
                Section {
                    Label("Finish or discard the workout in progress before restoring.", systemImage: "exclamationmark.triangle")
                        .accessibilityIdentifier("restore.workoutRunning")
                }
            }

            Section {
                if files.isEmpty {
                    Text("No backups yet.")
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("restore.empty")
                }
                ForEach(files) { file in
                    Button {
                        pending = file.url
                    } label: {
                        // Plain texts, not LabeledContent: with an empty value it
                        // dropped the row's button trait and identifier.
                        HStack {
                            Text(file.date.formatted(date: .abbreviated, time: .shortened))
                                .foregroundStyle(Color.primary)
                            Spacer()
                            if file.isSafetyCopy {
                                Text("Before restore").foregroundStyle(Color.secondary)
                            }
                        }
                    }
                    .accessibilityIdentifier("restore.file")
                    .confirmRestore(of: file.url, pending: $pending, restore: restore)
                }
            } header: {
                Text("On This iPhone")
            } footer: {
                Text("From Files › On My iPhone › Liftbook › Backups, newest first.")
            }

            Section {
                Button("Choose a Backup File…", systemImage: "folder") { isChoosingFile = true }
                    .accessibilityIdentifier("restore.chooseFile")
                    .confirmRestore(of: chosen, pending: $chosen, restore: restore)
            } footer: {
                Text("Restoring replaces everything in Liftbook with the backup. Your current data is saved to the Backups folder first.")
            }
        }
        .disabled(isWorkoutRunning)
        .navigationTitle("Restore Backup")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            files = AutoBackup.files()
            let running = FetchDescriptor<WorkoutSession>(predicate: #Predicate { $0.endedAt == nil })
            isWorkoutRunning = ((try? modelContext.fetchCount(running)) ?? 0) > 0
        }
        .fileImporter(isPresented: $isChoosingFile, allowedContentTypes: [.json]) { result in
            if case .success(let url) = result { chosen = url }
        }
        .alert(message?.title ?? "", isPresented: Binding { message != nil } set: { if !$0 { message = nil } },
               presenting: message) { message in
            Button("OK", role: .cancel) { if message.done { dismiss() } }
        } message: { message in
            Text(message.text)
        }
    }

    private func restore(_ url: URL) {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            let summary = try AutoBackup.restore(from: url, into: modelContext)
            message = ("Backup Restored",
                       "\(summary.workouts) workout\(summary.workouts == 1 ? "" : "s") and \(summary.routines) routine\(summary.routines == 1 ? "" : "s").",
                       true)
        } catch {
            message = ("Couldn't Restore", error.localizedDescription, false)
        }
        files = AutoBackup.files()
    }
}

private extension View {
    /// Asks before replacing all data with the backup at `url`, while `pending` is that URL.
    func confirmRestore(of url: URL?, pending: Binding<URL?>, restore: @escaping (URL) -> Void) -> some View {
        confirmationDialog("Replace all data with this backup?",
                           isPresented: Binding { url != nil && pending.wrappedValue == url } set: { if !$0 { pending.wrappedValue = nil } },
                           titleVisibility: .visible) {
            Button("Restore Backup", role: .destructive) {
                if let url { restore(url) }
            }
            .accessibilityIdentifier("restore.confirm")
        } message: {
            Text("Workouts, routines, exercises, machines and body measurements are replaced. Your current data is saved first.")
        }
    }
}
