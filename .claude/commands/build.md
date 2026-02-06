# Xcode Build

Build the Safa iOS project and return a concise result. This command filters out Xcode's verbose output to avoid filling the context window.

## Instructions

Run the following command to build the project:

```
xcodebuild -scheme Safa -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | grep -E "error:|warning:|BUILD SUCCEEDED|BUILD FAILED|build failed|Undefined symbol|duplicate symbol|linker command failed" | head -30
```

After running the build:

1. If **BUILD SUCCEEDED**: Report "Build succeeded." with no other details.
2. If **BUILD FAILED**: Report each error on its own line, stripping file paths to just the filename. For example, instead of `/Users/mansoor.aman/src/Safa/Safa/Features/Prayer/PrayerView.swift:45:13: error: cannot find 'Foo'`, report `PrayerView.swift:45: cannot find 'Foo'`.
3. If there are warnings but the build succeeded, mention the count of warnings but don't list them unless there are 3 or fewer.

Do NOT output the raw xcodebuild log. Always summarize concisely.
