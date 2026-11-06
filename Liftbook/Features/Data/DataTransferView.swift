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

    private var catalog: ExerciseCatalog {
        ExerciseCatalog(custom: customExercises.map(\.asLibraryExercise))
    }

    var body: some View {
        Form {
            Section {
                LabeledContent("Workouts", value: "\(sessions.count)")
                    .accessibilityIdentifier("data.workoutCount")
                LabeledContent("Sets", value: "\(sessions.reduce(0) { $0 + $1.exercises.reduce(0) { $0 + $1.sets.count } })")
            } header: {
                Text("On This iPhone")
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
                Text("CSV has one row per set and opens in any spreadsheet. The JSON backup also includes routines, custom exercises and body measurements. Progress photos aren't included.")
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
            let day = Date.now.formatted(.iso8601.year().month().day())
            let csv = DataExport.workoutsCSV(sessions, catalog: catalog)
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
