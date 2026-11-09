#!/usr/bin/env python3
"""Downloads the exercise pictures bundled into the app.

Two sources, both fetched at build time and never committed:

- Liftbook/Resources/exercise-illustrations.json maps a catalog exercise ID
  to RepDB free-tier illustrations (a start and a peak pose, or one main
  pose). Saved as <catalog ID>-start.webp / -peak.webp / -main.webp.
- Liftbook/Resources/exercise-animations.json maps the exercises RepDB
  doesn't cover to ExerciseDB V1 animations. Saved as <catalog ID>.gif.

Everything goes to Liftbook/Resources/ExerciseArt. Files already there (from
the CI cache) are kept. A missing picture only prints a warning: the app
falls back to an equipment symbol.
"""
import json
import pathlib
import subprocess
import sys
import time

ROOT = pathlib.Path(__file__).resolve().parent.parent
RESOURCES = ROOT / "Liftbook/Resources"
OUT = RESOURCES / "ExerciseArt"
# Pinned so a change upstream can't silently change the app's pictures.
REPDB = "https://raw.githubusercontent.com/RepDB/exercise-dataset/66c4298af8d99b9dc397dad6699e508fb871d249/{}"
EXERCISEDB = "https://static.exercisedb.dev/media/{}.gif"


def looks_valid(data: bytes, extension: str) -> bool:
    if extension == "gif":
        return data[:4] == b"GIF8"
    return data[:4] == b"RIFF" and data[8:12] == b"WEBP"


def fetch(url: str, dest: pathlib.Path) -> bool:
    if dest.exists() and looks_valid(dest.read_bytes()[:12], dest.suffix[1:]):
        return True
    for attempt in range(4):
        result = subprocess.run(["curl", "-sfL", "-m", "30", "-o", str(dest), url])
        if result.returncode == 0 and looks_valid(dest.read_bytes()[:12], dest.suffix[1:]):
            return True
        dest.unlink(missing_ok=True)
        time.sleep(2 * (attempt + 1))
    return False


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    illustrations = json.loads((RESOURCES / "exercise-illustrations.json").read_text())
    animations = json.loads((RESOURCES / "exercise-animations.json").read_text())
    wanted = {}
    for catalog_id, poses in illustrations.items():
        for pose, path in poses.items():
            wanted[f"{catalog_id}-{pose}.webp"] = REPDB.format(path)
    for catalog_id, source_id in animations.items():
        wanted[f"{catalog_id}.gif"] = EXERCISEDB.format(source_id)

    # Drop leftovers from an older mapping so the app never shows a stale picture.
    for stale in OUT.iterdir():
        if stale.name not in wanted:
            stale.unlink()

    missing = [name for name, url in sorted(wanted.items()) if not fetch(url, OUT / name)]
    print(f"{len(wanted) - len(missing)} of {len(wanted)} exercise pictures ready "
          f"({len(illustrations)} illustrated, {len(animations)} animated exercises)")
    if missing:
        print("::warning::Missing exercise pictures: " + ", ".join(missing))
    return 0


if __name__ == "__main__":
    sys.exit(main())
