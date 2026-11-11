import Testing
@testable import Liftbook

struct ExerciseFilterTests {
    // The hand-written exercises, so results are exact.
    private let all = ExerciseLibrary.handWritten.exercises

    private func ids(_ filter: ExerciseFilter) -> Set<String> {
        Set(filter.apply(to: all).map(\.id))
    }

    @Test func emptyFilterReturnsEverything() {
        let filter = ExerciseFilter()
        #expect(!filter.hasMenuFilters)
        #expect(filter.apply(to: all).count == all.count)
    }

    @Test func whitespaceOnlyQueryMatchesEverything() {
        #expect(ExerciseFilter(query: "   ").apply(to: all).count == all.count)
    }

    @Test func clearMenuFiltersKeepsQuery() {
        var filter = ExerciseFilter(query: "curl", muscle: .biceps, equipment: .cable)
        #expect(filter.hasMenuFilters)
        filter.clearMenuFilters()
        #expect(!filter.hasMenuFilters)
        #expect(filter.query == "curl")
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
        #expect(filter.hasMenuFilters)
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

    @Test func bestMatchesComeFirst() {
        let names = ["Plank Jack", "Side Plank", "Plank", "Weighted Plank Row"]
        let exercises = names.map { name in
            LibraryExercise(id: name, name: name, primaryMuscles: [.abs], secondaryMuscles: [],
                            equipment: .none, type: .duration, details: "")
        }
        let ranked = ExerciseFilter(query: "plank").apply(to: ExerciseLibrary(exercises: exercises).exercises, featured: [])
        #expect(ranked.map(\.name) == ["Plank", "Plank Jack", "Side Plank", "Weighted Plank Row"])
        let featured = ExerciseFilter(query: "plank").apply(to: ExerciseLibrary(exercises: exercises).exercises,
                                                            featured: ["Weighted Plank Row"])
        #expect(featured.map(\.name) == ["Plank", "Weighted Plank Row", "Plank Jack", "Side Plank"])
    }

    @Test func everydayExercisesLeadSearch() {
        let first = ExerciseFilter(query: "bench press").apply(to: ExerciseLibrary.bundled.exercises).first
        #expect(first?.id == "barbell-bench-press")
    }

    @Test func hyphenatedNamesMatchExactly() {
        let first = ExerciseFilter(query: "pull up").apply(to: ExerciseLibrary.bundled.exercises).first
        #expect(first?.id == "pull-up")
    }

    @Test func emptyQueryKeepsLibraryOrder() {
        #expect(ExerciseFilter(equipment: .machine).apply(to: all).map(\.id)
            == all.filter { $0.equipment == .machine }.map(\.id))
    }

    @Test func typosStillFindTheExercise() {
        let results = ExerciseFilter(query: "bnech pres").apply(to: all)
        #expect(results.first?.id == "barbell-bench-press" || results.contains { $0.id == "barbell-bench-press" })
    }

    @Test func nonsenseStillFindsNothing() {
        #expect(ExerciseFilter(query: "zzzz").apply(to: all).isEmpty)
        #expect(ExerciseFilter(query: "xq").apply(to: all).isEmpty)
    }

    @Test func editDistance() {
        #expect(ExerciseFilter.distance("bnech", "bench") == 1)
        #expect(ExerciseFilter.distance("pres", "press") == 1)
        #expect(ExerciseFilter.distance("curl", "curl") == 0)
    }
}
