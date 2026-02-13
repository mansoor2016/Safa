# Safa - Agent Development Guide

## Project Overview

Safa is an iOS Islamic companion app built with Swift and SwiftUI. This document provides all the context an AI coding agent needs to contribute effectively.

**Your Role:** You are a senior iOS developer working on this codebase. Follow the established patterns exactly - consistency is critical for maintainability.

**Reference Documents:**
- `.docs/DESIGN.md` - Product requirements (features, UX)
- `.docs/TECHNICAL.md` - Technical specifications (architecture, patterns)
- `.docs/TASKS.md` - Current progress and next tasks

**Tech Stack:**
- Swift 5.9+
- SwiftUI (iOS 17+, deployment target 17.0)
- Core Data + CloudKit
- Core ML (on-device LLM)
- WidgetKit, ActivityKit

---

## Quick Reference

### Project Structure

```
Safa/
├── App/                    # App entry, router, dependencies
├── Core/                   # Extensions, utilities, constants
├── Domain/                 # Entities, protocols, state, use cases
├── Data/                   # Repositories, Core Data, network, ML
├── Features/               # Feature modules (Prayer, Quran, etc.)
├── Shared/                 # Reusable UI components, styles
├── SafaWidgets/            # Widget extension
├── SafaIntents/            # Siri intents extension
└── Resources/              # Assets, fonts, bundled data
```

### Key Files

| File | Purpose |
|------|---------|
| `App/SafaApp.swift` | App entry point |
| `App/AppRouter.swift` | Navigation coordinator |
| `App/Dependencies.swift` | Dependency injection container |
| `Domain/State/UserStateManager.swift` | Global gamification state |
| `Data/Local/CoreData/CoreDataStack.swift` | Core Data configuration |
| `Core/Constants/AppDefaults.swift` | Single source of truth for app defaults |
| `Core/Services/LocationInferenceService.swift` | Location-based settings inference |

---

## Coding Conventions

### File Naming

```
Views:        {Name}View.swift           → PrayerTimesView.swift
ViewModels:   {Name}ViewModel.swift      → PrayerTimesViewModel.swift
Repositories: {Name}Repository.swift     → PrayerRepository.swift
Protocols:    {Name}Protocol.swift       → PrayerRepositoryProtocol.swift
Extensions:   {Type}+{Feature}.swift     → Date+Hijri.swift
Components:   {Name}.swift               → PrayerTimeRow.swift
Tests:        {Name}Tests.swift          → PrayerViewModelTests.swift
```

### Type Naming

```
Views:        {Name}View                 → PrayerTimesView
ViewModels:   {Name}ViewModel            → PrayerTimesViewModel
Protocols:    {Name}Protocol             → PrayerRepositoryProtocol
Entities:     {Name}                     → Prayer, Surah, Ayah
Managed Obj:  {Name}MO                   → PrayerLogMO
```

---

## Code Patterns

### ViewModel Template

Every ViewModel should follow this exact structure:

```swift
// MARK: - {Feature}ViewModel.swift
// PURPOSE: {Brief description}
// DEPENDENCIES: {List repository/service dependencies}

import SwiftUI

@Observable
final class {Feature}ViewModel {
    // MARK: - Published State
    private(set) var items: [Item] = []
    private(set) var isLoading = false
    private(set) var error: Error?

    // MARK: - Dependencies
    private let repository: {Feature}RepositoryProtocol

    // MARK: - Init
    init(repository: {Feature}RepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Public Methods

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            items = try await repository.getItems()
        } catch {
            self.error = error
        }
    }

    func refresh() async {
        await load()
    }

    // MARK: - Private Methods

    private func handleError(_ error: Error) {
        self.error = error
    }
}
```

### View Template

Every View should follow this exact structure:

