---
name: xcode-build
description: "Build and test the Safa iOS project with concise output. Use this skill whenever you need to verify a build or run tests — it filters Xcode's verbose output to avoid filling the context window."
model: haiku
allowed-tools: Bash
user-invocable: false
---

# Xcode Build & Test Skill

This skill handles building and testing the Safa iOS project. It filters xcodebuild's extremely verbose output down to only the essential information.

**IMPORTANT:** Always use this skill instead of running xcodebuild directly. Raw xcodebuild output is thousands of lines and wastes context.

## When to Use

- After writing or modifying any Swift code
- Before committing changes
- When the parent agent asks you to "build", "verify", "compile", or "test"

## Arguments

Arguments are space-separated. Parse them in order:

```
[action] [--platform <platform>] [--scheme <scheme>] [--class <TestClass>]
```

### Action (first argument, required)
- `build` — Build the project only
- `test` — Run all unit tests
- `test --class ClassName` — Run a specific test class

If no action is provided, default to `build`.

### Parameters (optional, with defaults)

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--platform` | `iOS Simulator,name=iPhone 17 Pro` | Target platform/device |
| `--scheme` | `Safa` | Xcode scheme to build |
| `--class` | (none) | Specific test class to run (test action only) |

### Example Arguments

- `build` — Build with defaults
- `test` — Run all tests with defaults
- `test --class PrayerViewModelTests` — Run specific test class
- `build --platform "iOS Simulator,name=iPad Air 11-inch (M3)"` — Build for iPad
- `build --scheme SafaWidgets` — Build widget extension
- `test --platform "iOS Simulator,name=iPhone Air"` — Test on different simulator
- `build --matrix` — Quick matrix: build on 3 configs (iOS 17 SE, iOS 18 Pro Max, iOS 26 Pro)
- `test --matrix` — Quick matrix: test on 3 configs
- `build --matrix-full` — Full matrix: build on 7 configs across all iOS versions and screen sizes
- `test --matrix-full` — Full matrix: test on 7 configs

## Build Workflow

Run commands sequentially:

**Step 1: Run the build and capture exit code**
```bash
xcodebuild -scheme {SCHEME} -destination 'platform={PLATFORM}' build 2>&1 | tail -3
```
The last few lines always contain either `** BUILD SUCCEEDED **` or `** BUILD FAILED **`.

**Step 2: If BUILD FAILED, get the Swift compiler errors**
```bash
xcodebuild -scheme {SCHEME} -destination 'platform={PLATFORM}' build 2>&1 | grep -E "\.swift:[0-9]+:[0-9]+: error:" | head -15
```
This grep pattern matches Swift compiler errors in the format `FileName.swift:LINE:COL: error: message`. It avoids false positives from environment variable dumps and sandbox output.

**Step 3: If Step 2 returned NO results (non-Swift errors like linker, signing, etc.)**
```bash
xcodebuild -scheme {SCHEME} -destination 'platform={PLATFORM}' build 2>&1 | grep -E "^(ld:|Undefined symbols|error:|fatal error|Code Signing Error|clang:)" | head -10
```
This catches linker errors (`ld:`, `Undefined symbols`), code signing errors, and other non-Swift build failures.

**Report format:**
- If `BUILD SUCCEEDED`: Reply with exactly `Build succeeded.` plus warning count if any.
- If `BUILD FAILED`: List each error, shortened to `FileName.swift:LINE: error message`. Maximum 10 errors. If no Swift errors found, report the linker/signing/other errors from Step 3.

**IMPORTANT:** Do NOT use a single grep pipeline for the build. The `error:` string appears in environment variable dumps and sandbox setup lines, producing false matches. Always check the last few lines first for BUILD SUCCEEDED/FAILED, then only grep for errors if the build failed.

## Test Workflow

Run commands sequentially:

**Step 0: Clean up previous result bundle**
```bash
rm -rf /tmp/safa-test.xcresult
```

**Step 1: Run tests with result bundle**
```bash
xcodebuild -scheme {SCHEME} -destination 'platform={PLATFORM}' {ONLY_TESTING} -parallel-testing-enabled NO -resultBundlePath /tmp/safa-test.xcresult test 2>&1 | tail -5
```
Where `{ONLY_TESTING}` is:
- All tests: `-only-testing:SafaTests`
- Specific class: `-only-testing:SafaTests/{CLASS}`

Check the last lines for:
- `** TEST SUCCEEDED **` → tests passed
- `** BUILD FAILED **` or `Testing cancelled because the build failed` → build error, not test failure
- `** TEST FAILED **` → actual test failures

**Step 2a: If BUILD FAILED during test, get Swift compiler errors**
```bash
xcodebuild -scheme {SCHEME} -destination 'platform={PLATFORM}' {ONLY_TESTING} -parallel-testing-enabled NO test 2>&1 | grep -E "\.swift:[0-9]+:[0-9]+: error:" | head -15
```

**Step 2a-fallback: If Step 2a returned NO results (linker/signing/other errors)**
```bash
xcodebuild -scheme {SCHEME} -destination 'platform={PLATFORM}' {ONLY_TESTING} -parallel-testing-enabled NO test 2>&1 | grep -E "^(ld:|Undefined symbols|error:|fatal error|Code Signing Error|clang:)" | head -10
```

**Step 2b: If TEST SUCCEEDED or TEST FAILED, get accurate counts from result bundle**
```bash
xcrun xcresulttool get test-results summary --path /tmp/safa-test.xcresult
```
Parse the JSON output for `passedTests` and `failedTests` fields.

**Step 2c: If TEST FAILED, get the names of failed tests**
```bash
xcrun xcresulttool get test-results tests --path /tmp/safa-test.xcresult | python3 -c "
import sys, json
data = json.load(sys.stdin)
def walk(node):
    if node.get('status') == 'Failed' and 'subtests' not in node:
        print(node.get('name', 'unknown'))
    for sub in node.get('subtests', []):
        walk(sub)
