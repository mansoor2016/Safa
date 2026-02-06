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

The caller will provide one of:
- `build` — Build the project only
- `test` — Run all unit tests
- `test ClassName` — Run a specific test class

If no argument is provided, default to `build`.

## Build Workflow

Run this command:

```bash
xcodebuild -scheme Safa -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | grep -E "error:|warning:|BUILD SUCCEEDED|BUILD FAILED|Undefined symbol|duplicate symbol|linker command failed" | head -30
```

**Report format:**
- If `BUILD SUCCEEDED`: Reply with exactly `Build succeeded.` plus warning count if any.
- If `BUILD FAILED`: List each error, shortened to `FileName.swift:LINE: error message`. Maximum 10 errors.

## Test Workflow

**All tests:**
```bash
xcodebuild -scheme Safa -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SafaTests test 2>&1 | grep -E "Test case|passed|failed|Executed" | tail -40
```

**Specific test class:**
```bash
xcodebuild -scheme Safa -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SafaTests/{ClassName} test 2>&1 | grep -E "Test case|passed|failed|Executed" | tail -40
```

**Report format:**
- If all pass: `All N tests passed.`
- If failures: List each failed test name, then `X passed, Y failed.`

## Rules

1. NEVER output raw xcodebuild logs
2. NEVER run multiple test commands in parallel (simulator resource constraint)
3. Always use `iPhone 17 Pro` as the simulator destination
4. Timeout: 5 minutes for builds, 5 minutes for tests
5. If build/test hangs, report timeout and suggest the caller investigate
