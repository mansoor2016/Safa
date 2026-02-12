# Run Unit Tests

Run Safa unit tests and return a concise result.

## Arguments

Optional arguments:
- First argument (no flag): test class name, e.g. `/test PrayerViewModelTests`
- `--platform "iOS Simulator,name=iPhone 17 Pro"` (default)
- `--scheme Safa` (default)
- `--matrix` — quick matrix: test on 3 configs (iOS 17 SE, iOS 18 Pro Max, iOS 26 Pro)
- `--matrix-full` — full matrix: test on 7 configs across all iOS versions and screen sizes

Examples: `/test`, `/test PrayerViewModelTests`, `/test --platform "iOS Simulator,name=iPhone Air"`, `/test --matrix`, `/test --matrix-full`

## Instructions

Parse any arguments. Use defaults for anything not specified.

### Standard test (no --matrix):

**All tests (no class specified):**
```
xcodebuild -scheme {SCHEME} -destination 'platform={PLATFORM}' -only-testing:SafaTests -parallel-testing-enabled NO test 2>&1 | grep -E "Test case|passed|failed|Executed" | tail -40
```

**Specific test class:**
```
xcodebuild -scheme {SCHEME} -destination 'platform={PLATFORM}' -only-testing:SafaTests/{CLASS} -parallel-testing-enabled NO test 2>&1 | grep -E "Test case|passed|failed|Executed" | tail -40
```

- If all pass: "All N tests passed."
- If failures: List each failed test, then "X passed, Y failed."

### Quick matrix (--matrix flag):

Run the full test suite sequentially on 3 configs covering each iOS version boundary + screen extremes:
1. `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=17.5` (375pt — oldest OS + smallest)
2. `platform=iOS Simulator,name=iPhone 16 Pro Max,OS=18.6` (430pt — middle OS + largest)
3. `platform=iOS Simulator,name=iPhone 17 Pro` (402pt — latest OS + default)

Run each one at a time (NEVER in parallel). Report a summary table:

```
| iOS | Device | Width | Result |
|-----|--------|-------|--------|
| 17.5 | iPhone SE (3rd gen) | 375pt | All N tests passed |
| 18.6 | iPhone 16 Pro Max | 430pt | All N tests passed |
| 26.2 | iPhone 17 Pro | 402pt | All N tests passed |
```

Stop on the first failure. If all pass, report "Quick matrix tests passed (3/3, N tests each)."

### Full matrix (--matrix-full flag):

Run the full test suite sequentially on 7 configs covering all iOS versions, popular models, and screen sizes:
1. `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=17.5` (375pt)
2. `platform=iOS Simulator,name=iPhone 15 Pro,OS=17.5` (393pt)
3. `platform=iOS Simulator,name=iPhone 16,OS=18.6` (393pt)
4. `platform=iOS Simulator,name=iPhone 16 Pro Max,OS=18.6` (430pt)
5. `platform=iOS Simulator,name=iPhone 16e` (375pt — iOS 26)
6. `platform=iOS Simulator,name=iPhone 17 Pro` (402pt — iOS 26)
7. `platform=iOS Simulator,name=iPhone 17 Pro Max` (430pt — iOS 26)

Run each one at a time (NEVER in parallel). Report a summary table with iOS version, device, width, and result. Stop on first failure. If all pass, report "Full matrix tests passed (7/7, N tests each)."

NEVER output raw xcodebuild logs. NEVER run multiple test commands in parallel.
