#!/usr/bin/env python3
"""Builds Liftbook/Resources/exercises-more.json from four free exercise databases.

The hand-written catalog (exercises.json) stays as it is: its IDs are what
logged workouts point at. This script adds every other exercise it can find,
merging duplicates across sources:

  1. ExerciseDB V1      https://oss.exercisedb.dev          (1,500)
  2. RepDB free tier    github.com/RepDB/exercise-dataset   (701)
  3. free-exercise-db   github.com/yuhonas/free-exercise-db (876, public domain)
  4. wger               https://wger.de                     (966, CC-BY-SA)

Earlier sources win for the name, equipment and muscles; the description comes
from the first source that has one, in the order free-exercise-db, ExerciseDB,
wger, RepDB. RepDB text is not stored here (its license forbids republishing
it): those entries carry a "repdbID", and CI adds the text at build time.

Downloads are cached in .catalog-cache/ (git-ignored); delete it to refetch.
Run: python3 scripts/build_catalog.py
"""
import html
import json
import pathlib
import re
import subprocess
import sys
import time
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parent.parent
CACHE = ROOT / ".catalog-cache"
CORE = ROOT / "Liftbook/Resources/exercises.json"
OUT = ROOT / "Liftbook/Resources/exercises-more.json"
CORE_SOURCES = ROOT / "scripts/catalog/core-sources.json"
ILLUSTRATIONS = ROOT / "Liftbook/Resources/exercise-illustrations.json"

REPDB_URL = "https://raw.githubusercontent.com/RepDB/exercise-dataset/66c4298af8d99b9dc397dad6699e508fb871d249/exercises.json"
FEDB_URL = "https://raw.githubusercontent.com/yuhonas/free-exercise-db/f00c92c7dcf1216a928a52c3706c7ce8e2f71ed5/dist/exercises.json"
EXDB_URL = "https://oss.exercisedb.dev/api/v1/exercises?limit=25"
WGER_URL = "https://wger.de/api/v2/exerciseinfo/?limit=200"


# ---------------------------------------------------------------- downloads

def get_json(url: str):
    for attempt in range(8):
        result = subprocess.run(["curl", "-sfL", "-m", "60", url], capture_output=True)
        if result.returncode == 0:
            return json.loads(result.stdout)
        time.sleep(min(60, 5 * 2 ** attempt))  # ExerciseDB rate-limits; back off politely
    raise RuntimeError(f"could not fetch {url}")


def cached(name: str, fetch):
    path = CACHE / name
    if not path.exists():
        CACHE.mkdir(exist_ok=True)
        path.write_text(json.dumps(fetch()))
    return json.loads(path.read_text())


def fetch_exercisedb():
    items, cursor = [], None
    while True:
        page = get_json(EXDB_URL + (f"&after={cursor}" if cursor else ""))
        items += page["data"]
        cursor = page.get("meta", {}).get("nextCursor")
        if not cursor or not page["data"]:
            return items
        time.sleep(1)


def fetch_wger():
    items, url = [], WGER_URL
    while url:
        page = json.load(urllib.request.urlopen(urllib.request.Request(url, headers={"Accept": "application/json"}), timeout=60))
        items += page["results"]
        url = page["next"]
        time.sleep(0.5)
    return items


# ---------------------------------------------------------------- names

STOP = {"with", "on", "the", "a", "an", "of", "and", "to", "for", "using", "in", "at", "your", "from"}
SYNONYMS = {
    "db": "dumbbell", "kb": "kettlebell", "bb": "barbell", "lever": "machine", "leverage": "machine",
    "flye": "fly", "flie": "fly", "pushup": "push up", "pullup": "pull up", "chinup": "chin up",
    "situp": "sit up", "tricep": "triceps", "bicep": "biceps", "ohp": "overhead press",
    "military": "overhead", "standing": "", "hammerstrength": "machine", "flat": "",
    "ezbar": "ezbar", "lying": "lying",
}
# The equipment word added to a name's key when the name doesn't say it, so
# "Decline Bench Press" (barbell) matches "Decline Barbell Bench Press".
EQUIPMENT_WORD = {"barbell": "barbell", "dumbbell": "dumbbell", "kettlebell": "kettlebell", "cable": "cable",
                  "machine": "machine", "band": "band", "smithMachine": "smith", "ezBar": "ezbar", "trapBar": "trap"}
