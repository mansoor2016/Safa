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

## Build Workflow

Construct and run:

```bash
xcodebuild -scheme {SCHEME} -destination 'platform={PLATFORM}' build 2>&1 | grep -E "error:|warning:|BUILD SUCCEEDED|BUILD FAILED|Undefined symbol|duplicate symbol|linker command failed" | head -30
```

**Report format:**
- If `BUILD SUCCEEDED`: Reply with exactly `Build succeeded.` plus warning count if any.
- If `BUILD FAILED`: List each error, shortened to `FileName.swift:LINE: error message`. Maximum 10 errors.

## Test Workflow

Construct and run:

**All tests:**
```bash
xcodebuild -scheme {SCHEME} -destination 'platform={PLATFORM}' -only-testing:SafaTests test 2>&1 | grep -E "Test case|passed|failed|Executed" | tail -40
```

**Specific test class:**
```bash
xcodebuild -scheme {SCHEME} -destination 'platform={PLATFORM}' -only-testing:SafaTests/{CLASS} test 2>&1 | grep -E "Test case|passed|failed|Executed" | tail -40
```

**Report format:**
- If all pass: `All N tests passed.`
- If failures: List each failed test name, then `X passed, Y failed.`

## Available Simulators

For reference, these simulators are available on this machine:

| Name | Type |
|------|------|
| iPhone 17 Pro (default) | iPhone |
| iPhone 17 | iPhone |
| iPhone 17 Pro Max | iPhone |
| iPhone Air | iPhone |
| iPhone 16e | iPhone |
| iPad Air 11-inch (M3) | iPad |
| iPad Air 13-inch (M3) | iPad |
| iPad Pro 11-inch (M5) | iPad |
| iPad Pro 13-inch (M5) | iPad |
| iPad mini (A17 Pro) | iPad |
| iPad (A16) | iPad |

## Rules

1. NEVER output raw xcodebuild logs
2. NEVER run multiple test commands in parallel (simulator resource constraint)
3. Timeout: 5 minutes for builds, 5 minutes for tests
4. If build/test hangs, report timeout and suggest the caller investigate
5. Parse arguments flexibly — the caller may use natural language like "build for iPad" which means use an iPad simulator
