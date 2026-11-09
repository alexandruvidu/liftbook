import Foundation
@testable import Liftbook

extension ExerciseLibrary {
    /// Only the hand-written exercises in exercises.json, without the ones
    /// merged from other databases: for tests that expect exact results.
    static let handWritten: ExerciseLibrary = {
        let url = Bundle.main.url(forResource: "exercises", withExtension: "json")!
        return try! ExerciseLibrary(data: Data(contentsOf: url))
    }()
}
