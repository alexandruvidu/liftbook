import SwiftData
import SwiftUI

/// What the user asked to start.
enum WorkoutStartRequest {
    case empty
    case routine(Routine)
    case repeating(WorkoutSession)
}

/// Shared state for starting, resuming and presenting the live workout.
@MainActor
@Observable
final class WorkoutStartController {
    var presented: WorkoutSession?
    var conflicting: WorkoutStartRequest?
    fileprivate var pending: WorkoutStartRequest?
    /// Deleted once the live workout screen has finished dismissing.
    fileprivate var discardAfterDismiss: WorkoutSession?

    /// UIKit ignores a present/dismiss that starts while an alert or dialog is
    /// still animating away, so changes made from one wait for it to finish.
    static let transitionDelay: Duration = .milliseconds(450)

    /// Called from the discard confirmation dialog.
    func discard(_ session: WorkoutSession) {
        discardAfterDismiss = session
        afterTransition { self.presented = nil }
    }

    /// Presents a session from an alert button.
    func presentAfterAlert(_ session: WorkoutSession?) {
        afterTransition { self.presented = session }
    }

    private func afterTransition(_ change: @escaping @MainActor () -> Void) {
        Task { @MainActor in
            try? await Task.sleep(for: Self.transitionDelay)
            change()
        }
    }

    func start(_ request: WorkoutStartRequest) {
        pending = request
    }

    /// Starts once a sheet that asked for it has finished closing.
    func startAfterDismiss(_ request: WorkoutStartRequest) {
        afterTransition { self.pending = request }
    }

    func resume(_ session: WorkoutSession) {
        presented = session
    }
}

private struct PresentedWorkout: Identifiable {
    let session: WorkoutSession
    var id: UUID { session.sessionID }
}

private struct WorkoutStartingModifier: ViewModifier {
    @Bindable var starter: WorkoutStartController
    /// Only one place (the root view) should offer to resume at launch.
    let offersLeftover: Bool
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<WorkoutSession> { $0.endedAt == nil }, sort: \WorkoutSession.startedAt)
    private var active: [WorkoutSession]
    @Query(filter: #Predicate<WorkoutSession> { $0.endedAt != nil }) private var finished: [WorkoutSession]
    @Query private var machines: [Machine]
    /// Whether this launch already offered to resume a leftover workout.
    @State private var checkedForLeftover = false
    @State private var leftover: WorkoutSession?

    private var hasLeftover: Binding<Bool> {
        Binding(get: { leftover != nil }, set: { if !$0 { leftover = nil } })
    }

    private var hasConflict: Binding<Bool> {
        Binding(get: { starter.conflicting != nil }, set: { if !$0 { starter.conflicting = nil } })
    }

    func body(content: Content) -> some View {
        content
            .onChange(of: starter.pending != nil) {
                guard let request = starter.pending else { return }
                starter.pending = nil
                if active.isEmpty {
                    begin(request)
                } else {
                    starter.conflicting = request
                }
            }
            // A workout still in progress at launch was left when the app quit.
            .task {
                guard offersLeftover, !checkedForLeftover else { return }
                checkedForLeftover = true
                if starter.presented == nil { leftover = active.last }
            }
            .alert(ResumePrompt.title, isPresented: hasLeftover, presenting: leftover) { session in
                Button("Resume") { starter.presentAfterAlert(session) }
                    .accessibilityIdentifier("leftover.resume")
                Button("Discard Workout", role: .destructive) {
                    RestAlerts.cancel()
                    modelContext.delete(session)
                    try? modelContext.save()
                }
                .accessibilityIdentifier("leftover.discard")
                Button("Not Now", role: .cancel) {}
            } message: { session in
                Text(ResumePrompt.message(for: session))
            }
            .alert("A workout is already in progress", isPresented: hasConflict) {
                Button("Resume Current") { starter.presentAfterAlert(active.last) }
                Button("Discard and Start New", role: .destructive) {
                    let request = starter.conflicting
                    for session in active {
                        modelContext.delete(session)
                    }
                    if let request { begin(request, fromAlert: true) }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Finish or discard it before starting another one.")
            }
            .fullScreenCover(item: presentedItem, onDismiss: deleteDiscarded) { item in
                LiveWorkoutView(session: item.session) { starter.discard(item.session) }
            }
    }

    /// Keyed by the session's own UUID: the SwiftData identifier changes from
    /// temporary to permanent on the first save, which would re-present the cover.
    private var presentedItem: Binding<PresentedWorkout?> {
        Binding(get: { starter.presented.map(PresentedWorkout.init) },
                set: { starter.presented = $0?.session })
    }

    private func deleteDiscarded() {
        if let session = starter.discardAfterDismiss {
            modelContext.delete(session)
            starter.discardAfterDismiss = nil
        }
    }

    private func begin(_ request: WorkoutStartRequest, fromAlert: Bool = false) {
        let session = switch request {
        case .empty: WorkoutStarter.emptyWorkout()
        case .routine(let routine): WorkoutStarter.workout(from: routine, machines: machines, history: finished)
        case .repeating(let past): WorkoutStarter.repeating(past)
        }
        modelContext.insert(session)
        // Save now so the new models get permanent identifiers before any view
        // uses them; an autosave later would change them mid-workout.
        try? modelContext.save()
        if fromAlert {
            starter.presentAfterAlert(session)
        } else {
            starter.presented = session
        }
    }
}

extension View {
    /// - Parameter offersLeftover: ask at launch to resume a workout left in progress.
    func workoutStarting(_ starter: WorkoutStartController, offersLeftover: Bool = false) -> some View {
        modifier(WorkoutStartingModifier(starter: starter, offersLeftover: offersLeftover))
    }
}
