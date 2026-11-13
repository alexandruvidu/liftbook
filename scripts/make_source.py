#!/usr/bin/env python3
"""Writes an AltStore-format source for the latest Liftbook build, for SideStore
(including LiveContainer + SideStore). SideStore verifies the downloaded IPA
against the source: bundle ID, version, build number, size and SHA-256. All of
them are read from the built app so they always match.

The download URL is the build's own file, Liftbook-<build>.ipa, never replaced
once uploaded: a source fetched before or during the next publish still points
at the IPA its SHA-256 describes. (The rolling Liftbook.ipa is replaced on every
build, so a cached source and a newer IPA there wouldn't match.)

No top-level "version": 2 on purpose: SideStore only enforces declared
permissions/entitlements for v2 sources, and an unsigned build has none.

    python3 scripts/make_source.py <Liftbook.app/Info.plist> <Liftbook.ipa> <out.json>
"""
import datetime
import hashlib
import json
import os
import plistlib
import struct
import sys

REPO = os.environ.get("GITHUB_REPOSITORY", "alexandruvidu/liftbook")
RELEASE = f"https://github.com/{REPO}/releases/download/latest-build"
ICON = f"https://raw.githubusercontent.com/{REPO}/main/Liftbook/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"

# Store screenshots, committed by StoreScreenshotsUITests; shown in SideStore.
SCREENSHOTS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "docs", "screenshots", "store")
SCREENSHOTS_URL = f"https://raw.githubusercontent.com/{REPO}/main/docs/screenshots/store"


def screenshots():
    """The store screenshots in name order, with their pixel sizes from the PNG header."""
    if not os.path.isdir(SCREENSHOTS_DIR):
        return []
    shots = []
    for name in sorted(os.listdir(SCREENSHOTS_DIR)):
        if not name.endswith(".png"):
            continue
        with open(os.path.join(SCREENSHOTS_DIR, name), "rb") as f:
            header = f.read(24)
        width, height = struct.unpack(">II", header[16:24])
        shots.append({"imageURL": f"{SCREENSHOTS_URL}/{name}", "width": width, "height": height})
    return shots


DESCRIPTION = (
    "Liftbook is an offline-first workout log. Plan routines, record sets as you "
    "train, and follow your progress over time. Everything stays on your phone."
)


def build_ipa_name(build):
    """The per-build IPA asset the source points at."""
    return f"Liftbook-{build}.ipa"


def main(info_plist, ipa, out):
    with open(info_plist, "rb") as f:
        info = plistlib.load(f)

    bundle_id = info["CFBundleIdentifier"]
    version = info["CFBundleShortVersionString"]
    build = info["CFBundleVersion"]
    min_os = info.get("MinimumOSVersion", "26.0")
    size = os.path.getsize(ipa)
    with open(ipa, "rb") as f:
        sha256 = hashlib.sha256(f.read()).hexdigest()
    # SideStore lists privacy permissions; keep them in sync with Info.plist.
    privacy = {k: v for k, v in info.items() if k.startswith("NS") and k.endswith("UsageDescription")}
    date = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    sha = os.environ.get("GITHUB_SHA", "local")[:7]
    notes = os.environ.get("RELEASE_NOTES", "").strip()
    description = f"{notes}\n\nBuild {build} ({sha}) from main." if notes else f"Build {build} ({sha}) from main."
    download = f"{RELEASE}/{build_ipa_name(build)}"
    shots = screenshots()

    source = {
        "name": "Liftbook",
        "identifier": f"{bundle_id}.source",
        "sourceURL": f"{RELEASE}/source.json",
        "subtitle": "Latest Liftbook builds",
        "iconURL": ICON,
        "tintColor": "0B7A6D",
        "apps": [
            {
                "name": "Liftbook",
                "bundleIdentifier": bundle_id,
                "developerName": REPO.split("/")[0],
                "subtitle": "Offline-first workout log",
                "localizedDescription": DESCRIPTION,
                "iconURL": ICON,
                "tintColor": "0B7A6D",
                "category": "lifestyle",
                "screenshots": shots,
                # Older clients read plain URLs.
                "screenshotURLs": [shot["imageURL"] for shot in shots],
                "versions": [
                    {
                        "version": version,
                        "buildVersion": build,
                        "date": date,
                        "localizedDescription": description,
                        "downloadURL": download,
                        "size": size,
                        "sha256": sha256,
                        "minOSVersion": min_os,
                    }
                ],
                # Legacy fields for older clients.
                "version": version,
                "versionDate": date,
                "versionDescription": description,
                "downloadURL": download,
                "size": size,
                "appPermissions": {"entitlements": [], "privacy": privacy},
            }
        ],
        "news": [],
    }
    with open(out, "w") as f:
        json.dump(source, f, indent=2)
    print(f"{bundle_id} {version} ({build}), {size} bytes -> {out}")


if __name__ == "__main__":
    main(*sys.argv[1:4])
