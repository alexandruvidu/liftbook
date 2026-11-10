#!/bin/bash
# Builds and tests Liftbook on a local iOS simulator.
#
#   scripts/test.sh                       unit tests only
#   scripts/test.sh MachinesUITests ...   unit tests plus these UI test classes
#   scripts/test.sh all                   unit tests plus every UI test
set -euo pipefail
cd "$(dirname "$0")/.."

# Exercise pictures are fetched by CI; an empty folder is enough to build.
mkdir -p Liftbook/Resources/ExerciseArt
xcodegen generate --quiet

# Newest iOS runtime, preferring a standard "iPhone NN" model.
UDID=$(xcrun simctl list devices available -j | python3 -c '
import json, re, sys
devices = json.load(sys.stdin)["devices"]
runtimes = sorted((r for r in devices if ".iOS-" in r), reverse=True)
phones = [(r, d) for r in runtimes for d in devices[r] if d["name"].startswith("iPhone")]
standard = [(r, d) for r, d in phones if re.fullmatch(r"iPhone \d+", d["name"])]
for r, d in standard + phones:
    print(d["udid"]); sys.stderr.write(d["name"] + " / " + r + "\n"); sys.exit(0)
sys.exit("No available iPhone simulator")
')

SELECT=()
if [ "${1:-}" != "all" ]; then
    SELECT+=("-only-testing:LiftbookTests")
    for name in "$@"; do SELECT+=("-only-testing:LiftbookUITests/$name"); done
fi

RESULT=build/TestResults.xcresult
rm -rf "$RESULT"
set +e
xcodebuild test ${SELECT[@]+"${SELECT[@]}"} \
    -project Liftbook.xcodeproj \
    -scheme Liftbook \
    -destination "id=$UDID" \
    -derivedDataPath build/DerivedData \
    -resultBundlePath "$RESULT" \
    -parallel-testing-enabled NO \
    CODE_SIGNING_ALLOWED=NO \
    | grep --line-buffered -E "error:|✘|Test run with|Test Case.*(passed|failed)|Executed|\*\* TEST"
STATUS=${PIPESTATUS[0]}
set -e

if [ "$STATUS" -ne 0 ]; then
    xcrun xcresulttool get test-results summary --path "$RESULT" --compact \
        | python3 -c 'import json,sys; [print(f["testIdentifierString"] + ": " + f["failureText"]) for f in json.load(sys.stdin).get("testFailures", [])]' \
        || true
fi
exit "$STATUS"
