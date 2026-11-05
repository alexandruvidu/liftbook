import Testing
@testable import Liftbook

struct SetKindTests {
    @Test func normalSetsAreNumberedAndOthersTagged() {
        let labels = SetKind.labels(for: [.warmUp, .warmUp, .normal, .normal, .drop, .failure, .normal])
        #expect(labels == ["W", "W", "1", "2", "D", "F", "3"])
    }

    @Test func noSetsMeansNoLabels() {
        #expect(SetKind.labels(for: []).isEmpty)
    }

    @Test func onlyWarmUpsAreExcludedFromWorkingSets() {
        #expect(SetKind.allCases.filter { !$0.isWorkingSet } == [.warmUp])
    }

    @Test func everyKindHasCopy() {
        for kind in SetKind.allCases {
            #expect(!kind.displayName.isEmpty)
            #expect(!kind.explanation.isEmpty)
            #expect((kind.tag == nil) == (kind == .normal))
        }
    }

    @Test func unknownStoredKindFallsBackToNormal() {
        let set = WorkoutSet(position: 0)
        set.kindID = "something-else"
        #expect(set.kind == .normal)
    }
}
