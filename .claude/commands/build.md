# Xcode Build

Build the Safa iOS project and return a concise result.

## Arguments

Optional arguments:
- `--platform "iOS Simulator,name=iPhone 17 Pro"` (default)
- `--scheme Safa` (default)
- `--matrix` — quick matrix: build on 3 configs (iOS 17 SE, iOS 18 Pro Max, iOS 26 Pro)
- `--matrix-full` — full matrix: build on 7 configs across all iOS versions and screen sizes

Examples: `/build`, `/build --platform "iOS Simulator,name=iPad Air 11-inch (M3)"`, `/build --scheme SafaWidgets`, `/build --matrix`, `/build --matrix-full`

## Instructions

Parse any arguments provided. Use defaults for anything not specified.

### Standard build (no --matrix):

Run:

```
xcodebuild -scheme {SCHEME} -destination 'platform={PLATFORM}' build 2>&1 | grep -E "error:|warning:|BUILD SUCCEEDED|BUILD FAILED|Undefined symbol|duplicate symbol|linker command failed" | head -30
```

- If **BUILD SUCCEEDED**: Report "Build succeeded." plus warning count if any.
- If **BUILD FAILED**: List each error as `FileName.swift:LINE: error message`. Max 10 errors.

### Quick matrix (--matrix flag):

Build sequentially on 3 configs covering each iOS version boundary + screen extremes:
1. `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=17.5` (375pt — oldest OS + smallest)
2. `platform=iOS Simulator,name=iPhone 16 Pro Max,OS=18.6` (430pt — middle OS + largest)
3. `platform=iOS Simulator,name=iPhone 17 Pro` (402pt — latest OS + default)

Run each build one at a time. Report a summary table:

```
| iOS | Device | Width | Result |
|-----|--------|-------|--------|
| 17.5 | iPhone SE (3rd gen) | 375pt | Build succeeded |
| 18.6 | iPhone 16 Pro Max | 430pt | Build succeeded |
| 26.2 | iPhone 17 Pro | 402pt | Build succeeded |
```

Stop on the first failure and report errors. If all pass, report "Quick matrix build passed (3/3)."

### Full matrix (--matrix-full flag):

Build sequentially on 7 configs covering all iOS versions, popular models, and screen sizes:
1. `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=17.5` (375pt)
2. `platform=iOS Simulator,name=iPhone 15 Pro,OS=17.5` (393pt)
3. `platform=iOS Simulator,name=iPhone 16,OS=18.6` (393pt)
4. `platform=iOS Simulator,name=iPhone 16 Pro Max,OS=18.6` (430pt)
5. `platform=iOS Simulator,name=iPhone 16e` (375pt — iOS 26)
6. `platform=iOS Simulator,name=iPhone 17 Pro` (402pt — iOS 26)
7. `platform=iOS Simulator,name=iPhone 17 Pro Max` (430pt — iOS 26)

Report a summary table with iOS version, device, width, and result. Stop on first failure. If all pass, report "Full matrix build passed (7/7)."

Do NOT output the raw xcodebuild log.
