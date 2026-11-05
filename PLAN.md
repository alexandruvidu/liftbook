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
- [ ] kg / lb setting

## Phase 2 — History & progress
- [ ] History list and calendar view
- [ ] Workout detail, edit past workouts, repeat a past workout
- [ ] Personal records: heaviest weight, best estimated 1RM, best set volume, most reps
- [ ] Per-exercise charts: estimated 1RM, max weight, volume over time
- [ ] Weekly sets and volume per muscle group chart
- [ ] Workout streaks and weekly goal
- [ ] Body measurements (weight, body fat, custom) with charts
- [ ] Progress photos stored locally

## Phase 3 — Advanced
- [ ] Plate calculator with configurable bar and plates
- [ ] Warm-up set calculator
- [ ] Exercise substitution suggestions by muscle group
- [ ] Progression suggestions (e.g. add weight after hitting the rep target)
- [ ] Export all data to CSV and JSON; import from CSV
- [ ] Dark mode polish, Dynamic Type, VoiceOver labels

## Phase 4 — Optional (may not work when sideloaded through LiveContainer)
- [ ] Apple Health workout export (HealthKit)
- [ ] Live Activity for the rest timer
- [ ] Home screen widget for streak and last workout

Out of scope: social feed, followers, cloud sync, accounts.
