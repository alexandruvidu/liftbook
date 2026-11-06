# Liftbook plan

Work top to bottom. An item is done only when CI builds, all tests pass, and its
screenshot looks correct.

## Phase 0 — Scaffold
- [x] Empty app builds and tests pass on CI
- [x] Tab bar: Workout, History, Exercises, Progress, Profile
- [x] Original app icon and accent color
- [x] Screenshot harness working

## Phase 1 — Core logging
- [x] Bundled exercise library (~200 exercises in JSON: name, primary/secondary muscles, equipment, type), descriptions written from scratch
- [x] Search and filter exercises by muscle and equipment
- [x] Create, edit, delete custom exercises
- [x] Exercise types: weight & reps, bodyweight, assisted, duration, distance
- [x] Routines: create, edit, reorder exercises, organize in folders
- [x] Start an empty workout or start from a routine
- [x] Live workout screen: add sets with reps, weight, RPE; check off sets
- [x] Set types: warm-up, normal, drop set, failure
- [x] Show previous performance next to each set
- [x] Rest timer per exercise with adjustable default, sound, and local notification
- [x] Supersets
- [x] Notes per workout and per exercise
- [x] Finish workout summary (duration, volume, sets, new PRs) and save to history
- [x] Resume an in-progress workout after the app is relaunched; discard option
- [x] kg / lb setting

## Phase 2 — History & progress
- [x] History list and calendar view
- [x] Workout detail, edit past workouts, repeat a past workout
- [x] Personal records: heaviest weight, best estimated 1RM, best set volume, most reps
- [x] Per-exercise charts: estimated 1RM, max weight, volume over time
- [x] Weekly sets and volume per muscle group chart
- [x] Workout streaks and weekly goal
- [x] Body measurements (weight, body fat, custom) with charts
- [x] Progress photos stored locally

## Phase 3 — Advanced
- [x] Plate calculator with configurable bar and plates
- [x] Warm-up set calculator
- [x] Exercise substitution suggestions by muscle group
- [x] Progression suggestions (e.g. add weight after hitting the rep target)
- [x] Export all data to CSV and JSON; import from CSV
- [x] Dark mode polish, Dynamic Type, VoiceOver labels

## Phase 4 — Optional (skipped: widgets, Live Activities and HealthKit don't work inside LiveContainer)
- [ ] Apple Health workout export (HealthKit)
- [ ] Live Activity for the rest timer
- [ ] Home screen widget for streak and last workout

## Phase 5 — Redesign (spec: docs/superpowers/specs/2026-11-06-redesign-design.md, plan: docs/superpowers/plans/2026-11-06-redesign.md)
- [x] New tab bar with start button and workout-running bar; Activity tab (History + Progress)
- [x] Live workout screen redesign (blocks, stat strip, last-time column, pre-fill, collapse)
- [x] Machines per exercise: picker with photos, per-machine last time and pre-fill
- [x] Per-machine charts and records with combined view; machine in history and summary
- [x] Own exercise photos and videos; exercise page gallery
- [x] Download exercise images; library as a photo grid
- [x] Export a single workout as CSV
- [ ] Restyle Home, Profile, exercise and workout screens
- [ ] Restyle body tracking, tools, data and editors
- [ ] Phase 5 cleanup and full UI run

Out of scope: social feed, followers, cloud sync, accounts.
