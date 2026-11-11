# Exercise pictures and animations: proposal

Status: proposal, not started. Written 2026-11-11.

Goal: every exercise's photo / animation in **one consistent style**, which
mixing providers can't give.

## Where things stand

- Only 208 of the 2,859 exercises have a picture: 194 RepDB illustrations and
  14 ExerciseDB GIFs. That's already two styles.
- RepDB's license forbids republishing the files, so CI downloads them at build
  time (`scripts/fetch_exercise_art.py`).

## If you look for a provider

From memory, so check current licensing and prices before relying on any of it.

| Option | Style | Coverage | Catch |
|---|---|---|---|
| Gym Visual and similar stock 3D animation libraries | One consistent 3D look | Thousands | Paid license, usually per app |
| ExerciseDB (full, paid) | Consistent 3D GIFs | About 1,300 | Paid API; the free V1 is limited |
| free-exercise-db | Real photos, start and end poses | About 870 | Public domain, but photos vary and only cover a third |
| RepDB free tier | Clean flat illustrations | About 200 | Small, can't be redistributed |

Even a paid library won't match all 2,859 catalog entries by name, so a
fallback is still needed for the rest.

## Recommendation: one character, rendered from pose data in CI

Everything runs on GitHub Actions with free tools, not on the Mac.

1. **One character.** A free (CC0) human model, from MakeHuman/MPFB or
   Quaternius, with one skeleton. Every exercise uses the same body, colours,
   lighting and camera, which is what makes the style uniform.
2. **Simple equipment.** Barbell, dumbbell, bench, cable stack, kettlebell,
   EZ bar, band, pull-up bar and machine seats. Modelled once in Blender, in
   the app's accent colour.
3. **Each exercise as data, not art.** A small file per exercise, for example
   `art/poses/barbell-bench-press.json`, holding:
   - the equipment
   - the camera angle
   - 2–4 key poses (start, bottom, top) as joint angles

   The animation loops between the poses.
4. **Render in CI.** Blender runs headless on GitHub's free Linux runners,
   which are unmetered for public repos. Its fast "Workbench" engine gives a
   flat, clean look on a plain CPU, in seconds per exercise. Output per
   exercise:
   - a start still and a peak still
   - a 2–3 second looping clip (animated WebP or HEVC)
   - a light and a dark variant
5. **Ship like today.** A workflow renders only the exercises whose pose file
   changed and publishes the results as a release asset. The app build
   downloads them the way it fetches ExerciseArt now. Nothing big goes in git,
   and the images are ours, so they can be redistributed.

### Getting the poses right

- **Written by Claude.** Joint angles for simple movements such as curls,
  presses, rows and raises. Squats, cleans and multi-joint lifts take a few
  rounds of render and fix, with the owner reviewing.
- **Filmed by the owner (recommended for complex lifts).** Film one rep on a
  phone and push the video. CI runs Google's free MediaPipe pose tracking on it
  and maps the motion onto the character. Only the anonymous character appears
  in the app. The motion is real and the style stays identical.

## Alternative: draw it in the app

The same pose files could drive a flat 2D figure that the app draws itself
(SwiftUI `Canvas`), with no image files at all:

- a few KB per exercise
- exact app colours, and perfect light and dark mode

It's less realistic, closer to a pictogram than a 3D model.

## Size and scope

- About 2,859 clips at roughly 100 KB each is around 280 MB. That's too much to
  bundle, so the obscure ones would download on demand.
- Start with the 213 hand-written exercises plus the 100 or so most-used from
  the big catalog. That's about 30 MB bundled.
- Everything else shows a similar exercise's picture or the equipment icon
  until it gets a pose file.
- Once the style is approved, adding an exercise is just adding a small file.

## Decisions needed

1. **Look:** 3D flat-shaded character (recommended), or the in-app 2D figure?
2. **Motion source:** written poses, filmed videos for the hard lifts, or both?
3. **Old pictures:** drop RepDB and ExerciseDB once the new art covers the same
   exercises, so the whole app has one style?

## First step once decided

A style test: CI renders five exercises (bench press, squat, curl, row, plank)
in light and dark, for sign-off before scaling up.
