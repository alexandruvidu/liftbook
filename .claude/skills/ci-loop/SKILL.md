---
name: ci-loop
description: Use after every git push in the Liftbook repo to wait for the iOS GitHub Actions run, fix failures, and review the screenshots it produces. Builds and tests only happen on CI (no local Mac).
---

# CI loop for Liftbook

There is no local Mac. GitHub Actions (`.github/workflows/ios.yml`) is the only
place the app is built and tested. Run this loop after **every** push.

## 1. Find the run for the commit you just pushed

```bash
SHA=$(git rev-parse HEAD)
gh run list --workflow ios.yml --branch "$(git branch --show-current)" \
  --limit 5 --json databaseId,headSha,status,conclusion
```

Take the `databaseId` whose `headSha` equals `$SHA`. If it isn't listed yet,
wait a few seconds and list again.

## 2. Wait for it

```bash
gh run watch <id> --exit-status
```

Run this in the background, or use a Monitor, so it doesn't hit a timeout.
A typical run takes 10–20 minutes.

## 3a. On failure

```bash
gh run view <id> --log-failed | tail -n 300
```

- Look at the **Summarize test failures** step first: it prints each failing
  test with its failure text.
- Find the **first real error**: compiler `error:`, linker error, failed
  assertion, or a test failure line. Later errors are often caused by it.
- If the log doesn't explain a test failure, download the result bundle:
  `gh run download <id> -n xcresult -D ci-xcresult/`.
- Fix the root cause in a small, focused commit, push, and go back to step 1.
- Count consecutive CI failures for the current PLAN.md item. After the 3rd
  failure in a row, stop: write what you tried and the error into `BLOCKED.md`,
  commit, push, and end the session.

## 3b. On success: review screenshots

```bash
rm -rf ci-screenshots && gh run download <id> -n screenshots -D ci-screenshots/
ls ci-screenshots
```

Open each new or changed PNG with the Read tool and check for:

- clipped or truncated layouts, text cut off by the safe area or tab bar
- unreadable text or low contrast in **light and dark** mode
- overlapping elements
- bad empty states (blank screens, missing guidance, placeholder text)

If something looks wrong, fix it, push, and repeat the loop. An item is done
only when CI is green **and** its screenshot looks right.

The `ipa` artifact holds the unsigned `Liftbook.ipa`. Pushes to `main` also
publish it to the `latest-build` release:
https://github.com/alexandruvidu/liftbook/releases/download/latest-build/Liftbook.ipa
