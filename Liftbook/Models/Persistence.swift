import Foundation
import SwiftData
import UIKit

enum Persistence {
    /// Every SwiftData model the app stores.
    static let schema = Schema([
        CustomExercise.self,
        RoutineFolder.self,
        Routine.self,
        RoutineEntry.self,
        WorkoutSession.self,
        WorkoutExercise.self,
        WorkoutSet.self,
        BodyMetric.self,
        BodyMeasurement.self,
        ProgressPhoto.self,
    ])

    static func makeContainer(inMemory: Bool) -> ModelContainer {
        open(ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory))
    }

    /// A store in a specific file; UI tests use this to survive a relaunch.
    static func makeContainer(url: URL) -> ModelContainer {
        open(ModelConfiguration(schema: schema, url: url))
    }

    private static func open(_ configuration: ModelConfiguration) -> ModelContainer {
        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Could not open the Liftbook data store: \(error)")
        }
    }

    /// Adds an "Upper Body" routine. Used by UI tests via `-uiTestSeedSampleData YES`.
    @MainActor
    static func seedSampleData(in context: ModelContext) {
        // A relaunched UI test keeps its store; don't add the routine twice.
        guard ((try? context.fetchCount(FetchDescriptor<Routine>())) ?? 0) == 0 else { return }
        var draft = RoutineDraft()
        draft.name = "Upper Body"
        draft.add(["barbell-bench-press", "bent-over-barbell-row", "overhead-press"])
        draft.entries[2].setCount = 2
        let routine = Routine()
        context.insert(routine)
        routine.apply(draft, folder: nil, in: context)
        try? context.save()
    }

    /// Adds three finished workouts 1, 2 and 9 days ago. Used by UI tests via
    /// `-uiTestSeedHistory YES`.
    @MainActor
    static func seedHistory(in context: ModelContext, now: Date = .now, calendar: Calendar = .current) {
        guard ((try? context.fetchCount(FetchDescriptor<WorkoutSession>())) ?? 0) == 0 else { return }
        let plans: [(daysAgo: Int, name: String, weight: Double)] = [
            (1, "Upper Body", 62.5), (2, "Leg Day", 100), (9, "Upper Body", 60),
        ]
        for plan in plans {
            let day = calendar.date(byAdding: .day, value: -plan.daysAgo, to: calendar.startOfDay(for: now))!
            let start = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: day)!
            let session = WorkoutSession(name: plan.name, startedAt: start)
            context.insert(session)
            let exercises = plan.name == "Leg Day" ? ["back-squat"] : ["barbell-bench-press", "bent-over-barbell-row"]
            session.addExercises(exercises, setCount: 3)
            for exercise in session.exercises {
                for set in exercise.sets {
                    set.measurement = SetMeasurement(weight: plan.weight, reps: 8)
                    set.toggleCompleted(for: .weightAndReps, at: start)
                }
            }
            session.finish(at: start.addingTimeInterval(52 * 60))
        }
        try? context.save()
    }

    /// Adds two drawn progress photos, today and 30 days ago. Used by UI tests
    /// via `-uiTestSeedPhotos YES` (the system photo picker can't be scripted).
    @MainActor
    static func seedPhotos(in context: ModelContext, store: PhotoStore = .standard) {
        guard ((try? context.fetchCount(FetchDescriptor<ProgressPhoto>())) ?? 0) == 0 else { return }
        let colors: [UIColor] = [.systemTeal, .systemIndigo]
        for (index, daysAgo) in [0, 30].enumerated() {
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            let image = UIGraphicsImageRenderer(size: CGSize(width: 600, height: 800), format: format).image { ctx in
                colors[index].setFill()
                ctx.fill(CGRect(x: 0, y: 0, width: 600, height: 800))
                UIColor.white.withAlphaComponent(0.5).setFill()
                ctx.cgContext.fillEllipse(in: CGRect(x: 200, y: 120, width: 200, height: 200))
                ctx.fill(CGRect(x: 170, y: 340, width: 260, height: 380))
            }
            guard let fileName = try? store.save(image) else { continue }
            context.insert(ProgressPhoto(date: .now.addingTimeInterval(TimeInterval(-daysAgo) * 86_400), fileName: fileName))
        }
        try? context.save()
    }
}
