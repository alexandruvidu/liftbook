import SwiftUI

/// Shown instead of the app when the data store can't be opened: restore the
/// newest backup, or start with no data. Either way the unreadable files are
/// kept in Damaged Data.
struct StoreRecoveryView: View {
    let store: DataStore

    @State private var latest = StoreRecovery.latestBackup()
    @State private var isConfirmingEmpty = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 10) {
                        Image(systemName: "externaldrive.badge.exclamationmark")
                            .font(.system(size: 44))
                            .foregroundStyle(.orange)
                            .accessibilityHidden(true)
                        Text("Liftbook Can't Open Your Data")
                            .font(.title2.bold())
                        Text("The data on this iPhone couldn't be read. Restore your latest backup, or start again with no data.")
                            .foregroundStyle(.secondary)
                    }
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("recovery.header")
                }

                Section("Backup") {
                    if let latest {
                        LabeledContent("Latest Backup", value: latest.date.formatted(date: .abbreviated, time: .shortened))
                            .accessibilityIdentifier("recovery.latest")
                    } else {
                        Text("No backups in Files › On My iPhone › Liftbook › Backups.")
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("recovery.noBackup")
                    }
                }

                if let latest {
                    // Its own section, so the button doesn't cut off the card above.
                    Section {
                        Button {
                            restore(latest)
                        } label: {
                            Label("Restore Latest Backup", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                                .frame(maxWidth: .infinity)
                        }
                        .prominentGlassButton()
                        .controlSize(.large)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .accessibilityIdentifier("recovery.restore")
                    } footer: {
                        Text("Your data comes back as it was at that backup, with its photos and settings.")
                    }
                }

                Section {
                    Button("Start Empty", systemImage: "square.dashed", role: .destructive) { isConfirmingEmpty = true }
                        .accessibilityIdentifier("recovery.startEmpty")
                } footer: {
                    Text("Either way, the unreadable data is kept in Files › On My iPhone › Liftbook › Damaged Data, and you can still restore a backup later from Profile › Data.")
                }

                if let failure = store.failure {
                    Section("Details") {
                        Text(failure)
                            .font(.footnote.monospaced())
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                            .lineLimit(6)
                    }
                }
            }
            .navigationTitle("Recovery")
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Start with no data?", isPresented: $isConfirmingEmpty, titleVisibility: .visible) {
                Button("Start Empty", role: .destructive) { run { try store.startEmpty() } }
                    .accessibilityIdentifier("recovery.confirmEmpty")
            } message: {
                Text("Liftbook opens with no workouts, routines or photos.")
            }
            .alert("Couldn't Recover", isPresented: Binding { error != nil } set: { if !$0 { error = nil } }) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(error ?? "")
            }
        }
    }

    private func restore(_ file: AutoBackup.File) {
        run { try store.restore(file) }
    }

    /// Runs a recovery step; on success the app replaces this screen.
    private func run(_ step: () throws -> Void) {
        do {
            try step()
        } catch {
            self.error = error.localizedDescription
            latest = StoreRecovery.latestBackup()
        }
    }
}
