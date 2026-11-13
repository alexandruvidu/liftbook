import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// Export workouts as CSV or everything as JSON, and import workouts from CSV.
struct DataTransferView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<WorkoutSession> { $0.endedAt != nil }) private var sessions: [WorkoutSession]
    @Query private var customExercises: [CustomExercise]

    @State private var csvURL: URL?
    @State private var jsonURL: URL?
    @State private var exportError: String?
    @State private var isImporting = false
    @State private var importMessage: String?
    @AppStorage(AutoBackup.enabledKey) private var autoBackup = true
    @AppStorage(AutoBackup.lastDateKey) private var lastBackup: Date?
    @State private var backupError: String?

    private var catalog: ExerciseCatalog {
        ExerciseCatalog(custom: customExercises.map(\.asLibraryExercise))
    }

    var body: some View {
        Form {
            Section {
                HStack(spacing: 8) {
                    StatTile(title: "Workouts", value: "\(sessions.count)", identifier: "data.workoutCount")
                    StatTile(title: "Sets", value: "\(sessions.reduce(0) { $0 + $1.exercises.reduce(0) { $0 + $1.sets.count } })",
                             identifier: "data.setCount")
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            Section {
                if let csvURL {
                    ShareLink(item: csvURL) {
                        Label("Export Workouts (CSV)", systemImage: "tablecells")
                    }
                    .accessibilityIdentifier("data.exportCSV")
                }
                if let jsonURL {
                    ShareLink(item: jsonURL) {
                        Label("Export Full Backup (JSON)", systemImage: "curlybraces")
                    }
                    .accessibilityIdentifier("data.exportJSON")
                }
                if let exportError {
                    Text(exportError).foregroundStyle(.red)
                }
            } header: {
                Text("Export")
            } footer: {
                Text("CSV has one row per set and opens in any spreadsheet. The JSON backup also includes routines, custom exercises, machines and body measurements. Photos and videos aren't included.")
            }

            Section {
                Toggle(isOn: $autoBackup) {
                    Label("Weekly Backup", systemImage: "clock.arrow.circlepath")
                }
                .accessibilityIdentifier("data.autoBackup")
                Button {
                    do {
                        try AutoBackup.backUp(from: modelContext)
                        backupError = nil
                    } catch {
                        backupError = "Couldn't save the backup: \(error.localizedDescription)"
                    }
                } label: {
                    Label("Back Up Now", systemImage: "externaldrive.badge.checkmark")
                }
                .accessibilityIdentifier("data.backUpNow")
                if let backupError {
                    Text(backupError).foregroundStyle(.red)
                }
            } header: {
                Text("Automatic Backup")
            } footer: {
                Text("A full JSON backup goes to Files › On My iPhone › Liftbook › Backups once a week; the last \(AutoBackup.kept) are kept. "
                     + (lastBackup.map { "Last backup: \($0.formatted(date: .abbreviated, time: .shortened))." } ?? "No backup yet."))
            }

            Section {
                Button {
                    isImporting = true
                } label: {
                    Label("Import Workouts from CSV", systemImage: "square.and.arrow.down")
                }
                .accessibilityIdentifier("data.import")
            } header: {
                Text("Import")
            } footer: {
                Text("Use a CSV in the same format as the export. Workouts already in Liftbook are skipped.")
            }
        }
        .navigationTitle("Export & Import")
        .navigationBarTitleDisplayMode(.inline)
        .task { prepareExports() }
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.commaSeparatedText, .plainText]) { result in
            importFile(result)
        }
        .alert("Import", isPresented: Binding(get: { importMessage != nil }, set: { if !$0 { importMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importMessage ?? "")
        }
    }

    private func prepareExports() {
        do {
            // Today in the user's time zone (plain .iso8601 is UTC: a day off after midnight).
            let day = Date.now.formatted(Date.ISO8601FormatStyle(timeZone: .current).year().month().day())
            let machines = (try? modelContext.fetch(FetchDescriptor<Machine>())) ?? []
            let csv = DataExport.workoutsCSV(sessions, catalog: catalog, machines: machines)
            csvURL = try DataExport.temporaryFile(named: "liftbook-workouts-\(day).csv", data: Data(csv.utf8))
            let backup = try DataExport.backup(from: modelContext)
            jsonURL = try DataExport.temporaryFile(named: "liftbook-backup-\(day).json", data: try DataExport.json(backup))
        } catch {
            exportError = "Couldn't prepare the export: \(error.localizedDescription)"
        }
    }

    private func importFile(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            let text = try String(contentsOf: url, encoding: .utf8)
            let summary = try DataImport.importWorkouts(csv: text, into: modelContext, catalog: catalog)
            importMessage = "Imported \(summary.workouts) workout\(summary.workouts == 1 ? "" : "s") with \(summary.sets) sets."
                + (summary.skippedDuplicates > 0 ? " Skipped \(summary.skippedDuplicates) already in Liftbook." : "")
            prepareExports()
        } catch DataImport.Failure.missingColumns(let columns) {
            importMessage = "This file is missing the columns: \(columns.joined(separator: ", "))."
        } catch {
            importMessage = "Couldn't import this file: \(error.localizedDescription)"
        }
    }
}
