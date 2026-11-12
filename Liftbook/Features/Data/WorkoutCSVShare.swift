import CoreTransferable
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// One workout as a CSV file, written only when it's actually shared.
struct WorkoutCSVFile: Transferable {
    let fileName: String
    let csv: String

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .commaSeparatedText) { file in
            SentTransferredFile(try DataExport.temporaryFile(named: file.fileName, data: Data(file.csv.utf8)))
        }
    }
}

/// A share button that exports one workout as CSV, e.g. to hand to an AI
/// for analysis.
struct ShareWorkoutButton: View {
    let session: WorkoutSession
    let catalog: ExerciseCatalog
    @Query private var machines: [Machine]

    var body: some View {
        let file = WorkoutCSVFile(fileName: DataExport.fileName(for: session),
                                  csv: DataExport.workoutCSV(session, catalog: catalog, machines: machines))
        ShareLink(item: file, preview: SharePreview(file.fileName, image: Image(systemName: "tablecells"))) {
            Label("Export CSV", systemImage: "square.and.arrow.up")
        }
        .accessibilityLabel("Export \(session.displayName) as CSV")
    }
}
