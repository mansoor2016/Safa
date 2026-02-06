# Run Unit Tests

Run Safa unit tests and return a concise result. Filters verbose xcodebuild output to show only test results.

## Arguments

- If an argument is provided, use it as the test class name: `-only-testing:SafaTests/{argument}`
- If no argument is provided, run all unit tests: `-only-testing:SafaTests`

## Instructions

Run the appropriate command:

**All tests (no argument):**
```
xcodebuild -scheme Safa -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SafaTests test 2>&1 | grep -E "Test case|Test Suite|passed|failed|Executed" | tail -40
```

**Specific test class (with argument):**
```
xcodebuild -scheme Safa -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SafaTests/{argument} test 2>&1 | grep -E "Test case|Test Suite|passed|failed|Executed" | tail -40
```

After running tests:

1. If **all tests pass**: Report "All tests passed (X tests)."
2. If **any tests fail**: List each failed test name and a brief reason if available. Then report "X passed, Y failed."
3. Never output the raw xcodebuild log. Always summarize.

**IMPORTANT:** Run tests in SERIES only. Never run multiple test commands in parallel.
