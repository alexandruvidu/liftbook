import Foundation
import SwiftData

enum Persistence {
    /// Every SwiftData model the app stores.
    static let schema = Schema([CustomExercise.self])

    static func makeContainer(inMemory: Bool) -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Could not open the Liftbook data store: \(error)")
        }
    }
}