TAGS = re.compile(r"\((?:male|female|version \d+|v\. ?\d+)\)|\bv\. ?\d+\b", re.I)


def clean_name(name: str) -> str:
    name = TAGS.sub("", name)
    return re.sub(r"\s+", " ", name).strip(" -,")


def key(name: str, equipment: str = "") -> str:
    """Words of a name, normalized and sorted, so word order, plurals and
    filler ("bench" in "decline bench press") don't matter."""
    s = clean_name(name).lower()
    s = re.sub(r"\b(e-?z|sz)[ -]?(curl )?bar(bell)?\b", "ezbar", s)
    s = s.replace("smith machine", "smith").replace("°", "").replace("-", " ").replace("/", " ")
    s = re.sub(r"[^a-z0-9 ]", " ", s)
    words = set()
    for word in s.split():
        word = SYNONYMS.get(word, word)
        for part in word.split():
            if len(part) > 3 and part.endswith("s") and not part.endswith("ss") and part not in ("triceps", "biceps"):
                part = part[:-1]
            if part and part not in STOP:
                words.add(part)
    if "press" in words or "fly" in words:
        words.discard("chest")
    if "press" in words and words & {"incline", "decline"}:
        words.discard("bench")
    if "smith" in words:
        words.discard("machine")
    word = EQUIPMENT_WORD.get(equipment)
    if word and not words & set(EQUIPMENT_WORD.values()):
        words.add(word)
    return " ".join(sorted(words))


SMALL = {"with", "on", "to", "and", "of", "the", "a", "an", "in", "at", "for", "or", "vs"}
UPPER = {"ez": "EZ", "trx": "TRX", "ohp": "OHP", "rdl": "RDL", "db": "DB", "kb": "KB", "v": "V", "t": "T", "y": "Y", "w": "W"}


def title(name: str) -> str:
    def cap(word: str, first: bool) -> str:
        if "-" in word:
            return "-".join(cap(part, first and i == 0) for i, part in enumerate(word.split("-")))
        lower = word.lower()
        if lower in UPPER:
            return UPPER[lower]
        if lower in SMALL and not first:
            return lower
        return word[:1].upper() + word[1:]
    words = clean_name(name).split()
    if name.islower() or name.isupper():
        return " ".join(cap(w.lower(), i == 0) for i, w in enumerate(words))
    return " ".join(cap(w, i == 0) if w.islower() else w for i, w in enumerate(words))


def slug(name: str) -> str:
    s = clean_name(name).lower().replace("°", "").replace("&", "and")
    return re.sub(r"[^a-z0-9]+", "-", s).strip("-")


# ---------------------------------------------------------------- mapping

def muscles(names, table):
    out = []
    for name in names:
        muscle = table.get(name.lower().strip())
        if muscle and muscle not in out:
            out.append(muscle)
    return out


