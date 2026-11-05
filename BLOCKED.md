# Blocked: "Start an empty workout or start from a routine"

CI failed 3 times in a row on this PLAN.md item, so work stopped per the
stopping rules in CLAUDE.md. The feature code is committed on `main`; the item
is **not** ticked.

## What the item adds (commits 91323d5, 8f1437b, latest)
- `WorkoutSession` / `WorkoutExercise` / `WorkoutSet` SwiftData models and
  `WorkoutStarter` (empty workout named by time of day, or prefilled from a
  routine). Unit tests in `WorkoutStarterTests` **pass**.
- Workout tab: Start Empty Workout, a "Workout in progress" resume banner,
  routine detail with Start Workout, a conflict alert when one is already
  running, and a first live workout screen (Add Exercises, Minimize, Finish,
  Discard).
- UI tests: `StartWorkoutUITests` (empty workout and from-routine flows).

## Attempts
1. **Run 41924443309** – all four `StartWorkoutUITests` failed. Cause: the
   tests looked for a "Not logged" static text, but `LabeledContent` merges
   "Set 1" and its value into one accessibility element.
   Fix: match with `label CONTAINS 'Not logged'`; also added a CI step that
   prints xcresult failure messages (parallel testing hides them).
2. **Run 41928110920** – still failing. The new summary step showed
   "Exercise picker did not open" style failures and plain `XCTAssertTrue failed`.
   Screenshots showed each flow stopped right after an alert or confirmation
   dialog (Resume Current, Discard). Diagnosis: presenting/dismissing the
   full-screen live workout while the alert/dialog is still animating away is
   ignored by UIKit.
   Fix (latest commit): delay those presentations until the transition ends
   (`WorkoutStartController.transitionDelay`), attach the presenting modifier
   to the `NavigationStack`, give every assertion a message, and retry the
   picker tap once.
3. **Run 42006823097 (and one re-run of the same commit)** – the fix was never
   exercised. All unit tests passed, but **no UI test started**:
   ```
   Clone 1 of iPhone 17 ... unable to connect to "com.apple.instruments.deviceservice.lockdown" - timed out after 120 seconds
   Clone 2 of iPhone 17 ... unable to connect to "com.apple.instruments.deviceservice.lockdown" - timed out after 120 seconds
   LiftbookUITests-Runner encountered an error (Early unexpected exit, operation never finished bootstrapping
     ... The test runner crashed while preparing to run tests: LiftbookUITests-Runner at -[XCTWaiter(StallHandling) handleStalledWait:])
   ```
   The re-run (new runner image 20261104.0337, Xcode 27.2, iOS 27.2 simulator)
   failed the same way: "The test runner timed out while preparing to run tests."
   The first try used the same image as earlier green runs (20261026.0314,
   Xcode 27.1), so the image update is not the only factor.

## Likely cause and suggested next step
The common factor in both infrastructure failures is parallel UI testing on
two simulator clones (`-parallel-testing-enabled YES -parallel-testing-worker-count 2`,
added in the cleanup pass d224127). It worked in two earlier runs, so it is
flaky rather than broken.

Suggested: remove the two parallel-testing flags from `.github/workflows/ios.yml`
(back to a single simulator, which was reliable but ~6 minutes slower), push,
and see whether `StartWorkoutUITests` passes with the presentation fix. If it
does, tick the item and delete this file.
