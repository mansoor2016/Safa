# Xcode Build

Build the Safa iOS project and return a concise result.

## Arguments

Optional arguments:
- `--platform "iOS Simulator,name=iPhone 17 Pro"` (default)
- `--scheme Safa` (default)

Examples: `/build`, `/build --platform "iOS Simulator,name=iPad Air 11-inch (M3)"`, `/build --scheme SafaWidgets`

## Instructions

Parse any arguments provided. Use defaults for anything not specified.

Run:

```
xcodebuild -scheme {SCHEME} -destination 'platform={PLATFORM}' build 2>&1 | grep -E "error:|warning:|BUILD SUCCEEDED|BUILD FAILED|Undefined symbol|duplicate symbol|linker command failed" | head -30
```

- If **BUILD SUCCEEDED**: Report "Build succeeded." plus warning count if any.
- If **BUILD FAILED**: List each error as `FileName.swift:LINE: error message`. Max 10 errors.

Do NOT output the raw xcodebuild log.