EXDB_MUSCLES = {
    "deltoids": "shoulders", "rear deltoids": "shoulders", "rotator cuff": "shoulders", "triceps": "triceps",
    "biceps": "biceps", "brachialis": "biceps", "hamstrings": "hamstrings", "forearms": "forearms",
    "wrists": "forearms", "wrist flexors": "forearms", "wrist extensors": "forearms", "hands": "forearms",
    "grip muscles": "forearms", "glutes": "glutes", "pectorals": "chest", "serratus anterior": "chest",
    "quadriceps": "quads", "hip flexors": "quads", "calves": "calves", "soleus": "calves",
    "tibialis anterior": "calves", "ankles": "calves", "ankle stabilizers": "calves", "feet": "calves",
    "abdominals": "abs", "core": "abs", "obliques": "obliques", "upper back": "upperBack",
    "rhomboids": "upperBack", "latissimus dorsi": "lats", "back": "lats", "erector spinae": "lowerBack",
    "trapezius": "traps", "levator scapulae": "traps", "sternocleidomastoid": "traps",
    "abductors": "abductors", "adductors": "adductors", "cardiovascular system": "fullBody",
}
FEDB_MUSCLES = {
    "shoulders": "shoulders", "hamstrings": "hamstrings", "glutes": "glutes", "quadriceps": "quads",
    "triceps": "triceps", "calves": "calves", "abdominals": "abs", "chest": "chest", "lower back": "lowerBack",
    "biceps": "biceps", "forearms": "forearms", "middle back": "upperBack", "traps": "traps", "lats": "lats",
    "adductors": "adductors", "abductors": "abductors", "neck": "traps",
}
REPDB_MUSCLES = {
    "gluteus_maximus": "glutes", "gluteus_medius": "glutes", "hamstrings": "hamstrings",
    "anterior_deltoid": "shoulders", "lateral_deltoid": "shoulders", "posterior_deltoid": "shoulders",
    "infraspinatus_teres_minor": "shoulders", "supraspinatus": "shoulders", "quadriceps": "quads",
    "hip_flexors": "quads", "triceps_brachii": "triceps", "erector_spinae": "lowerBack",
    "quadratus_lumborum": "lowerBack", "trapezius": "traps", "rectus_abdominis": "abs",
    "transverse_abdominis": "abs", "obliques": "obliques", "pectoralis_major": "chest",
    "serratus_anterior": "chest", "biceps_brachii": "biceps", "brachialis": "biceps",
    "brachioradialis": "forearms", "forearm_flexors": "forearms", "forearm_extensors": "forearms",
    "forearms": "forearms", "latissimus_dorsi": "lats", "rhomboids": "upperBack",
    "gastrocnemius": "calves", "soleus": "calves", "tibialis_anterior": "calves",
    "adductors": "adductors", "abductors": "abductors",
}
WGER_MUSCLES = {
    "shoulders": "shoulders", "glutes": "glutes", "abs": "abs", "lats": "lats", "quads": "quads",
    "triceps": "triceps", "biceps": "biceps", "chest": "chest", "hamstrings": "hamstrings",
    "trapezius": "traps", "obliquus externus abdominis": "obliques", "calves": "calves",
    "brachialis": "biceps", "serratus anterior": "chest", "soleus": "calves",
}
CATEGORY_MUSCLES = {  # last resort when a source lists no muscles
    "chest": "chest", "back": "lats", "upper arms": "biceps", "arms": "biceps", "lower arms": "forearms",
    "shoulders": "shoulders", "upper legs": "quads", "legs": "quads", "lower legs": "calves",
    "calves": "calves", "waist": "abs", "abs": "abs", "neck": "traps", "cardio": "fullBody",
}

EXDB_EQUIPMENT = {
    "bodyweight": "none", "assisted": "none", "towel": "none", "dumbbell": "dumbbell", "cable": "cable",
    "barbell": "barbell", "olympic barbell": "barbell", "leverage machine": "machine", "sled machine": "machine",
    "resistance band": "band", "band": "band", "smith machine": "smithMachine", "kettlebell": "kettlebell",
    "ez barbell": "ezBar", "ez bar": "ezBar", "medicine ball": "medicineBall", "trap bar": "trapBar",
    "elliptical machine": "cardioMachine", "stationary bike": "cardioMachine", "stepmill machine": "cardioMachine",
    "upper body ergometer": "cardioMachine", "ski ergometer": "cardioMachine",
}
FEDB_EQUIPMENT = {
    "body only": "none", None: "none", "barbell": "barbell", "dumbbell": "dumbbell", "cable": "cable",
    "machine": "machine", "kettlebells": "kettlebell", "bands": "band", "medicine ball": "medicineBall",
    "e-z curl bar": "ezBar",
}
REPDB_EQUIPMENT = {
    None: "none", "pull_up_bar": "none", "dip_station": "none", "flat_bench": "none", "rings": "other",
    "dumbbell": "dumbbell", "barbell": "barbell", "kettlebell": "kettlebell", "cable": "cable",
    "ez_bar": "ezBar", "smith_machine": "smithMachine", "loop_band": "band", "resistance_band": "band",
    "trap_bar": "trapBar", "plates": "plate", "medicine_ball": "medicineBall", "slam_ball": "medicineBall",
    "wall_ball": "medicineBall", "treadmill": "cardioMachine", "air_bike": "cardioMachine",
    "elliptical": "cardioMachine", "rower": "cardioMachine", "ski_erg": "cardioMachine",
    "stair_climber": "cardioMachine", "stationary_bike": "cardioMachine",
}
WGER_EQUIPMENT = {
    "dumbbell": "dumbbell", "cable machine": "cable", "barbell": "barbell", "resistance band": "band",
    "kettlebell": "kettlebell", "sz-bar": "ezBar", "swiss ball": "other",
}


