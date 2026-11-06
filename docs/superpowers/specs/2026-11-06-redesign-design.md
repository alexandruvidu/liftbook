# Liftbook redesign: layout, machines, media, single-workout export

Status: draft for the owner's approval. Mockups: https://claude.ai/artifact/VsEemwdaPvFVJeemyEeYQq
(four phone screens: live workout, machine picker, exercise library, Activity tab).

## Why

The owner uses Liftbook at the gym every session (installed inside
LiveContainer). It works, but almost every screen is an iOS "Settings-style"
grouped list: separate rounded sections with gaps, small gray headers, controls
squeezed into rows. The live workout screen in particular reads as disconnected
sections instead of "here is my workout". The owner wants a screen that works
like a training surface, and wants the same treatment across the app.

Two real needs drive the new features:

- **Machines.** The owner's gym has e.g. three T-bar row machines that load
  differently. Today "last time" and progress mix them together, which makes
  the numbers misleading. Each machine needs its own history.
- **Analysis with AI.** The owner wants to export one workout as CSV and hand it
  to an AI for analysis.

They also want exercise pictures (and their own videos) like other apps have.

## Goals

1. New navigation: Home, Exercises, Activity (History + Progress merged),
   Profile, plus a separate start button; a "workout running" bar to resume.
2. Redesigned live workout screen (as in the mockup).
3. Machines (variations) per exercise, each with a name and a photo, picked
   while logging; "last time", autofill, charts and records follow the machine.
4. Exercise media: downloaded open-dataset photos plus the owner's own photos
   and videos for exercises and machines; library becomes a photo grid.
5. Export a single workout as CSV.
6. Restyle every remaining list-of-sections screen (Profile first among them)
   in the same visual language.

## Non-goals

- No widgets, Live Activities, HealthKit or anything that needs a direct
  install: the app runs only inside LiveContainer.
- No cloud sync, accounts or social features (unchanged, out of scope).
- No bundled third-party exercise media in the repo or IPA.
- No change to how data is stored beyond what machines and media need; no
  data loss for existing workouts.

## Anti-goals (would be a failure even if it "works")

- Copying another app's look, layout, names, copy or media. The reference
  screenshots informed the *structure* (strong exercise header, previous
  column, stat strip); the design is Liftbook's own: its teal/mint accent,
  its own copy, its own components.
- Screens that still feel like grouped Settings lists after the restyle.
- Machines getting in the way of exercises that don't have any: an exercise
  with no machines must behave exactly as today.
- Autofill that silently logs sets the owner didn't do.

## Constraints

- Swift 6, SwiftUI, SwiftData, Swift Charts; iOS 18 deployment target, built
  with the latest Xcode on GitHub Actions; unsigned IPA; public repo; no
  secrets or signing (see CLAUDE.md).
- Must work inside LiveContainer. iOS 26 APIs (Liquid Glass tab bar,
  search-role tab, `tabViewBottomAccessory`) are used behind `#available`
  with an iOS 18 fallback. The owner's phone runs iOS 26.
- Existing SwiftData stores must migrate without losing data (new properties
  get defaults; new models are additive).
- Follow the repo workflow: PLAN.md items, unit tests + UI test with `snap()`
  per item, `ci/ui-tests.txt` selection, full UI run at the phase end.
- Many existing UI tests navigate by tab names ("Workout", "History",
  "Progress") and by current identifiers; they must be updated as screens
  change, not deleted.

## What the owner decided

- **Tab bar:** keep the native Liquid Glass tab bar. Tabs: Home, Exercises,
  Activity, Profile. A **+** start button sits as a separate round glass
  button at the right end of the bar (the iOS 26 search-role slot); a middle
  button is not possible with the native bar.
- **Resume:** while a workout is running, a small glass bar above the tab bar
  (iOS 26 bottom accessory) shows the workout name and elapsed time; tapping it
  opens the workout. Replaces the current resume banner.
- **History + Progress** become one tab, **Activity**, laid out as in the
  mockup: "This week" (goal, streak, per-day bars), shortcuts to exercise
  progress, muscles and records, then the workout history as cards.
- **Live workout** as in the mockup: stat strip (time, volume, sets) on top;
  each exercise one block with photo, accent-colored name, machine chip and
  ⋯ menu; Rest and Note as pills; set grid with a **Last time** column;
  completed rows tinted; next exercises as compact headers; floating rest
  timer.
- **Machines:** per machine, a name and an uploaded photo. Picked from a
  sheet of photo cards showing the last weight × reps and when. "Last time"
  and the pre-filled values come from the last session **on that machine**.