```swift
// MARK: - {Feature}View.swift
// PURPOSE: {Brief description}
// DEPENDENCIES: {ViewModel}, {Components used}
// NAVIGATION: {Where it's accessed from, where it navigates to}

import SwiftUI

struct {Feature}View: View {
    // MARK: - Environment
    @Environment(Dependencies.self) private var dependencies
    @Environment(AppRouter.self) private var router

    // MARK: - State
    @State private var viewModel: {Feature}ViewModel

    // MARK: - Init
    init(viewModel: {Feature}ViewModel? = nil) {
        _viewModel = State(initialValue: viewModel ?? {Feature}ViewModel(
            repository: Dependencies.shared.{feature}Repository
        ))
    }

    // MARK: - Body
    var body: some View {
        content
            .navigationTitle("{Title}")
            .task { await viewModel.load() }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            loadingView
        } else if let error = viewModel.error {
            errorView(error)
        } else {
            mainContent
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        List(viewModel.items) { item in
            // Item row
        }
    }

    @ViewBuilder
    private var loadingView: some View {
        ProgressView()
    }

    @ViewBuilder
    private func errorView(_ error: Error) -> some View {
        ContentUnavailableView(
            "Error",
            systemImage: "exclamationmark.triangle",
            description: Text(error.localizedDescription)
        )
    }
}
```

### Repository Template

```swift
// MARK: - {Feature}Repository.swift
// PURPOSE: {Brief description}
// DATA SOURCE: {Core Data / Network / Bundled}

import Foundation
import CoreData

final class {Feature}Repository: {Feature}RepositoryProtocol {
    // MARK: - Dependencies
    private let coreData: CoreDataStack

    // MARK: - Init
    init(coreData: CoreDataStack) {
        self.coreData = coreData
    }

    // MARK: - Protocol Methods

    func getItems() async throws -> [Item] {
        let request = ItemMO.fetchRequest()
        let managedObjects = try coreData.viewContext.fetch(request)
        return managedObjects.map { Item(managedObject: $0) }
    }

    func save(_ item: Item) async throws {
        let context = coreData.viewContext
        let managedObject = ItemMO(context: context)
        managedObject.update(from: item)
        try context.save()
    }
}
```

### Protocol Template

```swift
// MARK: - {Feature}RepositoryProtocol.swift
// PURPOSE: Defines contract for {feature} data access

import Foundation

protocol {Feature}RepositoryProtocol {
    /// Fetches all items
    func getItems() async throws -> [Item]

    /// Fetches item by ID
    func getItem(id: UUID) async throws -> Item?

    /// Saves an item
    func save(_ item: Item) async throws

    /// Deletes an item
    func delete(_ item: Item) async throws
}
```

---

## Error Handling

Use the standard `SafaError` enum:

```swift
enum SafaError: LocalizedError {
    case networkUnavailable
    case dataNotFound(String)
    case invalidInput(String)
    case storageError(Error)
    case permissionDenied(String)

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Network connection unavailable"
        case .dataNotFound(let item):
            return "\(item) not found"
        case .invalidInput(let reason):
            return "Invalid input: \(reason)"
        case .storageError(let underlying):
            return "Storage error: \(underlying.localizedDescription)"
        case .permissionDenied(let permission):
            return "\(permission) permission denied"
        }
    }
}
```

---

## Navigation

Use `AppRouter` for all navigation:

```swift
// Navigate to a destination
router.navigate(to: .surah(number: 2))

// Pop back
router.path.removeLast()

// Pop to root
router.popToRoot()

// Available destinations
enum Destination: Hashable {
    case quran
    case surah(number: Int)
    case ayah(surah: Int, ayah: Int)
    case prayer
    case qibla
    case prayerLog
    case learn
    case lesson(trackId: String, lessonId: String)
    case chat
    case hadith(collection: String?, hadithId: String?)
    case settings
    case family
}
```

---

## Testing

### Test File Location

```
Source: Features/Prayer/PrayerViewModel.swift
Test:   Tests/Features/Prayer/PrayerViewModelTests.swift
```

### Test Template

