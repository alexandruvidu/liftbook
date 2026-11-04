import SwiftData
import SwiftUI

/// What the user asked to start.
enum WorkoutStartRequest {
    case empty
    case routine(Routine)
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

    func discard(_ session: WorkoutSession) {
        discardAfterDismiss = session
        presented = nil
    }

    func start(_ request: WorkoutStartRequest) {
        pending = request
    }

    func resume(_ session: WorkoutSession) {
        presented = session
    }
}

/// "Start Empty Workout" or, while a workout is running, a resume banner.
struct StartWorkoutSection: View {
    let starter: WorkoutStartController
    @Query(filter: #Predicate<WorkoutSession> { $0.endedAt == nil }, sort: \WorkoutSession.startedAt)
    private var active: [WorkoutSession]

    var body: some View {
        Section {
            if let session = active.last {
                Button {
                    starter.resume(session)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Workout in progress")
                                .font(.headline)
                            Text(session.name)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("Resume")
                            .font(.headline)
                            .foregroundStyle(.tint)
                    }
                }
                .foregroundStyle(.primary)
                .accessibilityIdentifier("workout.resume")
            } else {
                Button {
                    starter.start(.empty)
                } label: {
                    Label("Start Empty Workout", systemImage: "play.fill")
                        .font(.headline)
                        .foregroundStyle(Color.accentForeground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .accessibilityIdentifier("workout.startEmpty")
            }
        }
    }
}

private struct WorkoutStartingModifier: ViewModifier {
    @Bindable var starter: WorkoutStartController
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<WorkoutSession> { $0.endedAt == nil })
    private var active: [WorkoutSession]

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
            .alert("A workout is already in progress", isPresented: hasConflict) {
                Button("Resume Current") { starter.presented = active.last }
                Button("Discard and Start New", role: .destructive) {
                    let request = starter.conflicting
                    for session in active {
                        modelContext.delete(session)
                    }
                    if let request { begin(request) }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Finish or discard it before starting another one.")
            }
            .fullScreenCover(item: $starter.presented, onDismiss: deleteDiscarded) { session in
                LiveWorkoutView(session: session) { starter.discard(session) }
            }
    }

    private func deleteDiscarded() {
        if let session = starter.discardAfterDismiss {
            modelContext.delete(session)
            starter.discardAfterDismiss = nil
        }
    }

    private func begin(_ request: WorkoutStartRequest) {
        let session = switch request {
        case .empty: WorkoutStarter.emptyWorkout()
        case .routine(let routine): WorkoutStarter.workout(from: routine)
        }
        modelContext.insert(session)
        starter.presented = session
    }
}

extension View {
    func workoutStarting(_ starter: WorkoutStartController) -> some View {
        modifier(WorkoutStartingModifier(starter: starter))
    }
}