def equipment_from_name(name: str, fallback: str) -> str:
    n = name.lower()
    if "smith" in n:
        return "smithMachine"
    if re.search(r"\b(lever|leverage|machine|sled|pec deck|butterfly machine|leg press|leg curl|leg extension|"
                 r"hack squat|calf press|seated row machine|chest press|shoulder press machine|hip thrust machine|"
                 r"abductor|adductor|hammer ?strength)(?:e?s)?\b", n) \
            and fallback in ("none", "other", "cable") and not re.search(r"\b(band|banded|cable)\b", n):
        return "machine"
    return fallback


def exercise_type(name: str, equipment: str, category: str) -> str:
    n = name.lower()
    if category in ("stretching", "cardio") or equipment == "cardioMachine" \
            or re.search(r"\b(stretch|hold|plank|wall sit|dead hang|isometric|pose|walk|walking|run|running|jog|jogging|sprint|cycling|bike|rowing|elliptical|stair|jump rope|rope jumping|swim)\b", n):
        if not re.search(r"\b(lunge|lunges|farmer|carry|plank (row|jack|up))", n):
            return "duration"
    if "assisted" in n and equipment in ("machine", "band", "none"):
        return "assisted"
    if equipment == "none":
        return "bodyweight"
    return "weightAndReps"


def strip_html(text: str) -> str:
    text = re.sub(r"<(li|p|br)[^>]*>", " ", text or "")
    text = html.unescape(re.sub(r"<[^>]+>", "", text))
    return re.sub(r"\s+", " ", text).strip()


# ---------------------------------------------------------------- sources

def record(source, sid, name, equipment, primary, secondary, category, description, body=None):
    equipment = equipment_from_name(name, equipment or "other")
    if not primary:
        primary = [CATEGORY_MUSCLES[b] for b in (body or []) if b in CATEGORY_MUSCLES][:1] or ["fullBody"]
    secondary = [m for m in secondary if m not in primary]
    return {"source": source, "sid": sid, "name": title(name), "equipment": equipment,
            "primaryMuscles": primary, "secondaryMuscles": secondary,
            "type": exercise_type(name, equipment, category), "description": description.strip()}


def from_exercisedb(items):
    for e in items:
        equipment = next((EXDB_EQUIPMENT[q.lower()] for q in e.get("equipments", []) if q.lower() in EXDB_EQUIPMENT), "other")
        steps = " ".join(re.sub(r"^Step:\s*\d+\s*", "", s) for s in e.get("instructions", []))
        targets = e.get("targetMuscles", [])
        category = "cardio" if "cardiovascular system" in targets else ("stretching" if "stretch" in e["name"].lower() else "")
        yield record("exercisedb", e["exerciseId"], e["name"], equipment, muscles(targets, EXDB_MUSCLES),
                     muscles(e.get("secondaryMuscles", []), EXDB_MUSCLES), category, steps, e.get("bodyParts"))


REPDB_MACHINES = {"leg_press", "leg_curl", "leg_extension", "hack_squat", "pec_deck", "sled", "glute_ham_developer"}


def repdb_equipment(name):
    if name in REPDB_EQUIPMENT:
        return REPDB_EQUIPMENT[name]
    return "machine" if name in REPDB_MACHINES or name.endswith("_machine") else "other"


def from_repdb(items):
    for e in items:
        steps = e.get("instructions_en")
        text = " ".join(steps) if isinstance(steps, list) else (steps or e.get("description_en") or "")
        yield record("repdb", e["id"], e["name_en"], repdb_equipment(e.get("equipment")),
                     muscles(e.get("primary_muscles", []), REPDB_MUSCLES), muscles(e.get("secondary_muscles", []), REPDB_MUSCLES),
                     e.get("category", ""), text, [e.get("body_part", "").replace("_", " ")])


def from_fedb(items):
    for e in items:
        yield record("free-exercise-db", e["id"], e["name"], FEDB_EQUIPMENT.get(e.get("equipment"), "other"),
                     muscles(e["primaryMuscles"], FEDB_MUSCLES), muscles(e["secondaryMuscles"], FEDB_MUSCLES),
                     e.get("category", ""), " ".join(e.get("instructions", [])))


JUNK = re.compile(r"custom|\btest\b|kickboard|integrated conditioning", re.I)
# Some of wger's "English" names are really German or Spanish.
FOREIGN = re.compile(r"[^\x00-\x7f°]|\b(de|con|mit|und|el|la|las|los|der|die|das|beim|auf|zum|zur|sentadilla|übung)\b|"
                     r"(schwimmen|laufen|radfahren|liegestütz|klimmz|kniebeug|bankdr)", re.I)