```swift
import XCTest
@testable import Safa

final class {Feature}ViewModelTests: XCTestCase {
    var sut: {Feature}ViewModel!
    var mockRepository: Mock{Feature}Repository!

    override func setUp() {
        super.setUp()
        mockRepository = Mock{Feature}Repository()
        sut = {Feature}ViewModel(repository: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    func test_load_success() async {
        // Given
        mockRepository.itemsToReturn = [.mock()]

        // When
        await sut.load()

        // Then
        XCTAssertEqual(sut.items.count, 1)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
    }

    func test_load_failure() async {
        // Given
        mockRepository.errorToThrow = SafaError.networkUnavailable

        // When
        await sut.load()

        // Then
        XCTAssertTrue(sut.items.isEmpty)
        XCTAssertNotNil(sut.error)
    }
}
```

### Writing Effective Tests

**Test correctness, not conformance.** Every test should verify that the code does the right thing — not just that it does what it currently does. A test that stores a value and asserts it was stored is tautological. A good test proves a behavior contract that would catch real bugs.

**Ask:** "If someone introduced a bug here, would this test fail?" If the answer is no, the test has no value.

| Bad (conformance) | Good (correctness) |
|---|---|
| `XCTAssertNotNil(modifier.error)` after setting error | Verify that when `error != nil`, ErrorView is rendered instead of content |
| `XCTAssertNil(screen.stickyContent)` on convenience init | Verify that scrolling past threshold shows the sticky content in the toolbar |
| `XCTAssertEqual(toast.actionTitle, "Undo")` | Verify that tapping Undo actually reverts the state change |

**Prioritize:**
1. **Behavior tests** — call a method, assert the observable outcome (state change, side effect, return value)
2. **Edge case tests** — boundary inputs, error paths, race conditions
3. **Regression tests** — reproduce a known bug, prove the fix works

**Avoid:**
- Testing that a property you just set has the value you set it to
- Testing that a struct initializer stores its parameters
- Tests that would pass even if the feature were completely broken

**For SwiftUI views without ViewInspector:** Extract testable logic into standalone functions or ViewModel methods rather than testing View property storage. If logic is locked behind `private`, extract it to an `internal` helper to enable real correctness tests.

---

## File Size Limits

| File Type | Target | Maximum |
|-----------|--------|---------|
| View | 50-150 lines | 250 lines |
| ViewModel | 50-200 lines | 300 lines |
| Repository | 100-300 lines | 400 lines |
| Component | 20-80 lines | 150 lines |
| Entity | 20-50 lines | 100 lines |

**If exceeding max**: Split into smaller files.

---

## Dependencies Access

Access dependencies via environment in Views:

```swift
@Environment(Dependencies.self) private var dependencies

// Use
dependencies.prayerRepository
dependencies.userState
dependencies.audioPlayer
```

Or construct ViewModels with explicit injection:

```swift
{Feature}ViewModel(repository: dependencies.{feature}Repository)
```

---

## Common Tasks

### Adding a New Feature

1. Create folder: `Features/{FeatureName}/`
2. Create protocol: `Domain/Protocols/{Feature}RepositoryProtocol.swift`
3. Create repository: `Data/Repositories/{Feature}Repository.swift`
4. Create ViewModel: `Features/{Feature}/{Feature}ViewModel.swift`
5. Create View: `Features/{Feature}/{Feature}View.swift`
6. Add to Dependencies container
7. Add navigation destination to AppRouter
8. Write tests

### Adding a New Entity

1. Create entity: `Domain/Entities/{Entity}.swift`
2. Add Core Data managed object: `Data/Local/CoreData/ManagedObjects/{Entity}MO.swift`
3. Update `.xcdatamodeld` schema
4. Add mapping between entity and managed object

### Adding a New Component

1. Create in appropriate folder: `Shared/Components/{Category}/{Component}.swift`
2. Keep under 150 lines
3. Make it configurable via parameters
4. Document with header comment

---

## Don'ts