for device in data.get('devices', []):
    for result in device.get('tests', []):
        walk(result)
" 2>/dev/null
```

**Report format:**
- If all pass: `All N tests passed.`
- If build fails: Report as build failure with errors (same format as build workflow). If no Swift errors found, report the linker/signing/other errors from the fallback step.
- If test failures: List each failed test name, then `X passed, Y failed.`

**IMPORTANT:** A test run can fail because the BUILD failed (not because tests failed). Always distinguish between build failures and test failures. If you see "Testing cancelled because the build failed", report it as a build failure and show the compiler errors.
**IMPORTANT:** Never rely on `grep | tail` for test counts — with 2400+ tests the output gets truncated. Always use `xcresulttool` for accurate results.

## Available Simulators

For reference, these simulators are available on this machine:

| iOS | Name | Width | Type |
|-----|------|-------|------|
| 17.5 | iPhone SE (3rd generation) | 375pt | iPhone |
| 17.5 | iPhone 15 | 393pt | iPhone |
| 17.5 | iPhone 15 Plus | 393pt | iPhone |
| 17.5 | iPhone 15 Pro | 393pt | iPhone |
| 17.5 | iPhone 15 Pro Max | 430pt | iPhone |
| 18.6 | iPhone 16e | 375pt | iPhone |
| 18.6 | iPhone 16 | 393pt | iPhone |
| 18.6 | iPhone 16 Plus | 393pt | iPhone |
| 18.6 | iPhone 16 Pro | 402pt | iPhone |
| 18.6 | iPhone 16 Pro Max | 430pt | iPhone |
| 26.2 | iPhone 16e | 375pt | iPhone |
| 26.2 | iPhone 17 | 393pt | iPhone |
| 26.2 | iPhone Air | 393pt | iPhone |
| 26.2 | iPhone 17 Pro (default) | 402pt | iPhone |
| 26.2 | iPhone 17 Pro Max | 430pt | iPhone |
| 26.2 | iPad Air 11-inch (M3) | — | iPad |
| 26.2 | iPad Air 13-inch (M3) | — | iPad |
| 26.2 | iPad Pro 11-inch (M5) | — | iPad |
| 26.2 | iPad Pro 13-inch (M5) | — | iPad |
| 26.2 | iPad mini (A17 Pro) | — | iPad |
| 26.2 | iPad (A16) | — | iPad |

## Matrix Modes

### Quick matrix (`--matrix`)

Covers each iOS version boundary + screen width extremes in 3 runs:
1. `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=17.5` (375pt — oldest OS + smallest)
2. `platform=iOS Simulator,name=iPhone 16 Pro Max,OS=18.6` (430pt — middle OS + largest)
3. `platform=iOS Simulator,name=iPhone 17 Pro` (402pt — latest OS + default)

Use for every layout/UI change. ~1 minute.

### Full matrix (`--matrix-full`)

Covers all iOS versions, popular models (14/15/16/17 generation), and all screen sizes in 7 runs:
1. `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=17.5` (375pt)
2. `platform=iOS Simulator,name=iPhone 15 Pro,OS=17.5` (393pt)
3. `platform=iOS Simulator,name=iPhone 16,OS=18.6` (393pt)
4. `platform=iOS Simulator,name=iPhone 16 Pro Max,OS=18.6` (430pt)
5. `platform=iOS Simulator,name=iPhone 16e` (375pt — iOS 26)
6. `platform=iOS Simulator,name=iPhone 17 Pro` (402pt — iOS 26)
7. `platform=iOS Simulator,name=iPhone 17 Pro Max` (430pt — iOS 26)

Use before releases or after significant changes. ~2 minutes.

### Report format (both modes)

Report a summary table:

```
| iOS | Device | Width | Result |
|-----|--------|-------|--------|
| 17.5 | iPhone SE (3rd gen) | 375pt | Build succeeded / All N tests passed |
| 18.6 | iPhone 16 Pro Max | 430pt | Build succeeded / All N tests passed |
| 26.2 | iPhone 17 Pro | 402pt | Build succeeded / All N tests passed |
```

Stop on the first failure and report errors. If all pass: "Quick/Full matrix passed (N/N)."

## Rules

1. NEVER output raw xcodebuild logs
2. NEVER run multiple test commands in parallel (simulator resource constraint)
3. Timeout: 5 minutes for builds, 5 minutes for tests
4. If build/test hangs, report timeout and suggest the caller investigate
5. Parse arguments flexibly — the caller may use natural language like "build for iPad" which means use an iPad simulator
6. ALWAYS check for BUILD SUCCEEDED/FAILED in the last few lines BEFORE grepping for errors
7. When tests fail due to build failure, report the build errors — not "0 tests passed"
