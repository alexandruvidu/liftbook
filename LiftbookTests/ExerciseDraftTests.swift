import Testing
@testable import Liftbook

struct ExerciseDraftTests {
    private func validDraft() -> ExerciseDraft {
        var draft = ExerciseDraft()
        draft.name = "  Sandbag Carry  "
        draft.primaryMuscles = [.forearms]
        return draft
    }

    @Test func emptyDraftNeedsNameAndPrimaryMuscle() {
        #expect(ExerciseDraft().problems(existingNames: []) == [.missingName, .missingPrimaryMuscle])
    }

    @Test func whitespaceNameCountsAsMissing() {
        var draft = validDraft()
        draft.name = "   "
        #expect(draft.problems(existingNames: []) == [.missingName])
    }

    @Test func validDraftHasNoProblems() {
        #expect(validDraft().problems(existingNames: ["Back Squat"]).isEmpty)
        #expect(validDraft().trimmedName == "Sandbag Carry")
    }

    @Test func duplicateNamesAreRejectedIgnoringCase() {
        #expect(validDraft().problems(existingNames: ["sandbag carry"]) == [.duplicateName])
    }

    @Test func secondaryNeverRepeatsPrimary() {
        var draft = validDraft()
        draft.primaryMuscles = [.quads, .glutes]
        draft.secondaryMuscles = [.glutes, .hamstrings, .chest]
        #expect(draft.orderedPrimaryMuscles == [.glutes, .quads])
        #expect(draft.orderedSecondaryMuscles == [.chest, .hamstrings])
    }

    @Test func initFromExerciseCopiesFields() throws {
        let bench = try #require(ExerciseLibrary.bundled.exercise(id: "barbell-bench-press"))
        let draft = ExerciseDraft(exercise: bench)
        #expect(draft.name == bench.name)
        #expect(draft.orderedPrimaryMuscles == bench.primaryMuscles)
        #expect(draft.equipment == .barbell)
        #expect(draft.type == .weightAndReps)
    }

    @Test func problemsHaveMessages() {
        for problem in [ExerciseDraft.Problem.missingName, .duplicateName, .missingPrimaryMuscle] {
            #expect(!problem.message.isEmpty)
        }
    }
}
