import Foundation
import Testing
@testable import Liftbook

struct ExerciseLibraryTests {
    private let library = ExerciseLibrary.bundled

    private var handWritten: [LibraryExercise] { ExerciseLibrary.handWritten.exercises }

    @Test func bundledLibraryHasThousandsOfExercises() {
        #expect(handWritten.count >= 190)
        #expect(library.exercises.count >= 2500)
    }

    /// Logged workouts point at these IDs, so none may disappear.
    @Test func everyHandWrittenExerciseIsKept() {
        for exercise in handWritten {
            #expect(library.exercise(id: exercise.id) == exercise, "\(exercise.id)")
        }
    }

    @Test func mergedExercisesIncludeCommonMachines() {
        #expect(library.exercise(id: "machine-decline-chest-press")?.equipment == .machine)
    }

    @Test func everyIDIsASlug() {
        for exercise in library.exercises {
            #expect(exercise.id.wholeMatch(of: /[a-z0-9]+(-[a-z0-9]+)*/) != nil, "\(exercise.id)")
        }
    }

    @Test func idsAndNamesAreUnique() {
        let ids = library.exercises.map(\.id)
        let names = library.exercises.map { $0.name.lowercased() }
        #expect(Set(ids).count == ids.count)
        #expect(Set(names).count == names.count)
    }

    @Test func idsAreSlugsOfNames() {
        for exercise in handWritten {
            let expected = exercise.name.lowercased()
                .replacingOccurrences(of: "'", with: "")
                .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
                .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
            #expect(exercise.id == expected, "\(exercise.name)")
        }
    }

    @Test func everyExerciseHasMuscles() {
        for exercise in library.exercises {
            #expect(!exercise.primaryMuscles.isEmpty, "\(exercise.name) has no primary muscle")
            #expect(Set(exercise.primaryMuscles).isDisjoint(with: exercise.secondaryMuscles), "\(exercise.name)")
        }
    }

    @Test func handWrittenExercisesAreFullyDescribed() {
        for exercise in handWritten {
            #expect(exercise.details.count >= 30, "\(exercise.name) description too short")
            #expect(exercise.details.hasSuffix("."), "\(exercise.name) description should end with a period")
        }
    }

    @Test func libraryCoversEveryTypeMuscleAndCoreEquipment() {
        let types = Set(library.exercises.map(\.type))
        #expect(types == Set(ExerciseType.allCases))

        let muscles = Set(library.exercises.flatMap(\.primaryMuscles))
        #expect(muscles == Set(Muscle.allCases))

        let equipment = Set(library.exercises.map(\.equipment))
        for item in [Equipment.none, .barbell, .dumbbell, .kettlebell, .machine, .cable, .band] {
            #expect(equipment.contains(item), "No \(item) exercises")
        }
    }

    @Test func exercisesAreSortedAndSectionedAlphabetically() {
        let names = library.exercises.map(\.name)
        #expect(names == names.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending })

        let sections = library.sections
        #expect(sections.map(\.letter) == sections.map(\.letter).sorted())
        #expect(sections.reduce(0) { $0 + $1.exercises.count } == library.exercises.count)
        for section in sections {
            #expect(section.exercises.allSatisfy { $0.name.uppercased().hasPrefix(section.letter) })
        }
    }

    @Test func lookupByID() {
        #expect(library.exercise(id: "barbell-bench-press")?.name == "Barbell Bench Press")
        #expect(library.exercise(id: "does-not-exist") == nil)
    }

    @Test func decodingRejectsUnknownMuscle() {
        let json = """
        [{"id":"x","name":"X","primaryMuscles":["wings"],"secondaryMuscles":[],
          "equipment":"none","type":"bodyweight","description":"Flap."}]
        """
        #expect(throws: DecodingError.self) {
            _ = try ExerciseLibrary(data: Data(json.utf8))
        }
    }

    @Test func summaryJoinsMusclesAndEquipment() throws {
        let exercise = try #require(library.exercise(id: "barbell-bench-press"))
        #expect(exercise.summary == "Chest · Barbell")
    }

    private func exercise(_ id: String, _ name: String, details: String = "") -> String {
        """
        {"id":"\(id)","name":"\(name)","primaryMuscles":["chest"],"secondaryMuscles":[],
         "equipment":"none","type":"bodyweight","description":"\(details)"}
        """
    }

    @Test func extraDescriptionsFillOnlyEmptyOnes() throws {
        let core = Data("[\(exercise("a", "A", details: "Own text."))]".utf8)
        let more = Data("[\(exercise("b", "B")),\(exercise("c", "C", details: "Source text."))]".utf8)
        let loaded = try ExerciseLibrary.load(core: core, more: more,
                                              descriptions: ["a": "Extra.", "b": "Extra.", "c": "Extra."])
        #expect(loaded.exercises.map(\.details) == ["Own text.", "Extra.", "Source text."])
        #expect(loaded.exercise(id: "b")?.name == "B")
    }

    @Test func catalogMergesCustomExercisesInOrder() throws {
        let base = try ExerciseLibrary.load(core: Data("[\(exercise("a", "Apple")),\(exercise("c", "Cherry"))]".utf8), more: nil)
        let custom = [LibraryExercise(id: "custom-b", name: "banana", primaryMuscles: [.chest], secondaryMuscles: [],
                                      equipment: .none, type: .bodyweight, details: ""),
                      LibraryExercise(id: "custom-d", name: "Date", primaryMuscles: [.chest], secondaryMuscles: [],
                                      equipment: .none, type: .bodyweight, details: "")]
        let catalog = ExerciseCatalog(library: base, custom: custom)
        #expect(catalog.exercises.map(\.name) == ["Apple", "banana", "Cherry", "Date"])
        #expect(catalog.exercise(id: "custom-d")?.name == "Date")
        #expect(catalog.exercise(id: "c")?.name == "Cherry")
        #expect(ExerciseCatalog(library: base, custom: []).exercises.map(\.id) == ["a", "c"])
    }
}
