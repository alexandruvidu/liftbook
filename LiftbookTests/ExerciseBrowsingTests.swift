import Foundation
import SwiftData
import Testing
@testable import Liftbook

@MainActor
struct ExerciseBrowsingTests {
    private let container = Persistence.makeContainer(inMemory: true)

    private func exercise(_ id: String, _ name: String) -> LibraryExercise {
        LibraryExercise(id: id, name: name, primaryMuscles: [.chest], secondaryMuscles: [],
                        equipment: .none, type: .bodyweight, details: "")
    }

    /// A session on `day` doing `ids` in that order.
    private func session(day: Double, _ ids: [String]) -> WorkoutSession {
        let session = WorkoutSession(name: "W", startedAt: Date(timeIntervalSince1970: day * 86_400))
        container.mainContext.insert(session)
        for (position, id) in ids.enumerated() {
            session.exercises.append(WorkoutExercise(exerciseID: id, position: position))
        }
        return session
    }

    @Test func everydayAndCustomExercisesComeFirstKeepingOrder() {
        let all = [exercise("1-leg", "1 Leg Box Squat"), exercise("bench", "Bench Press"),
                   exercise("\(CustomExercise.idPrefix)x", "My Press"), exercise("odd", "Odd Lift"),
                   exercise("squat", "Squat")]
        let ordered = ExerciseBrowsing.featuredFirst(all, featured: ["bench", "squat"])
        #expect(ordered.map(\.id) == ["bench", "\(CustomExercise.idPrefix)x", "squat", "1-leg", "odd"])
    }

    @Test func recentIDsAreNewestFirstWithoutRepeats() {
        let sessions = [session(day: 1, ["bench", "row"]),
                        session(day: 3, ["squat", "bench"]),
                        session(day: 2, ["curl"])]
        #expect(ExerciseBrowsing.recentIDs(in: sessions) == ["squat", "bench", "curl", "row"])
        #expect(ExerciseBrowsing.recentIDs(in: sessions, limit: 2) == ["squat", "bench"])
        #expect(ExerciseBrowsing.recentIDs(in: []).isEmpty)
    }
}
