import Foundation
import Testing
@testable import Liftbook

struct RestActivityStateTests {
    private let now = Date(timeIntervalSince1970: 10_000)

    @Test func noStateWithoutRest() {
        let session = WorkoutSession(name: "W")
        #expect(RestActivityAttributes.ContentState(session: session, exerciseName: "Squat") == nil)
    }

    @Test func stateCoversTheWholeRest() throws {
        let session = WorkoutSession(name: "W")
        session.startRest(seconds: 90, for: "back-squat", at: now)
        let state = try #require(RestActivityAttributes.ContentState(session: session, exerciseName: "Back Squat"))
        #expect(state.startedAt == now)
        #expect(state.endsAt == now.addingTimeInterval(90))
        #expect(state.exerciseName == "Back Squat")
    }

    @Test func addedTimeStretchesTheRest() throws {
        let session = WorkoutSession(name: "W")
        session.startRest(seconds: 60, for: "x", at: now)
        session.adjustRest(by: 15, at: now)
        let state = try #require(RestActivityAttributes.ContentState(session: session, exerciseName: nil))
        #expect(state.endsAt.timeIntervalSince(state.startedAt) == 75)
        #expect(state.exerciseName == "your workout")
    }
}
