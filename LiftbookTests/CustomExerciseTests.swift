import Foundation
import SwiftData
import Testing
@testable import Liftbook

@MainActor
struct CustomExerciseTests {
    private let container: ModelContainer
    private let context: ModelContext

    init() {
        container = Persistence.makeContainer(inMemory: true)
        context = ModelContext(container)
    }

    private func draft(_ name: String) -> ExerciseDraft {
        var draft = ExerciseDraft()
        draft.name = name
        draft.type = .distance
        draft.equipment = .other
        draft.primaryMuscles = [.forearms, .traps]
        draft.secondaryMuscles = [.abs, .traps]
        draft.details = "  Carry it far.  "
        return draft
    }

    private func fetchAll() throws -> [CustomExercise] {
        try context.fetch(FetchDescriptor<CustomExercise>())
    }

    @Test func createStoresTrimmedFieldsWithCustomID() throws {
        context.insert(CustomExercise(draft: draft(" Sandbag Carry ")))
        let saved = try #require(try fetchAll().first)

        #expect(saved.exerciseID.hasPrefix("custom-"))
        #expect(saved.name == "Sandbag Carry")
        #expect(saved.details == "Carry it far.")
        #expect(saved.primaryMuscles == [.traps, .forearms])
        #expect(saved.secondaryMuscles == [.abs])
        #expect(saved.equipment == .other)
        #expect(saved.type == .distance)
    }

    @Test func idsAreUnique() {
        let a = CustomExercise(draft: draft("A"))
        let b = CustomExercise(draft: draft("B"))
        #expect(a.exerciseID != b.exerciseID)
    }

    @Test func convertsToLibraryExercise() {
        let custom = CustomExercise(draft: draft("Sandbag Carry"))
        let exercise = custom.asLibraryExercise
        #expect(exercise.id == custom.exerciseID)
        #expect(exercise.isCustom)
        #expect(exercise.summary == "Traps, Forearms · Other")
        #expect(!ExerciseLibrary.bundled.exercises.contains { $0.isCustom })
    }

    @Test func updateEditsInPlace() throws {
        let custom = CustomExercise(draft: draft("Sandbag Carry"))
        context.insert(custom)
        let id = custom.exerciseID

        var edited = ExerciseDraft(exercise: custom.asLibraryExercise)
        edited.name = "Sandbag Shoulder Carry"
        edited.type = .duration
        custom.update(from: edited)

        let saved = try #require(try fetchAll().first)
        #expect(saved.exerciseID == id)
        #expect(saved.name == "Sandbag Shoulder Carry")
        #expect(saved.type == .duration)
    }

    @Test func deleteRemovesExercise() throws {
        let custom = CustomExercise(draft: draft("Sandbag Carry"))
        context.insert(custom)
        #expect(try fetchAll().count == 1)
        context.delete(custom)
        #expect(try fetchAll().isEmpty)
    }

    @Test func customExercisesAreSearchable() {
        let custom = CustomExercise(draft: draft("Sandbag Carry")).asLibraryExercise
        #expect(ExerciseFilter(query: "sandbag").matches(custom))
        #expect(ExerciseFilter(muscle: .forearms).matches(custom))
        #expect(!ExerciseFilter(equipment: .barbell).matches(custom))
    }
}
