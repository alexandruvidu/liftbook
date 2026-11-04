import Testing
@testable import Liftbook

struct ExerciseFilterTests {
    private let all = ExerciseLibrary.bundled.exercises

    private func ids(_ filter: ExerciseFilter) -> Set<String> {
        Set(filter.apply(to: all).map(\.id))
    }

    @Test func emptyFilterReturnsEverything() {
        let filter = ExerciseFilter()
        #expect(!filter.isActive)
        #expect(filter.apply(to: all).count == all.count)
    }

    @Test func whitespaceOnlyQueryIsInactive() {
        #expect(!ExerciseFilter(query: "   ").isActive)
    }

    @Test func searchIsCaseInsensitive() {
        let results = ids(ExerciseFilter(query: "BENCH"))
        #expect(results.contains("barbell-bench-press"))
        #expect(results.contains("dumbbell-bench-press"))
        #expect(!results.contains("back-squat"))
    }

    @Test func hyphensAndSpacesAreInterchangeable() {
        for query in ["pull-up", "pullup", "pull up"] {
            #expect(ids(ExerciseFilter(query: query)).contains("pull-up"), "\(query)")
        }
    }

    @Test func everyWordMustMatch() {
        let results = ids(ExerciseFilter(query: "dumbbell curl"))
        #expect(results.contains("dumbbell-curl"))
        #expect(results.contains("hammer-curl"))  // matches via equipment
        #expect(!results.contains("barbell-curl"))
    }

    @Test func searchCoversMusclesAndEquipment() {
        let results = ids(ExerciseFilter(query: "calves machine"))
        #expect(results.contains("seated-calf-raise"))
        #expect(!results.contains("dumbbell-calf-raise"))
    }

    @Test func apostrophesAreIgnored() {
        #expect(ids(ExerciseFilter(query: "farmers")).contains("farmers-carry"))
    }

    @Test func muscleFilterUsesPrimaryMusclesOnly() {
        let results = ExerciseFilter(muscle: .triceps).apply(to: all)
        #expect(results.allSatisfy { $0.primaryMuscles.contains(.triceps) })
        #expect(!results.contains { $0.id == "barbell-bench-press" })  // triceps only secondary
        #expect(results.contains { $0.id == "rope-pushdown" })
    }

    @Test func equipmentFilter() {
        let results = ExerciseFilter(equipment: .kettlebell).apply(to: all)
        #expect(!results.isEmpty)
        #expect(results.allSatisfy { $0.equipment == .kettlebell })
    }

    @Test func filtersCombine() {
        let filter = ExerciseFilter(query: "raise", muscle: .calves, equipment: .machine)
        #expect(filter.isActive)
        let results = ids(filter)
        #expect(results == ["leg-press-calf-raise", "seated-calf-raise", "standing-calf-raise"])
    }

    @Test func impossibleCombinationIsEmpty() {
        #expect(ExerciseFilter(muscle: .calves, equipment: .kettlebell).apply(to: all).isEmpty)
    }

    @Test func filteredSectionsStayAlphabetical() {
        let results = ExerciseFilter(muscle: .chest).apply(to: all)
        let sections = ExerciseLibrary.sections(for: results)
        #expect(sections.map(\.letter) == sections.map(\.letter).sorted())
        #expect(sections.reduce(0) { $0 + $1.exercises.count } == results.count)
    }
}
