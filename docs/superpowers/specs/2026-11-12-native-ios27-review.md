# Liftbook — native iOS 27 look review

Date: 2026-11-12
Scope: every screen under `Liftbook/Features/` plus the view-facing logic in `Liftbook/Models/`.
Goal: make the app look and behave like a first-party iOS 27 app.

## Summary

The foundations are already current: the `Tab` API, `tabViewBottomAccessory` for the
running workout, a Liquid Glass start button, drag reordering and swipe actions on
iOS 27, and item-bound confirmation dialogs.

The gap to a native app is that almost every screen is hand-drawn cards inside a
`ScrollView`, with hand-rolled buttons, chips, section titles and footers that
approximate system controls. The fix is mostly *removing* custom UI and letting
`List`, `Form`, `Section`, system button styles and the system toolbar do the work.

Recommended order:

1. Decide the deployment target (iOS 18 vs iOS 26).
2. Move Start into the tab bar bottom accessory.
3. Convert Home and Profile to `List`; they set the tone for the whole app.
4. Swap `PillButtonStyle` for system button styles everywhere.
5. Search, filter chips, toolbars.
6. The smaller polish items and the logic fixes below.

---

## 0. Decide the deployment target first

`project.yml` targets iOS 18, so every iOS 26/27 feature is behind `#available` and
falls back to older styling (`SystemBehaviors.swift`, `StartButton.swift`,
`WorkoutRunningBar.swift`, `ExerciseReordering.swift`, `ActivityHomeView.swift`).

The app is sideloaded to the owner's own iPhone. Raising the target to **iOS 26**
would allow:

- `.glass` / `.glassProminent` button styles without gates
- `ConcentricRectangle` corners
- `navigationSubtitle`, `ToolbarSpacer`, `searchToolbarBehavior`
- deleting every fallback branch and the pre‑26 running-bar inset

If iOS 18 stays, everything below still applies with the existing gating pattern.

---

## 1. Biggest wins

### 1.1 Use `List` + `Section` instead of custom blocks on list-like screens

`Block`, `BlockHeader`, `BlockSection` and `SectionTitle` in
`Features/Shared/Blocks.swift` re‑implement inset grouped sections: 18 pt radius,
14 pt padding, `.title3.bold` headers, `.caption` footers.

The system versions give for free:

- iOS 26 corner radii and insets
- separators, row insets, selection highlight, disclosure chevrons
- section header / footer typography
- swipe actions on *every* OS version (no `swipeActionsContainer` gate)
- scroll edge effects under the glass bars
- correct Dynamic Type layout

Convert:

| Screen | File | Notes |
|---|---|---|
| Home routines | `Workout/WorkoutHomeView.swift` | folders become `Section(isExpanded:)` |
| Activity history | `Activity/ActivityHomeView.swift` | share/delete/repeat become swipe + context menu |
| Profile | `Profile/ProfileHomeView.swift` | tiles become `Label` rows with tinted icons |
| Settings | `Profile/SettingsBlock.swift` | becomes a `Form` section |
| Workout detail | `History/WorkoutDetailView.swift` | one section per exercise |
| Routine detail | `Routines/RoutineDetailView.swift` | |
| Exercise detail info / how‑to / alternatives / machines / set fields | `Exercises/ExerciseDetailView.swift` | keep the media gallery and chart as custom rows |
| Data transfer | `Data/DataTransferView.swift` | `Form` |
| Body measurements | `Body/BodyMeasurementsView.swift` | |
| Quick Start | `Root/QuickStartSheet.swift` | |

Keep custom cards only where content is genuinely rich: the live-workout
`ExerciseBlock`, the exercise photo grid (`ExerciseCard`), machine cards.

### 1.2 If a block stays, give it concentric corners

Fixed radii are scattered: 18 (`Blocks.swift`), 16 (`StatTile.swift`), 14
(`WorkoutStatStrip.swift`, `ActivityHomeView` shortcuts), 12 / 10 / 8 / 7
(`SetRow.swift`, `SetMenus.swift`, `SetValueField.swift`).

On iOS 26+ use `ConcentricRectangle` (or `.rect(corners: .concentric)`) for cards
and `.containerShape(...)` on the screen so nested radii resolve against the
system container, as first-party apps do.

### 1.3 Replace `PillButtonStyle` with system button styles

`PillButtonStyle` (`Blocks.swift:121`) is used for Start, Add Exercises, Repeat
Workout, Save as Routine, export buttons, the machine switcher and the RPE sheet.

- iOS 26+: `.buttonStyle(.glass)` and `.buttonStyle(.glassProminent)`
- earlier: `.bordered` and `.borderedProminent`

Also remove the manual `.foregroundStyle(Color.accentForeground)` on prominent
buttons. The system picks the label colour for a tinted button:

- `LiveWorkout/LiveWorkoutView.swift:138` (Finish)
- `Routines/RoutineEditorView.swift:120` (Save)
- `LiveWorkout/FinishSummaryView.swift:78` (Done)
- `Routines/ExercisePickerView.swift:91` (Add N Exercises)
- `Routines/RoutineRow.swift:43`, `Exercises/ExercisesHomeView.swift:80`

`Color.accentForeground` / the `OnAccent` colour set can then go away, together
with `BrandColors.swift`.

### 1.4 One tinted prominent control per screen

HIG for Liquid Glass: reserve a tinted background for a single primary action.
Home currently has a prominent **Start** on every routine card *plus* the floating
Start button. Make the per-card Start a quiet `.glass` / `.bordered` button, or move
it to a swipe action and context menu, and keep the floating Start as the one
prominent call to action.

### 1.5 Move Start into the tab bar bottom accessory

`Root/RootView.swift:42-51` floats Start over the tab bar with a hand-tuned 66 pt
offset, extra `contentMargins`, and keyboard notifications to hide it. That offset
will not track the iOS 26 floating tab bar when it minimizes on scroll.

`tabViewBottomAccessory` is already used for the running bar
(`Root/WorkoutRunningBar.swift:46`). Show a **"Start Workout"** accessory when
nothing is running and the running bar when something is. That is the Music
mini-player pattern and removes all three hacks (`StartButton`, the bottom
margin, the keyboard observers).

The SDK also exposes `TabRole.prominent`; verify its availability before using
it as an alternative.

### 1.6 Adopt the iOS 26 search behaviours

`Exercises/ExercisesHomeView.swift:45` and `Routines/ExercisePickerView.swift:49`
force `.navigationBarDrawer(displayMode: .always)`, which pins a legacy search
drawer under the title.

- Use the default placement so the field sits in the bottom bar on iOS 26.
- Add `.searchToolbarBehavior(.minimize)` where it should collapse to a button.
- Optionally make Exercises a `Tab(role: .search)` if search living in the tab
  bar's search slot is acceptable.

### 1.7 Filter chips → menus in system styles

`Exercises/ExerciseFilterBar.swift:62` draws its own capsules with a hairline
border. Use the same `Menu` labels with `.buttonStyle(.glass)` (or `.bordered`)
and `.controlSize(.small)`.

- The result count below the chips reads non-native; move it to a section header
  or drop it.
- The chip row uses 20 pt horizontal padding inside a 16 pt padded stack, so chips
  do not line up with the grid.

### 1.8 Tidy the toolbars

- `LiveWorkout/LiveWorkoutView.swift:111` hand-builds title + timer in a principal
  item. On iOS 26 use `navigationTitle` + `navigationSubtitle` (timer-style `Text`
  still works). Let the `.confirmationAction` Finish button receive the system's
  prominent treatment; drop `.borderedProminent`. Separate Note from Finish with
  `ToolbarSpacer(.fixed)`.
- `History/WorkoutDetailView.swift:69` – group Share and Edit in one
  `ToolbarItemGroup`.
- `Exercises/ExerciseDetailView.swift:68` – move the camera and media Edit buttons
  from a pill row above the content into the toolbar.
- `Machines/MachinePickerSheet.swift:46` – principal title + subtitle can become
  `navigationTitle` + `navigationSubtitle`.

---

## 2. Smaller polish

| Where | Today | Native shape |
|---|---|---|
| `Workout/WorkoutHomeView.swift:27` | hand-rotated chevron for folders | `Section(isExpanded:)` in a `List` |
| `Profile/SettingsBlock.swift` | `ViewThatFits` rows + caption notes | `Form` with `Picker`, `Stepper`, `Toggle`, footers |
| `Activity/ActivityHomeView.swift:46`, `Activity/WorkoutCard.swift:24` | share button overlaid on a `NavigationLink`, with a reserved clear frame | share in swipe actions / context menu; detail toolbar already has it |
| `LiveWorkout/RestTimerBar.swift:41` | thick material + stroke + shadow | single `.glassEffect(in: .rect(cornerRadius:))` on iOS 26 |
| `Activity/WeekStrip.swift:22` | rounded rectangles as bars | Swift Charts `BarMark`, consistent with other charts, free accessibility |
| `LiveWorkout/FinishSummaryView.swift:18`, `Exercises/ExerciseCard.swift:80` | fixed point sizes | text styles + `.imageScale(.large)` so they follow Dynamic Type |
| `Exercises/ExerciseDetailView.swift:30` | forced `.large` title on a pushed screen | inherit default; long names wrap badly |
| `Features/Shared/StatTile.swift` | custom tile | fine, but radius should be concentric with its container |
| `Machines/MachineSwitcher.swift` | pills via `PillButtonStyle` | segmented `Picker` if ≤4 options, else `.glass` buttons |
| `Media/MediaGallery.swift` | page-style `TabView` with custom corner clip | fine; align radius with 1.2 |