def from_wger(items):
    for e in items:
        english = next((t for t in e["translations"] if t["language"] == 2), None)
        if not english or len(english["name"].strip()) < 3:
            continue
        description = strip_html(english["description"])
        if JUNK.search(english["name"]) or JUNK.search(description) or FOREIGN.search(english["name"]):
            continue
        names = [q["name"].lower() for q in e["equipment"]]
        equipment = next((WGER_EQUIPMENT[q] for q in names if q in WGER_EQUIPMENT), "none")
        category = e["category"]["name"].lower()
        yield record("wger", e["id"], english["name"], equipment,
                     muscles([m.get("name_en") or m["name"] for m in e["muscles"]], WGER_MUSCLES),
                     muscles([m.get("name_en") or m["name"] for m in e["muscles_secondary"]], WGER_MUSCLES),
                     "cardio" if category == "cardio" else "", description, [category])


# ---------------------------------------------------------------- merge

# Best written first. RepDB comes last because its text can't be committed
# (see below), so it only fills exercises no other source describes.
DESCRIPTION_ORDER = ["free-exercise-db", "exercisedb", "wger", "repdb"]


def main() -> int:
    core = json.loads(CORE.read_text())
    covered = json.loads(CORE_SOURCES.read_text())
    covered["repdb"] = {}
    for catalog_id, poses in json.loads(ILLUSTRATIONS.read_text()).items():
        path = next(iter(poses.values()))
        covered["repdb"][catalog_id] = re.sub(r"-(start|peak|main)\.webp$", "", path.rsplit("/", 1)[1])
    covered_ids = {(source, sid) for source, table in covered.items() for sid in table.values()}

    sources = [
        from_exercisedb(cached("exercisedb.json", fetch_exercisedb)),
        from_repdb(cached("repdb.json", lambda: get_json(REPDB_URL))["exercises"]),
        from_fedb(cached("free-exercise-db.json", lambda: get_json(FEDB_URL))),
        from_wger(cached("wger.json", fetch_wger)),
    ]
    taken_keys = {key(e["name"], e["equipment"]) for e in core}
    taken_names = {e["name"].lower() for e in core}
    taken_ids = {e["id"] for e in core}
    merged: dict[str, dict] = {}
    descriptions: dict[str, dict[str, str]] = {}
    counts = {}
    for records in sources:
        for r in records:
            k = key(r["name"], r["equipment"])
            if (r["source"], r["sid"]) in covered_ids or k in taken_keys or not k:
                continue
            if r["description"]:
                descriptions.setdefault(k, {}).setdefault(r["source"], (r["description"], r["sid"]))
            if k in merged or r["name"].lower() in taken_names:
                continue
            merged[k] = r
            taken_names.add(r["name"].lower())
            counts[r["source"]] = counts.get(r["source"], 0) + 1

    out = []
    for k, r in merged.items():
        texts = descriptions.get(k, {})
        identifier = base = slug(r["name"]) or f"{r['source']}-{r['sid']}"
        if identifier in taken_ids:
            identifier = base = f"{base}-{slug(r['equipment'])}"
        n = 2
        while identifier in taken_ids:
            identifier, n = f"{base}-{n}", n + 1
        taken_ids.add(identifier)
        source = next((s for s in DESCRIPTION_ORDER if s in texts), None)
        entry = {
            "id": identifier, "name": r["name"],
            "primaryMuscles": r["primaryMuscles"], "secondaryMuscles": r["secondaryMuscles"],
            "equipment": r["equipment"], "type": r["type"],
            "description": texts[source][0] if source and source != "repdb" else "",
        }
        if source == "repdb":
            # RepDB's license allows its text in the app but not republished
            # here: CI adds it at build time (scripts/fetch_exercise_art.py).
            entry["repdbID"] = texts[source][1]
        out.append(entry)
    out.sort(key=lambda e: (e["name"].lower(), e["id"]))
    OUT.write_text(json.dumps(out, indent=1, ensure_ascii=False) + "\n")
    print(f"{len(out)} exercises added to the {len(core)} hand-written ones "
          + ", ".join(f"{s}: {c}" for s, c in counts.items()))
    return 0


if __name__ == "__main__":
    sys.exit(main())
