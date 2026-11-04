#!/usr/bin/env python3
"""Writes an AltStore-format source (used by SideStore / LiveContainer) for the
latest Liftbook build. Bundle ID and versions are read from the built app's
Info.plist so they always match the IPA.

    python3 scripts/make_source.py <Liftbook.app/Info.plist> <Liftbook.ipa> <out.json>
"""
import datetime
import json
import os
import plistlib
import sys

REPO = os.environ.get("GITHUB_REPOSITORY", "alexandruvidu/liftbook")
RELEASE = f"https://github.com/{REPO}/releases/download/latest-build"
ICON = f"https://raw.githubusercontent.com/{REPO}/main/Liftbook/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"

DESCRIPTION = (
    "Liftbook is an offline-first workout log. Plan routines, record sets as you "
    "train, and follow your progress over time. Everything stays on your phone."
)


def main(info_plist, ipa, out):
    with open(info_plist, "rb") as f:
        info = plistlib.load(f)

    bundle_id = info["CFBundleIdentifier"]
    version = info["CFBundleShortVersionString"]
    build = info["CFBundleVersion"]
    min_os = info.get("MinimumOSVersion", "18.0")
    size = os.path.getsize(ipa)
    date = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    sha = os.environ.get("GITHUB_SHA", "local")[:7]
    download = f"{RELEASE}/Liftbook.ipa"

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
                "versions": [
                    {
                        "version": version,
                        "buildVersion": build,
                        "date": date,
                        "localizedDescription": f"Build {build} ({sha}) from main.",
                        "downloadURL": download,
                        "size": size,
                        "minOSVersion": min_os,
                    }
                ],
                # Legacy fields for older clients.
                "version": version,
                "versionDate": date,
                "versionDescription": f"Build {build} ({sha}) from main.",
                "downloadURL": download,
                "size": size,
                "appPermissions": {"entitlements": [], "privacy": {}},
            }
        ],
        "news": [],
    }
    with open(out, "w") as f:
        json.dump(source, f, indent=2)
    print(f"{bundle_id} {version} ({build}), {size} bytes -> {out}")


if __name__ == "__main__":
    main(*sys.argv[1:4])
