#!/usr/bin/env python3
"""Downloads the exercise animations bundled into the app.

Reads Liftbook/Resources/exercise-animations.json (catalog exercise ID ->
ExerciseDB V1 exercise ID) and saves each animation as
Liftbook/Resources/ExerciseGIFs/<catalog ID>.gif. Files already there (from
the CI cache) are kept. A missing animation only prints a warning: the app
shows an equipment symbol instead.
"""
import json
import pathlib
import subprocess
import sys
import time

ROOT = pathlib.Path(__file__).resolve().parent.parent
MAPPING = ROOT / "Liftbook/Resources/exercise-animations.json"
OUT = ROOT / "Liftbook/Resources/ExerciseGIFs"
URL = "https://static.exercisedb.dev/media/{}.gif"


def fetch(url: str, dest: pathlib.Path) -> bool:
    for attempt in range(4):
        result = subprocess.run(["curl", "-sfL", "-m", "30", "-o", str(dest), url])
        if result.returncode == 0 and dest.read_bytes()[:4] == b"GIF8":
            return True
        dest.unlink(missing_ok=True)
        time.sleep(2 * (attempt + 1))
    return False


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    mapping = json.loads(MAPPING.read_text())
    missing = []
    for catalog_id, source_id in sorted(mapping.items()):
        dest = OUT / f"{catalog_id}.gif"
        if dest.exists() and dest.stat().st_size > 0:
            continue
        if not fetch(URL.format(source_id), dest):
            missing.append(catalog_id)
        time.sleep(0.2)
    have = len(list(OUT.glob("*.gif")))
    print(f"{have} of {len(mapping)} exercise animations ready")
    if missing:
        print("::warning::Missing exercise animations: " + ", ".join(missing))
    return 0


if __name__ == "__main__":
    sys.exit(main())