---

## 3. Logic issues found

1. **Two different name fallbacks when editing a workout.**
   `History/EditWorkoutView.swift:79` saves `"Workout"` when the name is blank on
   Done, while `onDisappear` at line 70 uses `WorkoutStarter.defaultName`. Swiping
   the sheet away vs tapping Done gives different results. Pick one (the
   time-of-day name, which `displayName` already uses).

2. **"Discard and Start New" leaves the old rest notification scheduled.**
   `Workout/WorkoutStarting.swift:115` deletes the active sessions but never calls
   `RestAlerts.cancel()`, unlike the other discard paths.

3. **Per-block navigation destinations in the live workout.**
   `LiveWorkout/ExerciseBlock.swift:58` registers `navigationDestination(isPresented:)`
   inside every block. Use `NavigationLink(value: ExercisePageLink(...))` with one
   `exercisePageDestination()` on the live workout's `NavigationStack`, as the rest
   of the app does.

4. **Periodic timeline on the exercise page.**
   `Media/MediaGallery.swift:41` re-renders every 1.2 s to cycle downloaded photos.
   `CLAUDE.md` warns that periodic `TimelineView`s close menus; the add-media
   `Menu` sits directly below the gallery. Consider a manual page indicator or a
   longer interval that pauses while a menu is open.

5. **Unused parameter.** `WorkoutStatStrip.tile(_:value:id:accent:)` never
   receives `accent: true`.

---

## 4. Suggested implementation plan

Each step is independently shippable and testable with `scripts/test.sh`.

1. **Target + cleanup** – raise deployment target to iOS 26 (if agreed); delete
   fallbacks in `SystemBehaviors.swift`, `StartButton.swift`,
   `WorkoutRunningBar.swift`, `ExerciseReordering.swift`.
2. **Bottom accessory** – replace the floating Start overlay with a
   `tabViewBottomAccessory` that switches between "Start Workout" and the running
   bar. Remove `contentMargins` and keyboard observers in `RootView`.
3. **Home → List** – `Section(isExpanded:)` per folder, routine rows with
   `NavigationLink`, swipe to start / context menu to edit.
4. **Profile → List** – stats header, `Label` rows, settings `Form` section.
5. **Buttons** – introduce `.buttonStyle(.glassProminent)` / `.glass` helpers,
   delete `PillButtonStyle`, `Color.accentForeground`, `BrandColors.swift`.
6. **Search + filters** – default `searchable` placement, `.searchToolbarBehavior`,
   menu chips in system styles.
7. **Toolbars** – `navigationSubtitle`, `ToolbarSpacer`, grouped items.
8. **Remaining screens** – Activity, Workout detail, Routine detail, Exercise
   detail, Data, Body, Quick Start.
9. **Logic fixes** – items in section 3.

Update the UI test identifiers as rows move from custom buttons into `List` rows;
the helpers in `LiftbookUITests/UITestHelpers.swift` (`openMenu`, `scrollTo`)
should keep working.

---

## 5. Outcome (2026-11-12)

Implemented with the deployment target raised to **iOS 26**. Where the
result differs from the plan above:

- **`OnAccent` / `Color.accentForeground` stay.** `.glassProminent` keeps its
  label white, which is unreadable on the dark-mode mint accent (about 1.6:1).
  The main action per screen uses `prominentGlassButton()`
  (`Shared/BrandColors.swift`), which adds the `accentForeground` label. In
  toolbars the color has to be set on the label's `Text`.
- **Toolbar confirmation actions aren't tinted by the system**, so Finish and
  Save use `prominentGlassButton()` explicitly.
- **The live timer uses `ToolbarItem(placement: .subtitle)`**, not
  `navigationSubtitle`: a timer-style `Text` passed to `navigationSubtitle`
  doesn't tick.
- **The Exercises tab keeps `.navigationBarDrawer(displayMode: .always)`.** In a
  tab the default placement hides the field until you pull down (the tab bar
  takes the bottom slot). The exercise picker sheet uses the default placement
  and gets the bottom search bar. Exercises did not become `Tab(role: .search)`.
- **Downloaded exercise photos are separate gallery pages**, swiped by hand,
  instead of cycling on a timer.
- **The routine editor and edit-workout headers stay `Block` cards** with system
  controls: the screens' rich exercise blocks use iOS 27 drag reordering and
  per-set swipe actions that don't fit inside `List` rows.
- **Home uses `.listStyle(.sidebar)`**, the style in which
  `Section(isExpanded:)` draws its own disclosure control.
- **`TabRole.prominent`** wasn't used; the bottom accessory covers Start.
- Concentric corners: cards use `ConcentricRectangle` with their old radius as
  the minimum; `Block` sets a container shape for the controls inside it.
  Screens and sheets keep the system's own container shape.
