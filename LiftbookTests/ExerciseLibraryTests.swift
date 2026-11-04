import Foundation
import Testing
@testable import Liftbook

struct ExerciseLibraryTests {
    private let library = ExerciseLibrary.bundled

    @Test func bundledLibraryHasAboutTwoHundredExercises() {
        #expect(library.exercises.count >= 190)
    }

    @Test func idsAndNamesAreUnique() {
        let ids = library.exercises.map(\.id)
        let names = library.exercises.map { $0.name.lowercased() }
        #expect(Set(ids).count == ids.count)
        #expect(Set(names).count == names.count)
    }

    @Test func idsAreSlugsOfNames() {
        for exercise in library.exercises {
            let expected = exercise.name.lowercased()
                .replacingOccurrences(of: "'", with: "")
                .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
                .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
            #expect(exercise.id == expected, "\(exercise.name)")
        }
    }

    @Test func everyExerciseIsFullyDescribed() {
        for exercise in library.exercises {
            #expect(!exercise.primaryMuscles.isEmpty, "\(exercise.name) has no primary muscle")
            #expect(Set(exercise.primaryMuscles).isDisjoint(with: exercise.secondaryMuscles), "\(exercise.name)")
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
}