- **Don't** use `print()` - use proper logging if needed
- **Don't** force unwrap (`!`) - use safe unwrapping
- **Don't** use stringly-typed APIs - use enums
- **Don't** put business logic in Views - use ViewModels
- **Don't** access Core Data directly from Views - use Repositories
- **Don't** hardcode strings - use constants or localization
- **Don't** exceed file size limits - split instead
- **Don't** use abbreviations in names - be explicit (`.muslimWorldLeague` not `.mwl`)
- **Don't** duplicate type names across files - rename if needed (e.g., `HomeStatItem` vs `StatItem`)
- **Don't** use `class` for stateless types - use `struct` (avoids heap allocation bugs; see PrayerTimeCalculator SIGABRT fix)
- **Don't** access `.shared` singletons directly from ViewModels or business logic - inject via `Dependencies` container or init parameters instead. Singletons hide dependencies and make testing harder. Existing `.shared` usage is legacy; new code should prefer injection.

---

## Do's

- **Do** follow the exact templates provided
- **Do** include header comments with PURPOSE, DEPENDENCIES
- **Do** use `async/await` for asynchronous code
- **Do** handle all error cases
- **Do** write tests for new code
- **Do** keep files focused on single responsibility
- **Do** use meaningful variable names
- **Do** prefer `struct` over `class` unless you need reference semantics (mutable shared state, `@Observable`, inheritance, `NSObject`)
- **Do** inject services through `Dependencies` container or init parameters for testability
- **Do** place feature-specific settings close to the feature (inline controls, context menus, long-press options) rather than in the global Settings tab. Global Settings is for app-wide preferences only.
- **Do** build and run tests immediately after changes (see below)

---

## Build-Test-Verify Workflow

**CRITICAL: Every code change MUST build successfully and have test coverage before proceeding.**

### Mandatory Build Verification

After **every** code change:

1. **Build immediately:**
   ```bash
   xcodebuild -scheme Safa -destination 'platform=iOS Simulator,name=iPhone 15' build
   ```

2. **If build fails → Fix and rebuild (iteration loop):**
   - Read the error message carefully
   - Fix the issue
   - Rebuild
   - Repeat until build passes
   - **Maximum 5 iterations** - if still failing, revert changes

3. **If build cannot be fixed → Revert:**
   ```bash
   git checkout -- <modified-files>
   ```
   Then reassess the approach before trying again.

### Test Coverage Requirement

**All code changes must be covered by tests:**

1. **Run existing tests** to ensure no regressions:
   ```bash
   xcodebuild -scheme Safa -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
     -only-testing:SafaTests -parallel-testing-enabled NO test
   ```

2. **Write new tests** for new/modified code:
   - New features: Add corresponding test file
   - Bug fixes: Add test that would have caught the bug
   - Refactors: Ensure existing tests still pass

3. **Run specific test file** (faster feedback):
   ```bash
   xcodebuild -scheme Safa -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
     -only-testing:SafaTests/{TestClassName} -parallel-testing-enabled NO test
   ```

### Simulator Resource Management

**IMPORTANT: Run simulator tests in SERIES, not parallel. Only ONE simulator instance at a time.**

- **ALWAYS** pass `-parallel-testing-enabled NO` to `xcodebuild test` — without this flag, Xcode spawns multiple simulator clones that cause "Safa quit unexpectedly" crashes (SIGABRT / memory corruption)
- This machine has limited resources - spawning multiple simulators can cause failures
- Do NOT run multiple `xcodebuild test` commands in parallel
- When running tests, wait for one test run to complete before starting another
- Prefer running unit tests only (`-only-testing:SafaTests`) over full test suites when possible
- UI tests (`SafaUITests`) are resource-intensive and may fail due to simulator launch issues

### Complete Workflow

```
1. Write/modify code
2. Build → If fails, fix and rebuild (max 5 attempts, else revert)
3. Write/update tests for the changes
4. Run quick checks during iteration (targeted tests + build)
5. Run full checks before commit (build + SafaTests + lint/format validation when configured)
6. Only proceed to next task when full checks pass
7. Commit completed feature → Once checks are green, commit before moving on
```

### Build & Test via Skill (Preferred)

