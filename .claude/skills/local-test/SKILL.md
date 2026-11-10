---
name: local-test
description: Use before every commit in the Liftbook repo to build and test on the local Mac and check the changed screens in the simulator, then confirm the CI IPA build after pushing.
---

# Local test loop for Liftbook

All building and testing happens on this Mac. GitHub Actions
(`.github/workflows/ios.yml`) only packages the IPA. Run this loop before
**every** commit; never commit or push code that hasn't passed it.

## 1. Run the tests

```bash
scripts/test.sh                                   # unit tests
scripts/test.sh MachinesUITests LogSetsUITests    # plus these UI test classes
scripts/test.sh all                               # every UI test (about an hour)
```

- Always run the unit tests.
- Add the UI test classes for the current item, plus any existing class whose
  screens the change touches.
- Run `all` at the end of each phase and fix anything it finds.
- The script generates the project with XcodeGen, uses the newest iPhone
  simulator, and prints each failing test with its message. The result bundle
  is `build/TestResults.xcresult`.
- Exercise pictures aren't fetched locally, so screens show the equipment
  symbol instead (as they do in UI tests).

## 2. Check the changed screens in the simulator

Use the `device-interaction` skill to run the app in the simulator, open each
screen you changed, and look at it in **light and dark** mode. Check for:

- clipped or truncated layouts, text cut off by the safe area or tab bar
- unreadable text or low contrast
- overlapping elements
- bad empty states (blank screens, missing guidance, placeholder text)

Fix anything wrong and go back to step 1.

## 3. On failure

- Find the **first real error**: compiler `error:`, linker error, failed
  assertion, or a test failure line. Later errors are often caused by it.
- Fix the root cause and rerun.
- Count consecutive failed attempts for the current PLAN.md item. After the 3rd
  in a row, stop: write what you tried and the error into `BLOCKED.md`,
  commit, push, and end the session.

## 4. After pushing: confirm the IPA build

```bash
SHA=$(git rev-parse HEAD)
gh run list --workflow ios.yml --branch "$(git branch --show-current)" \
  --limit 5 --json databaseId,headSha,status,conclusion
gh run watch <id> --exit-status        # the run whose headSha is $SHA
gh run view <id> --log-failed | tail -n 300   # if it failed
```

The `ipa` artifact holds the unsigned `Liftbook.ipa`. Pushes to `main` also
publish it to the `latest-build` release:
https://github.com/alexandruvidu/liftbook/releases/download/latest-build/Liftbook.ipa