- **Charts and records:** per machine, with a **combined** view option.
- **Exercise media:** the app downloads free-exercise-db's photos onto the
  phone on request (not bundled); the owner can add their own photos and
  videos to any exercise or machine, and theirs take priority.
- **Single-workout export:** CSV, meant for AI analysis.
- **Restyle:** every screen that is a list of different sections, e.g. the
  Profile tab, gets rearranged in the new visual language.
- **A machine belongs to one exercise.** No sharing between exercises.
- **Machines start fresh.** No assigning past workouts to a machine.
- **Exercises in the live workout can be collapsed and expanded** by the
  owner.

## The design

### Visual language (applies everywhere)

- Dark-first, also correct in light mode. Black (or system background)
  ground, one raised surface tone for blocks, a second for inputs/chips.
- Content is grouped into **blocks** with a strong header (image or icon +
  title + optional trailing action), not into inset list sections with small
  gray captions.
- Actions are **pills** (capsule buttons) or full-width buttons; never tiny
  tinted text links in a row.
- Numbers that matter are shown as **stat tiles** (label above, big value).
- Large titles stay; section titles are bold, white, 20 pt, not gray caps.
- Accent: existing teal (light) / mint (dark) asset colors; text on accent
  uses the existing `OnAccent` color. Contrast at least 4.5:1 for text.
- Dynamic Type and VoiceOver keep working as they do now (the accessibility
  UI test stays green).

### Navigation

- `TabView` with four tabs + a search-role "Start" tab on iOS 26. Selecting
  Start does not switch screens: it opens a quick sheet: **Empty workout**
  and the owner's routines (start any with one tap). If a workout is already
  running, it opens that workout instead.
- iOS 18 fallback: Start is a normal fifth tab item with the same behavior.
- Bottom accessory (iOS 26) while a session is in progress: workout name,
  elapsed timer (`Text(date, style: .timer)`), tap to open. iOS 18 fallback:
  the current resume banner.