**Use the `xcode-build` skill or `/build` and `/test` commands instead of running xcodebuild directly.** These filter Xcode's verbose output to avoid filling the context window.

- **Skill** (`xcode-build`): Auto-invoked by the agent, uses haiku model. Pass `build`, `test`, or `test --class ClassName`.
- **Commands**: `/build` and `/test` for manual invocation.
- Both support `--platform`, `--scheme`, and `--class` parameters.

### Local Checks Standard (No CI Yet)

Use this local-first model until CI exists:

1. **Quick checks** (while coding):
   - `/build`
   - `/test <TestClassName>` for touched areas

2. **Full checks** (required before commit):
   - `/build`
   - `/test`
   - `swiftlint lint Safa/ SafaTests/` (must report 0 violations)

3. **Quick matrix** (when touching layout, frames, sizing, or UI components):
   - `/build --matrix` — builds on iOS 17 SE (375pt), iOS 18 Pro Max (430pt), iOS 26 Pro (402pt)
   - `/test --matrix` — runs full test suite on same 3 configs sequentially

4. **Full matrix** (before releases or after significant changes):
   - `/build --matrix-full` — builds on 7 configs across iOS 17/18/26 and all screen sizes
   - `/test --matrix-full` — runs full test suite on all 7 configs sequentially

Terminology note: use **`full checks`** (this replaces `fast-ci` wording).

### Run Full Checks Before Committing

**CRITICAL: Always run full checks before committing any changes.**

Use `/build` and `/test` (or xcode-build skill equivalents). Alternatively:

```bash
xcodebuild -scheme Safa -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
xcodebuild -scheme Safa -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:SafaTests -parallel-testing-enabled NO test
```

- Build and unit tests must pass before committing
- SwiftLint must pass with 0 violations: `swiftlint lint Safa/ SafaTests/`
- If a test fails, fix the issue and re-run tests
- Never commit with known failing tests
- Run tests in series (one simulator at a time) to avoid resource issues

### Commit Regularly

**Commit after each completed feature or logical change once full checks are green.**

- Do not accumulate multiple unrelated changes before committing
- Each commit should represent a coherent, working unit of change
- Write clear commit messages summarizing what changed and why
- This ensures progress is saved, changes are reviewable, and rollback is easy if needed

### Branching Strategy

**Every push to main triggers an Xcode Cloud build in App Store Connect.** To avoid excessive cloud builds, use feature branches for daily work and only merge to main when ready to ship:

```
main               ← only merged into, never committed to directly
 └─ feature/xyz    ← daily work happens here
```

**Daily workflow:**
1. Create a feature branch: `git checkout -b feature/qibla-redesign`
2. Commit freely to the branch (no cloud builds triggered)
3. Run full checks (`/build`, `/test`, lint) on the branch
4. When ready, merge to main and release:
   ```bash
   git checkout main && git merge feature/qibla-redesign
   bin/release patch   # bumps version, tags, pushes — triggers one cloud build
   ```
5. Delete the branch: `git branch -d feature/qibla-redesign`

**When to merge to main:**
- A feature or logical group of changes is complete and tested
- End of a work session with meaningful progress
- A bug fix that should ship immediately

**When NOT to merge to main:**
- Work-in-progress commits (keep on feature branch)
- Intermediate refactors that aren't self-contained
- Multiple unrelated small changes — batch them into one merge

This keeps main clean, minimizes cloud builds, and ensures every main commit is a shippable state.

### Version Bumps Before Pushing Main

**CRITICAL: Every push to main must have a unique build number.** Use `bin/release` to manage versioning:

```bash
bin/release --build     # Increment build number only (for non-release pushes)
bin/release patch       # Auto-bump patch: 1.3.1 → 1.3.2 (creates tag)
bin/release minor       # Auto-bump minor: 1.3.1 → 1.4.0 (creates tag)
bin/release 2.0         # Explicit version (creates tag)
```

