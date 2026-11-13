import ActivityKit
import SwiftData
import SwiftUI

/// Starts, updates and ends the workout's Live Activity, and carries out its
/// buttons (`LogNextSetIntent`, `SkipRestIntent`) on the stored workout.
@MainActor
enum WorkoutLiveActivity {
    /// Lets the Live Activity's buttons change workouts in `container`.
    static func registerActions(container: ModelContainer) {
        WorkoutActivityActions.handler = { action in
            handle(action, in: container.mainContext)
        }
    }

    /// Shows `session` as the Live Activity, or ends it when there's no
    /// workout in progress. Skipped in UI tests (except the Live Activity's own),
    /// so other tests aren't affected by it.
    static func sync(_ session: WorkoutSession?, in context: ModelContext) {
        guard !UITestOverrides.isUITesting || UITestOverrides.showsLiveActivity else { return }
        let activities = Activity<WorkoutActivityAttributes>.activities
        guard let session, session.endedAt == nil else {
            end(activities)
            return
        }
        let id = session.sessionID.uuidString
        let content = ActivityContent(state: state(for: session, in: context), staleDate: nil)
        end(activities.filter { $0.attributes.sessionID != id })
        if let activityID = activities.first(where: { $0.attributes.sessionID == id })?.id {
            Task { await update(activityID, with: content) }
        } else if ActivityAuthorizationInfo().areActivitiesEnabled {
            _ = try? Activity.request(attributes: WorkoutActivityAttributes(sessionID: id), content: content)
        }
    }

    private static func end(_ activities: [Activity<WorkoutActivityAttributes>]) {
        for activityID in activities.map(\.id) {
            Task { await end(activityID) }
        }
    }

    // Activities aren't Sendable, so these look them up by ID off the main actor.
    nonisolated private static func update(_ activityID: String,
                                           with content: ActivityContent<WorkoutActivityAttributes.ContentState>) async {
        await Activity<WorkoutActivityAttributes>.activities.first { $0.id == activityID }?.update(content)
    }

    nonisolated private static func end(_ activityID: String) async {
        await Activity<WorkoutActivityAttributes>.activities.first { $0.id == activityID }?
            .end(nil, dismissalPolicy: .immediate)
    }

    private static func handle(_ action: WorkoutActivityActions.Action, in context: ModelContext) {
        var running = FetchDescriptor<WorkoutSession>(predicate: #Predicate { $0.endedAt == nil },
                                                       sortBy: [SortDescriptor(\.startedAt, order: .reverse)])
        running.fetchLimit = 1
        guard let session = try? context.fetch(running).first else {
            sync(nil, in: context)
            return
        }
        switch action {
        case .logNextSet:
            let lookup = Lookup(session: session, context: context)
            if session.logNextSet(type: lookup.type, placeholder: lookup.placeholder, defaultRest: Settings.defaultRest),
               let end = session.restEndsAt {
                // The live workout screen schedules this when it's open; it may not be.
                RestAlerts.schedule(at: end, exerciseName: session.restExerciseID.map(lookup.name) ?? "your workout",
                                    sound: Settings.restSound)
            }
        case .skipRest:
            session.stopRest()
            RestAlerts.cancel()
        }
        try? context.save()
        sync(session, in: context)
    }

    private static func state(for session: WorkoutSession, in context: ModelContext) -> WorkoutActivityAttributes.ContentState {
        let lookup = Lookup(session: session, context: context)
        return .init(session: session, name: lookup.name, type: lookup.type, placeholder: lookup.placeholder,
                     unit: Settings.unit)
    }

    /// Names, types and last time's sets, read as the live workout screen does.
    private struct Lookup {
        let catalog: ExerciseCatalog
        let finished: [WorkoutSession]
        let machines: [Machine]
        let session: WorkoutSession

        init(session: WorkoutSession, context: ModelContext) {
            self.session = session
            let custom = (try? context.fetch(FetchDescriptor<CustomExercise>())) ?? []
            catalog = ExerciseCatalog(custom: custom.map(\.asLibraryExercise))
            finished = (try? context.fetch(FetchDescriptor<WorkoutSession>(predicate: #Predicate { $0.endedAt != nil }))) ?? []
            machines = (try? context.fetch(FetchDescriptor<Machine>())) ?? []
        }

        func name(_ id: String) -> String { catalog.name(for: id) }

        func type(_ id: String) -> ExerciseType { catalog.exercise(id: id)?.type ?? .weightAndReps }

        func placeholder(_ exercise: WorkoutExercise, _ index: Int) -> SetMeasurement? {
            // With machines, last time is that machine's (or no machine's).
            let filter: MachineFilter = machines.of(exercise.exerciseID).isEmpty ? .all : MachineFilter(exercise.machineID)
            let previous = PreviousPerformance.find(exerciseID: exercise.exerciseID, machine: filter,
                                                    in: finished, excluding: session)
            return previous?.set(at: index, kinds: exercise.orderedSets.map(\.kind))
        }
    }

    /// The settings the live workout screen reads with `@AppStorage`.
    private enum Settings {
        static var unit: WeightUnit {
            AppSettings.store.string(forKey: WeightUnit.storageKey).flatMap(WeightUnit.init(rawValue:)) ?? .kilograms
        }

        static var defaultRest: Int {
            AppSettings.store.object(forKey: RestTimer.defaultSecondsKey) as? Int ?? RestTimer.fallbackSeconds
        }

        static var restSound: Bool {
            AppSettings.store.object(forKey: RestTimer.soundKey) as? Bool ?? true
        }
    }
}

/// What the Live Activity shows, so it updates only when that changes.
struct WorkoutActivitySnapshot: Hashable {
    let name: String
    let completed: Int
    let total: Int
    let nextSet: PersistentIdentifier?
    let nextValues: [Double?]
    let restEndsAt: Date?
    let endedAt: Date?

    init(_ session: WorkoutSession) {
        name = session.displayName
        let sets = session.exercises.flatMap(\.sets)
        completed = sets.filter(\.isCompleted).count
        total = sets.count
        let next = session.nextSetToLog?.set
        nextSet = next?.persistentModelID
        nextValues = [next?.weight, next?.reps.map(Double.init), next?.duration, next?.distance]
        restEndsAt = session.restEndsAt
        endedAt = session.endedAt
    }
}