- **Home** tab (builder's layout, my guess at content): routines as cards with
  a Start pill each, folders as collapsible groups, "This week" summary.
- **Activity** tab replaces History and Progress. The calendar view moves
  behind a calendar button in its navigation bar. Exercise progress, muscle
  volume and records open as pushed screens from the shortcut tiles.

### Live workout

As in the mockup. Specifics:

- Each exercise block can be **collapsed** to its header (photo, name,
  machine, "2 / 3 sets") and **expanded** again by tapping the header or a
  chevron. All start expanded; collapsing is manual only (builder's call:
  nothing collapses on its own). The state lives on the screen, not in data.
- Workout notes move into the ⋯/toolbar (a "Workout note" action) instead of
  a field at the top.
- Exercise note: the Note pill opens an inline text field under the header.
- Set grid columns: Set (kind badge: number or W/D/F), Last time, value
  columns per exercise type, RPE (kept, in the row's menu or a compact
  column — builder's choice as long as it fits at 390 pt), Done.
- **Pre-fill:** empty inputs show the last-time values (same machine) as gray
  placeholder text. Tapping Done on a row whose fields are untouched commits
  the placeholder values. Typing replaces them. Nothing is logged without the
  owner tapping Done.
- Superset grouping, warm-up/plate calculator, swap and remove stay in the
  exercise ⋯ menu.
- Progression suggestion ("Next: 42.5 kg × 8") becomes a one-line hint next
  to the pills; tapping it applies, as today.

### Machines

- New model `Machine`: id (UUID), exerciseID, name, optional location/notes,
  photo file name (optional), createdAt. A machine belongs to exactly one
  exercise (owner's decision).
- `WorkoutExercise` gets `machineID: UUID?` (nil = no specific machine).
  `RoutineExercise` gets the same, so a routine can remember a machine.
- Adding an exercise that has machines asks which one (the picker sheet from
  the mockup), defaulting to the most recently used. The machine chip under
  the exercise name reopens the picker. Exercises without machines skip the
  picker and show no chip; the ⋯ menu offers "Add machine".
- Machines are created from the picker ("Add machine": name + photo) or from
  the exercise page, and can be renamed, re-photographed and deleted. Deleting
  a machine keeps past sets; they show as "No specific machine".
- `PreviousPerformance`, progression suggestions, warm-up defaults, records
  and exercise charts are computed per (exerciseID, machineID). Machines
  start fresh (owner's decision): existing history has no machine and is not
  reassigned. "No specific machine" (nil) uses only sets logged without a
  machine, which includes all history from before machines (builder's call).
- **Records announced** in the finish summary and on Activity cards are per
  machine and labeled with it ("Heaviest on Plate-loaded"); sets without a
  machine count as their own group (builder's call: machines load
  differently, so a cross-machine best means little). The exercise page shows
  per-machine records and an All-machines view.
- **Starting a routine or repeating a workout:** each exercise uses the
  routine's remembered machine, else the most recently used one. Its chip is
  highlighted as "unconfirmed" until tapped or until the first set is checked
  off. No series of pickers at start (builder's call).
- The exercise page shows a machine switcher for charts and records: each
  machine, and **All machines** (combined).
- History rows, workout detail, the finish summary and exports show the
  machine name after the exercise ("T-Bar Row · Plate-loaded").

### Exercise media

- Model `ExerciseMedia`: id, owner (exerciseID or machineID), kind
  (photo/video), file name, position, source (own/downloaded), createdAt.
  Files live in Application Support, like progress photos.
- **Own media:** add photos and videos from the photo library (PhotosPicker,
  images and movies) and, if available inside LiveContainer, from the camera.
  Videos are copied into the app and play muted and looping; tap for sound.
- **Downloaded images:** Profile → "Download exercise images" fetches
  free-exercise-db's exercise list and images from GitHub at runtime, matches
  them to catalog exercises by normalized name (plus a small hand-written alias
  table in code for near-misses), stores them as `source = downloaded`, and
  shows progress and a "Remove downloaded images" option. Nothing from that
  dataset is committed to the repo or bundled in the IPA. Exercises with two
  images alternate between them.
- Display priority: own media → downloaded → equipment icon.
- **Library** becomes a two-column grid of photo cards (name, muscle ·
  equipment, "N machines" badge), with search and muscle/equipment filter
  chips, as in the mockup. The exercise page opens with a swipeable media
  gallery.

### Single-workout export

- Share action on each Activity workout card and in workout detail.
- Produces `Liftbook-<date>-<workout name>.csv` via the share sheet, using the
  same columns as the existing full CSV export plus a `machine` column (also
  added to the full export). One row per set: date, workout, exercise,
  machine, set number, set kind, weight, reps, duration, distance, RPE,
  completed, workout notes, exercise notes. Weight units are named in the
  column header.
- Units (builder's call): weights stay in kilograms (`weight_kg`) in both
  exports so the existing CSV import keeps working.
- CSV import reads the `machine` column, matches a machine by name within the
  exercise or creates it, and groups rows by exercise **and** machine so two
  machines of the same exercise in one workout don't merge (builder's call).
- The JSON backup includes machines and media records (file names, kinds),
  not the media files themselves (builder's call).

### Restyle of the remaining screens

Every screen that is currently a stack of grouped sections is rearranged into
blocks, tiles and pills: Home, Exercise detail, Workout detail and edit,
Finish summary, Profile, Body measurements and metric detail, Progress photos,
Plate and Warm-up calculators, Data (export/import), Routine detail/editor,
Exercise editor. Profile becomes: a header block (this week, total workouts),
then tiles for Body, Photos, Tools, Data, and one compact Settings block
(units, weekly goal, rest timer, sound). Forms that are genuinely forms
(editors) may stay `Form`-based but get the new header and buttons.

## Delivery order (becomes Phase 5 in PLAN.md)

1. Visual building blocks (block, header, pill, stat tile) + new tab layout,
   Start button and quick-start sheet, bottom accessory; Activity tab merge.
2. Live workout redesign (without machines).
3. Machines: model, picker, chip, per-machine previous/pre-fill.
4. Per-machine charts and records with combined view; machine in history.
5. Own photos/videos for exercises and machines; exercise page gallery.
6. Downloaded exercise images; library grid.
7. Single-workout CSV export (+ machine column in full export).
8. Restyle: Home, Profile, exercise detail, workout detail, summary.
9. Restyle: body, photos, tools, data, routines, editors.
10. Cleanup pass; phase-end full UI run.

## Left to the builder

- Exact spacing, corner radii, font sizes, as long as they follow the visual
  language and the mockups.
- Component and file structure; how the iOS 18 fallbacks are implemented.
- The name-matching rules and alias table for downloaded images.
- Video size/length limits and compression.
- How UI tests seed machines and media (new launch flags as needed).

## Risks

- The camera may not be usable inside LiveContainer (privacy strings and
  permissions come from the host app). The photo library picker must always
  work; camera is a bonus.
- The free-exercise-db image URLs or repository could change or disappear;
  the download must fail gracefully and keep whatever was already saved.
- iOS 26-only APIs need clean fallbacks so CI simulators and iOS 18 still
  build and pass.