**Workflow:**
- For regular merges to main: merge your branch, then run `bin/release --build` to bump the build number and push
- For feature releases: merge your branch, then run `bin/release patch` (or `minor`/explicit version) to bump, tag, and push
- **Never `git push main` directly** — always go through `bin/release` so the build number is incremented
- The script handles commit + push atomically; working tree must be clean before running

### Common Build Issues

| Error | Solution |
|-------|----------|
| "Cannot find type" | Check imports, verify file is in target |
| "Missing argument" | Check function signature matches protocol |
| "Type mismatch" | Verify entity ↔ managed object mapping |
| "Ambiguous reference" | Use full type name or alias |
| "Invalid redeclaration" | Search for duplicate type names, rename one |

### When to Revert

Revert your changes if:
- Build fails after 5 fix attempts
- Fix requires changes outside the scope of the task
- Fix introduces more complexity than the original change
- You're unsure why the build is failing

**It's better to revert and try a different approach than to compound errors.**

### Never Skip Testing

- Even "small" changes can break things
- Build errors compound if not caught early
- Tests document expected behavior
- Passing tests = confidence to continue

---

## Reference Documents

| Document | Location | Purpose |
|----------|----------|---------|
| Design Doc | `.docs/DESIGN.md` | Product requirements |
| Technical Doc | `.docs/TECHNICAL.md` | Technical specifications |
| Task List | `.docs/TASKS.md` | Development progress |

---

## Project-Specific Notes

### Islamic Content
- Always use proper transliteration for Arabic terms
- Include both Arabic text and English translation where applicable
- Be respectful of religious content

### Design System
- Use `Theme` for colors, fonts, spacing
- Components are in `Shared/Components/`
- Keep UI minimal and clean per design doc

### Data Sources
- Quran/Hadith data bundled in `Resources/Data/`
- User data in Core Data with CloudKit sync
- Audio downloaded async over WiFi only

### App Defaults (Single Source of Truth)
All defaults are centralized in `Core/Constants/AppDefaults.swift`:
- **CloudKit/iCloud sync:** `useCloudKit = false` — set to `true` when paid Apple Developer account is available. This single flag switches between `NSPersistentContainer` (local) and `NSPersistentCloudKitContainer` (iCloud sync).
- **Calculation method:** `.muslimWorldLeague` (MWL)
- **Madhab:** `.hanafi`
- **Default location:** London, UK (fallback when GPS unavailable)
- Change these values in one place to update across entire app

### Location Intelligence
- `LocationInferenceService` infers user preferences from location
- Maps countries to calculation methods, madhabs, languages
- Used in Onboarding and Settings for smart recommendations

### Disabled Feature Pattern
For features not yet ready, use the disabled feature pattern:

```swift
// Using FeatureFlags enum (preferred)
Button("AI Chat") { ... }
    .disabledFeature(.aiCompanion)

// Using custom flag
SomeView()
    .disabledFeature(isDisabled: !isReady, name: "Feature Name")

// Disabled row component for lists
DisabledFeatureRow(
    title: "Spotlight Search",
    icon: "magnifyingglass",
    feature: .spotlightSearch
)
```

Key components:
- `FeatureFlags.swift` - Toggle management with persistence
- `DisabledFeatureModifier.swift` - View modifier for disabled state
- `ToastView.swift` - Contains `ToastService` for "Coming soon" messages
- Apply `.toastContainer()` to root view to enable toasts

**MANDATORY:** Every unimplemented or partially implemented feature MUST use this pattern.
- **Never** leave a button/link that navigates to an empty or broken screen
- **Never** use manual "coming soon" placeholder text — always use `.disabledFeature()` or `DisabledFeatureRow`
- **Never** silently hide a planned feature — show it greyed out so users know it's coming
- If a feature exists in `FeatureFlags.Feature` enum and `isDisabled()`, its UI entry point must use `.disabledFeature()`

---

## Getting Help

If you need clarification:
1. Check the reference documents first
2. Look for similar patterns in existing code
3. Ask for clarification before making assumptions

---

*Last Updated: February 2026*
