# Run Unit Tests

Run Safa unit tests and return a concise result.

## Arguments

Optional arguments:
- First argument (no flag): test class name, e.g. `/test PrayerViewModelTests`
- `--platform "iOS Simulator,name=iPhone 17 Pro"` (default)
- `--scheme Safa` (default)

Examples: `/test`, `/test PrayerViewModelTests`, `/test --platform "iOS Simulator,name=iPhone Air"`

## Instructions

Parse any arguments. Use defaults for anything not specified.

**All tests (no class specified):**
```
xcodebuild -scheme {SCHEME} -destination 'platform={PLATFORM}' -only-testing:SafaTests test 2>&1 | grep -E "Test case|passed|failed|Executed" | tail -40
```

**Specific test class:**
```
xcodebuild -scheme {SCHEME} -destination 'platform={PLATFORM}' -only-testing:SafaTests/{CLASS} test 2>&1 | grep -E "Test case|passed|failed|Executed" | tail -40
```

- If all pass: "All N tests passed."
- If failures: List each failed test, then "X passed, Y failed."

NEVER output raw xcodebuild logs. NEVER run multiple test commands in parallel.
