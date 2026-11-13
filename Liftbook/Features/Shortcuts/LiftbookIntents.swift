import AppIntents
import SwiftData
import SwiftUI

/// What Siri and Shortcuts need from the running app.
@MainActor
@Observable
final class ShortcutRequests {
    static let shared = ShortcutRequests()

    enum Start: Equatable {
        case empty
        case routine(UUID)
    }

    /// The store the intents read and write; set at launch.
    @ObservationIgnored var container: ModelContainer?
    /// A workout Siri or a shortcut asked to start; RootView starts it.
    var start: Start?
}

/// A routine, as Siri and Shortcuts see it.
struct RoutineEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Routine"
    static let defaultQuery = RoutineQuery()

    /// The routine's own UUID, which never changes.
    let id: UUID
    let name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct RoutineQuery: EntityStringQuery {
    @MainActor
    func entities(for identifiers: [UUID]) async throws -> [RoutineEntity] {
        routines().filter { identifiers.contains($0.id) }
    }

    @MainActor
    func entities(matching string: String) async throws -> [RoutineEntity] {
        routines().filter { $0.name.localizedStandardContains(string) }
    }

    @MainActor
    func suggestedEntities() async throws -> [RoutineEntity] {
        routines()
    }

    @MainActor
    private func routines() -> [RoutineEntity] {
        guard let context = ShortcutRequests.shared.container?.mainContext else { return [] }
        let routines = (try? context.fetch(FetchDescriptor<Routine>(sortBy: [SortDescriptor(\.name)]))) ?? []
        return routines.map { RoutineEntity(id: $0.routineID, name: $0.name) }
    }
}

/// Opens Liftbook and starts a routine, or an empty workout.
struct StartWorkoutIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Workout"
    static let description = IntentDescription("Starts a workout, from one of your routines or empty.")
    static let supportedModes: IntentModes = .foreground(.immediate)

    @Parameter(title: "Routine")
    var routine: RoutineEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Start \(\.$routine)")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        ShortcutRequests.shared.start = routine.map { .routine($0.id) } ?? .empty
        return .result()
    }
}

/// Logs today's body weight without opening the app.
struct LogBodyWeightIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Body Weight"
    static let description = IntentDescription("Adds a body weight to Body Measurements.")
    static let supportedModes: IntentModes = .background

    @Parameter(title: "Weight")
    var weight: Measurement<UnitMass>

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$weight) body weight")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let context = ShortcutRequests.shared.container?.mainContext else {
            return .result(dialog: "Liftbook isn't ready yet. Try again in a moment.")
        }
        let kilograms = weight.converted(to: .kilograms).value
        guard BodyMetrics.logBodyWeight(kilograms: kilograms, in: context) else {
            return .result(dialog: "That doesn't look like a body weight, so it wasn't saved.")
        }
        let unit = AppSettings.store.string(forKey: WeightUnit.storageKey).flatMap(WeightUnit.init(rawValue:)) ?? .kilograms
        return .result(dialog: "Logged \(BodyMetricKind.weight.formatted(kilograms, unit: unit)).")
    }
}

/// "2 of 3 workouts this week · 4-week streak".
struct WeeklyProgressIntent: AppIntent {
    static let title: LocalizedStringResource = "Weekly Progress"
    static let description = IntentDescription("Tells you how many workouts you've done this week against your goal.")
    static let supportedModes: IntentModes = .background

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let context = ShortcutRequests.shared.container?.mainContext
        let finished = (try? context?.fetch(FetchDescriptor<WorkoutSession>(predicate: #Predicate { $0.endedAt != nil }))) ?? []
        let goal = AppSettings.store.object(forKey: WeeklyGoal.storageKey) as? Int ?? WeeklyGoal.defaultGoal
        let summary = WeeklyGoal().summary(goal: goal, sessions: finished)
        return .result(value: summary, dialog: "\(summary).")
    }
}

struct LiftbookShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: StartWorkoutIntent(), phrases: [
            "Start a workout in \(.applicationName)",
            "Start \(\.$routine) in \(.applicationName)",
        ], shortTitle: "Start Workout", systemImageName: "play.fill")
        AppShortcut(intent: LogBodyWeightIntent(), phrases: [
            "Log body weight in \(.applicationName)",
        ], shortTitle: "Log Body Weight", systemImageName: "scalemass")
        AppShortcut(intent: WeeklyProgressIntent(), phrases: [
            "How is my week in \(.applicationName)",
            "\(.applicationName) weekly progress",
        ], shortTitle: "Weekly Progress", systemImageName: "chart.bar.fill")
    }
}
