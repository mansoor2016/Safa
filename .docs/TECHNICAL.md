# Safa - Technical Requirements Document

## Version 0.9 (Pre-Production)

---

## 1. Platform & Technology Stack

### 1.1 Target Platform
- **Primary Platform**: iOS (iPhone)
- **Minimum iOS Version**: iOS 26.0 (latest SwiftUI, @Observable, NavigationPath)
- **AI Companion**: Apple Foundation Models (included in iOS 26)
- **Devices**: iPhone (no iPad optimization initially)
- **Future**: watchOS 10+ companion app (see Section 15)

### 1.1.1 Supported Device Matrix

**Target: iOS 26.0+** — Devices that support iOS 26.

| Device | Year | Chip | Screen | Support Tier |
|--------|------|------|--------|--------------|
| iPhone 17 Pro Max | 2025 | A19 Pro | 6.9" | Tier 1 - Primary |
| iPhone 17 Pro | 2025 | A19 Pro | 6.3" | Tier 1 - Primary |
| iPhone 17 / Air | 2025 | A19 | 6.1"/6.6" | Tier 1 - Primary |
| iPhone 16 Pro Max | 2024 | A18 Pro | 6.9" | Tier 2 - High |
| iPhone 16 Pro | 2024 | A18 Pro | 6.3" | Tier 2 - High |
| iPhone 16 / Plus | 2024 | A18 | 6.1"/6.7" | Tier 2 - High |
| iPhone 15 Pro Max | 2023 | A17 Pro | 6.7" | Tier 3 - Medium |
| iPhone 15 Pro | 2023 | A17 Pro | 6.1" | Tier 3 - Medium |
| iPhone 15 / Plus | 2023 | A16 | 6.1"/6.7" | Tier 3 - Medium |
| iPhone SE (3rd) | 2022 | A15 | 4.7" | Tier 4 - Compact |

**Feature Availability by iOS Version:**

**Target: iOS 26.0+** — All features available on the target platform. No multi-version degradation matrix needed.

| Feature | iOS 26.0+ |
|---------|-----------|
| Core app (Prayer, Quran, Learn) | ✅ |
| Gamification (Hasanat, Streaks) | ✅ |
| Widgets (Home, Lock Screen) | ✅ |
| Live Activities & Dynamic Island | ✅ |
| AI Companion (Apple Foundation Models) | ✅ |
| Siri Shortcuts & App Intents | ✅ |
| CloudKit Sync | ✅ (requires `AppDefaults.useCloudKit = true` + paid dev account) |
| watchOS Companion | v2 |
| Assistive Access Mode | v2 |

### 1.2 Language & Frameworks
| Layer | Technology |
|-------|------------|
| **Language** | Swift 5.9+ |
| **UI Framework** | SwiftUI (primary), UIKit (where necessary) |
| **Architecture** | MVVM with Clean Architecture principles |
| **Async** | Swift Concurrency (async/await, Actors) |
| **Dependency Injection** | Swift native (Protocol-based DI) |

### 1.3 Core iOS Frameworks
| Framework | Purpose |
|-----------|---------|
| **SwiftUI** | All UI components |
| **WidgetKit** | Home screen widgets |
| **ActivityKit** | Live Activities & Dynamic Island |
| **CoreLocation** | Prayer time calculation, Qibla direction |
| **CoreMotion** | Compass heading for Qibla |
| **AVFoundation** | Audio playback (Quran recitation, dhikr) |
| **Speech** | Speech recognition for pronunciation |
| **CoreML** | On-device LLM inference |
| **CoreData** | Local persistence |
| **UserNotifications** | Prayer reminders, alerts |
| **BackgroundTasks** | Background refresh for prayer times |
| **StoreKit 2** | Donations/tips |
| **CloudKit** | Cross-device sync |
| **FamilyControls** | Family sharing features |
| **AppIntents** | Siri Shortcuts, Apple Intelligence integration |
| **EventKit** | Calendar integration (Islamic events) |
| **HealthKit** | Ramadan fasting tracking |
| **CoreSpotlight** | iOS Spotlight search for Quran/Hadith/Duas |
| **WatchConnectivity** | (v2) iPhone ↔ Watch data sync |
| **ClockKit/WidgetKit** | (v2) watchOS complications |

---

## 2. Architecture

### 2.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        App Layer                                 │
│  ┌─────────────┐ ┌─────────────┐ ┌───────────────────────────┐  │
│  │  SafaApp    │ │  AppRouter  │ │  Dependencies Container   │  │
│  └─────────────┘ └─────────────┘ └───────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────┼───────────────────────────────────┐
│                    Presentation Layer                            │
│  ┌──────────────────────────▼──────────────────────────────────┐│
│  │  Feature Modules (Prayer, Quran, Learn, Chat, etc.)         ││
│  │  Each contains: Views, ViewModels, Feature-specific logic   ││
│  └─────────────────────────────────────────────────────────────┘│
│  ┌─────────────────────────────────────────────────────────────┐│
│  │  Shared UI: Components, Styles, Design System               ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────┼───────────────────────────────────┐
│                      Domain Layer                                │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │ UserState   │  │  UseCases   │  │  Domain Entities        │  │
│  │ Manager     │  │ (complex    │  │  (Prayer, Surah, etc.)  │  │
│  │ (global)    │  │  logic only)│  │                         │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────┼───────────────────────────────────┐
│                       Data Layer                                 │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                    Repositories                             ││
│  └───────┬─────────────┬─────────────┬─────────────┬───────────┘│
│    ┌─────▼─────┐ ┌─────▼─────┐ ┌─────▼─────┐ ┌─────▼─────┐     │
│    │ CoreData  │ │ CloudKit  │ │  Network  │ │  CoreML   │     │
│    │ + SQLite  │ │   Sync    │ │   APIs    │ │   LLM     │     │
│    └───────────┘ └───────────┘ └───────────┘ └───────────┘     │
└─────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────┼───────────────────────────────────┐
│                    Extensions (Separate Targets)                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │  Widgets    │  │    Live     │  │     Siri Intents        │  │
│  │             │  │  Activities │  │                         │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
│                              │                                   │
│              ┌───────────────▼───────────────┐                  │
│              │  Shared Module (App Group)    │                  │
│              │  - Shared Core Data           │                  │
│              │  - Shared Models              │                  │
│              │  - Shared UserDefaults        │                  │
│              └───────────────────────────────┘                  │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 Key Architectural Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Architecture Pattern** | MVVM (simplified) | ViewModels access Repositories directly; UseCases only for complex logic |
| **DI Approach** | SwiftUI Environment + Constructor | No external framework; explicit and testable |
| **Navigation** | NavigationPath + AppRouter | Supports deep linking from widgets/notifications |
| **Global State** | UserStateManager (@Observable) | Single source of truth for gamification |
| **Data Sharing** | App Groups | Required for Widgets and Live Activities |
| **Sync** | NSPersistentCloudKitContainer | Automatic Core Data ↔ CloudKit sync |

### 2.3 Module Structure

```
Safa/
├── App/
│   ├── SafaApp.swift                 # App entry point
│   ├── AppRouter.swift               # Navigation coordinator
│   ├── Dependencies.swift            # DI container
│   └── AppDelegate.swift             # UIKit lifecycle (if needed)
│
├── Core/
│   ├── Extensions/                   # Swift extensions (one file per type)
│   │   ├── Date+Extensions.swift
│   │   ├── String+Extensions.swift
│   │   └── View+Extensions.swift
│   ├── Utilities/
│   │   ├── HijriDateConverter.swift
│   │   ├── PrayerTimeCalculator.swift
│   │   └── QiblaCalculator.swift
│   ├── Constants/
│   │   ├── AppConstants.swift
│   │   ├── AppDefaults.swift          # Single source of truth for defaults
│   │   └── IslamicConstants.swift
│   ├── Services/
│   │   └── LocationInferenceService.swift  # Location-based settings inference
│   └── DesignSystem/
│       ├── Colors.swift              # Color palette with theme support
│       ├── Typography.swift          # Font styles (FontConfig for centralized control)
│       ├── Spacing.swift             # Layout constants
│       └── Theme.swift               # Theme manager
│
├── Domain/
│   ├── Entities/                     # One file per entity
│   │   ├── Prayer.swift
│   │   ├── Surah.swift
│   │   ├── Ayah.swift
│   │   ├── Hadith.swift
│   │   ├── Dua.swift
│   │   ├── Streak.swift
│   │   └── Achievement.swift
│   ├── State/
│   │   └── UserStateManager.swift    # Global gamification state
│   ├── UseCases/                     # Only for complex business logic
│   │   ├── CalculateHasanatUseCase.swift
│   │   ├── UpdateStreakUseCase.swift
│   │   └── CheckAchievementsUseCase.swift
│   └── Protocols/                    # Repository interfaces
│       ├── PrayerRepositoryProtocol.swift
│       ├── QuranRepositoryProtocol.swift
│       └── UserRepositoryProtocol.swift
│
├── Data/
│   ├── Repositories/                 # One file per repository
│   │   ├── PrayerRepository.swift
│   │   ├── QuranRepository.swift
│   │   ├── HadithRepository.swift
│   │   ├── DuaRepository.swift
│   │   ├── UserRepository.swift
│   │   └── ChatRepository.swift
│   ├── Local/
│   │   ├── CoreData/
│   │   │   ├── CoreDataStack.swift
│   │   │   ├── Safa.xcdatamodeld
│   │   │   └── ManagedObjects/       # One file per managed object
│   │   │       ├── PrayerLogMO.swift
│   │   │       ├── QuranProgressMO.swift
│   │   │       └── StreakMO.swift
│   │   └── UserDefaults/
│   │       └── PreferencesStore.swift
│   ├── Remote/
│   │   ├── NetworkClient.swift
│   │   └── Endpoints/
│   │       └── AudioEndpoints.swift
│   ├── Sync/
│   │   └── CloudKitSyncService.swift
│   └── ML/
│       ├── LLMService.swift
│       └── SystemPrompts.swift
│
├── Features/                         # Each feature is self-contained
│   ├── Home/
│   │   ├── HomeView.swift
│   │   ├── HomeViewModel.swift
│   │   └── Components/
│   │       ├── PrayerCountdownCard.swift
│   │       └── PrayerTimelineView.swift
│   ├── Prayer/
│   │   ├── PrayerView.swift          # Feature entry point
│   │   ├── PrayerViewModel.swift
│   │   ├── Views/
│   │   │   ├── PrayerTimesListView.swift
│   │   │   ├── QiblaCompassView.swift
│   │   │   └── PrayerLogView.swift
│   │   └── Components/
│   │       ├── PrayerTimeRow.swift
│   │       └── CompassNeedle.swift
│   ├── Quran/
│   │   ├── QuranView.swift
│   │   ├── QuranViewModel.swift
│   │   ├── Views/
│   │   │   ├── SurahListView.swift
│   │   │   ├── AyahReaderView.swift
│   │   │   └── AudioPlayerView.swift
│   │   └── Components/
│   │       ├── AyahRow.swift
│   │       └── SurahHeader.swift
│   ├── Learn/
│   │   ├── LearnView.swift
│   │   ├── LearnViewModel.swift
│   │   ├── Views/
│   │   │   ├── TrackListView.swift
│   │   │   ├── LessonView.swift
│   │   │   └── PronunciationView.swift
│   │   └── Components/
│   │       ├── ProgressRing.swift
│   │       └── LessonCard.swift
│   ├── Chat/
│   │   ├── ChatView.swift
│   │   ├── ChatViewModel.swift
│   │   └── Components/
│   │       ├── MessageBubble.swift
│   │       └── TypingIndicator.swift
│   ├── Dhikr/
│   │   ├── DhikrView.swift
│   │   ├── DhikrViewModel.swift
│   │   ├── Views/
│   │   │   ├── TasbeehCounterView.swift
│   │   │   ├── DhikrListView.swift
│   │   │   └── DuaCategoryView.swift
│   │   └── Components/
│   │       ├── CounterButton.swift
│   │       └── DhikrProgressBar.swift
│   ├── Hadith/
│   │   ├── HadithView.swift
│   │   ├── HadithViewModel.swift
│   │   └── Views/
│   │       ├── CollectionListView.swift
│   │       └── HadithDetailView.swift
│   ├── Calendar/
│   │   ├── CalendarView.swift
│   │   ├── CalendarViewModel.swift
│   │   └── Components/
│   │       └── HijriDateCell.swift
│   ├── Family/
│   │   ├── FamilyView.swift
│   │   ├── FamilyViewModel.swift
│   │   └── Views/
│   │       ├── FamilyCircleView.swift
│   │       └── InviteMemberView.swift
│   ├── Ramadan/
│   │   ├── RamadanView.swift
│   │   ├── RamadanViewModel.swift
│   │   └── Views/
│   │       ├── FastingTrackerView.swift
│   │       ├── TaraweehTrackerView.swift
│   │       └── ZakatCalculatorView.swift
│   ├── WindDown/
│   │   ├── WindDownView.swift
│   │   ├── WindDownViewModel.swift
│   │   └── Components/
│   │       └── SleepDhikrChecklist.swift
│   ├── Settings/
│   │   ├── SettingsView.swift
│   │   ├── SettingsViewModel.swift
│   │   └── Views/
│   │       ├── PrayerSettingsView.swift
│   │       ├── NotificationSettingsView.swift
│   │       ├── AppearanceSettingsView.swift
│   │       └── DownloadsView.swift
│   └── Onboarding/
│       ├── OnboardingView.swift
│       ├── OnboardingViewModel.swift
│       └── Views/
│           ├── WelcomeView.swift
│           ├── LocationPermissionView.swift
│           └── NotificationPermissionView.swift
│
├── Shared/
│   ├── Components/                   # Reusable UI components
│   │   ├── Buttons/
│   │   │   ├── PrimaryButton.swift
│   │   │   └── SecondaryButton.swift
│   │   ├── Cards/
│   │   │   ├── ContentCard.swift
│   │   │   └── ReminderCard.swift
│   │   ├── Inputs/
│   │   │   └── SearchBar.swift
│   │   └── Feedback/
│   │       ├── LoadingView.swift
│   │       └── EmptyStateView.swift
│   └── Localization/
│       └── Localizable.xcstrings
│
├── SafaWidgets/                      # Widget Extension Target
│   ├── SafaWidgets.swift             # Widget bundle
│   ├── PrayerTimeWidget/
│   │   ├── PrayerTimeWidget.swift
│   │   └── PrayerTimeWidgetView.swift
│   ├── StreakWidget/
│   │   ├── StreakWidget.swift
│   │   └── StreakWidgetView.swift
│   └── Shared/                       # Shared with main app via App Group
│       └── WidgetDataProvider.swift
│
├── SafaIntents/                      # Siri Intents Extension Target
│   └── IntentHandler.swift
│
└── Resources/
    ├── Assets.xcassets
    ├── Fonts/
    │   └── Arabic/
    ├── Audio/
    │   └── Bundled/                  # Small essential audio files
    └── Data/
        ├── quran.sqlite              # Bundled Quran database
        ├── hadith.sqlite             # Bundled Hadith database
        └── duas.json                 # Bundled Duas
```

### 2.4 App Groups Configuration

For sharing data between main app and extensions:

```swift
// App Group identifier
let appGroupIdentifier = "group.com.safa.app"

// Shared UserDefaults
let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier)

// Shared Core Data store URL
let sharedStoreURL = FileManager.default
    .containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)!
    .appendingPathComponent("Safa.sqlite")
```

### 2.5 Navigation (AppRouter)

```swift
@Observable
final class AppRouter {
    var path = NavigationPath()
    var selectedTab: String = "home"  // Cross-tab navigation (home/quran/prayer/learn/more)
    var activeSheet: Sheet?
    var activeAlert: AlertType?

    enum Destination: Hashable {
        // Quran
        case quran
        case surah(number: Int)
        case ayah(surah: Int, ayah: Int)

        // Prayer
        case prayer
        case qibla
        case prayerLog

        // Learn
        case learn
        case lesson(trackId: String, lessonId: String)

        // Other
        case chat
        case hadith(collection: String?, hadithId: String?)
        case settings
        case family
    }

    func navigate(to destination: Destination) {
        path.append(destination)
    }

    func popToRoot() {
        path.removeLast(path.count)
    }

    func handleDeepLink(_ url: URL) -> Bool {
        // Parse URL and navigate
        // safa://quran/2/255 → .ayah(surah: 2, ayah: 255)
        // safa://prayer → .prayer
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme == "safa" else {
            return false
        }

        switch components.host {
        case "quran":
            // Parse path for surah/ayah
            navigate(to: .quran)
        case "prayer":
            navigate(to: .prayer)
        default:
            return false
        }
        return true
    }
}
```

### 2.6 Dependencies Container

```swift
@Observable
final class Dependencies {
    // Repositories
    let prayerRepository: PrayerRepositoryProtocol
    let quranRepository: QuranRepositoryProtocol
    let hadithRepository: HadithRepositoryProtocol
    let duaRepository: DuaRepositoryProtocol
    let userRepository: UserRepositoryProtocol
    let chatRepository: ChatRepositoryProtocol

    // Services
    let audioPlayer: AudioPlayerService
    let notificationService: NotificationService
    let locationService: LocationService
    let llmService: LLMService

    // Global State
    let userState: UserStateManager

    init() {
        // Initialize Core Data stack
        let coreDataStack = CoreDataStack.shared

        // Initialize repositories
        self.prayerRepository = PrayerRepository(coreData: coreDataStack)
        self.quranRepository = QuranRepository(coreData: coreDataStack)
        self.hadithRepository = HadithRepository(coreData: coreDataStack)
        self.duaRepository = DuaRepository(coreData: coreDataStack)
        self.userRepository = UserRepository(coreData: coreDataStack)
        self.chatRepository = ChatRepository(llmService: LLMService())

        // Initialize services
        self.audioPlayer = AudioPlayerService()
        self.notificationService = NotificationService()
        self.locationService = LocationService()  // Falls back to London, UK (AppDefaults.defaultCoordinates) when GPS unavailable
        self.llmService = LLMService()

        // Initialize global state
        self.userState = UserStateManager(userRepository: userRepository)
    }
}
```

### 2.7 AI-Agent Development Guidelines

The codebase is designed to be developed primarily by AI coding agents. The following conventions ensure agents can work effectively:

#### File Organization Principles

| Principle | Rationale |
|-----------|-----------|
| **One concept per file** | Agents have limited context windows; small files are easier to reason about |
| **Predictable naming** | `{Feature}View.swift`, `{Feature}ViewModel.swift` - agents know where to look |
| **Flat over nested** | Avoid deep folder hierarchies; 2-3 levels max |
| **Explicit over clever** | No magic, no metaprogramming - straightforward code |

#### Naming Conventions

```
Files:
  Views:       {Name}View.swift           (e.g., PrayerTimesView.swift)
  ViewModels:  {Name}ViewModel.swift      (e.g., PrayerTimesViewModel.swift)
  Repositories:{Name}Repository.swift     (e.g., PrayerRepository.swift)
  Protocols:   {Name}Protocol.swift       (e.g., PrayerRepositoryProtocol.swift)
  Extensions:  {Type}+{Feature}.swift     (e.g., Date+Hijri.swift)
  Components:  {Name}.swift               (e.g., PrayerTimeRow.swift)

Types:
  Views:       {Name}View                 (e.g., PrayerTimesView)
  ViewModels:  {Name}ViewModel            (e.g., PrayerTimesViewModel)
  Protocols:   {Name}Protocol             (e.g., PrayerRepositoryProtocol)
  Entities:    {Name}                     (e.g., Prayer, Surah)
  Managed Obj: {Name}MO                   (e.g., PrayerLogMO)
```

#### Code Style for AI Agents

```swift
// GOOD: Explicit, self-documenting
final class PrayerViewModel: ObservableObject {
    @Published private(set) var prayers: [Prayer] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?

    private let repository: PrayerRepositoryProtocol

    init(repository: PrayerRepositoryProtocol) {
        self.repository = repository
    }

    func loadPrayers(for date: Date) async {
        isLoading = true
        defer { isLoading = false }

        do {
            prayers = try await repository.getPrayers(for: date)
        } catch {
            self.error = error
        }
    }
}

// BAD: Implicit, requires context to understand
class VM: OO {
    @Published var p: [P] = []
    let r: R
    func load() async { /* ... */ }
}
```

#### File Size Guidelines

| File Type | Target Lines | Max Lines |
|-----------|--------------|-----------|
| View | 50-150 | 250 |
| ViewModel | 50-200 | 300 |
| Repository | 100-300 | 400 |
| Component | 20-80 | 150 |
| Entity | 20-50 | 100 |

**If a file exceeds max lines**: Split into smaller components or extract logic.

#### Documentation for Agents

Each file should have a header comment explaining its purpose:

```swift
// MARK: - PrayerTimesView.swift
// PURPOSE: Displays daily prayer times with countdown to next prayer
// DEPENDENCIES: PrayerViewModel, PrayerTimeRow, Theme
// NAVIGATION: Accessed from HomeView, can navigate to QiblaView

import SwiftUI

struct PrayerTimesView: View {
    // ...
}
```

#### Protocol-First Design

Define protocols before implementations - agents can understand the contract without reading the full implementation:

```swift
// In: Domain/Protocols/PrayerRepositoryProtocol.swift
protocol PrayerRepositoryProtocol {
    /// Returns prayer times for a specific date and location
    func getPrayers(for date: Date, location: Coordinates) async throws -> [Prayer]

    /// Logs a prayer as completed
    func logPrayer(_ prayer: Prayer, at time: Date) async throws

    /// Returns prayer log history for date range
    func getPrayerLogs(from: Date, to: Date) async throws -> [PrayerLog]
}

// In: Data/Repositories/PrayerRepository.swift
final class PrayerRepository: PrayerRepositoryProtocol {
    // Implementation...
}
```

#### Consistent Patterns

**ViewModel Pattern** (every ViewModel follows this structure):

```swift
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
    func load() async { }
    func refresh() async { }

    // MARK: - Private Methods
    private func handleError(_ error: Error) { }
}
```

**View Pattern** (every View follows this structure):

```swift
struct {Feature}View: View {
    // MARK: - Environment
    @Environment(Dependencies.self) private var dependencies

    // MARK: - State
    @State private var viewModel: {Feature}ViewModel

    // MARK: - Init
    init() {
        // ViewModel initialization
    }

    // MARK: - Body
    var body: some View {
        content
            .task { await viewModel.load() }
    }

    // MARK: - Subviews
    @ViewBuilder
    private var content: some View { }

    @ViewBuilder
    private var loadingView: some View { }

    @ViewBuilder
    private var errorView: some View { }
}
```

#### Error Handling Pattern

Consistent error handling agents can rely on:

```swift
enum SafaError: LocalizedError {
    case networkUnavailable
    case dataNotFound(String)
    case invalidInput(String)
    case storageError(Error)

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
        }
    }
}
```

#### Test File Convention

Each source file has a corresponding test file:

```
Source: Features/Prayer/PrayerViewModel.swift
Test:   Tests/Features/Prayer/PrayerViewModelTests.swift
```

#### Task Boundaries for Agents

When assigning work to agents, tasks should align with file boundaries:

```
GOOD Task: "Implement PrayerViewModel with load and refresh methods"
           → Agent works on single file: PrayerViewModel.swift

BAD Task:  "Implement prayer feature"
           → Too broad, spans multiple files, unclear scope
```

---

## 3. Data Layer

### 3.1 Local Storage Strategy

| Data Type | Storage | Rationale |
|-----------|---------|-----------|
| User preferences | UserDefaults | Simple key-value |
| User progress, streaks, logs | Core Data | Relational, queryable |
| Quran text & translations | Bundled SQLite + Core Data | Large dataset, read-heavy |
| Hadith collections | Bundled SQLite + Core Data | Large dataset, searchable |
| Dua & Dhikr | Bundled JSON → Core Data | Static content |
| Localization metadata | Bundled JSON + UserDefaults | Language availability manifest + user language/content preferences |
| Audio files (recitations) | Async download over WiFi + FileManager | Large files, cached |
| LLM model | Bundled in app | Required for offline |

### 3.2 Offline-First Strategy

The app is designed for comprehensive offline functionality with aggressive size optimization.

**Bundled at Install (<100MB target):**
- Quran text (Arabic + Sahih International translation) - compressed SQLite ~5MB
- Hadith collections - compressed SQLite ~15MB
- Duas and Dhikr - JSON ~1MB
- Prayer calculation algorithms
- UI assets ~10MB
- *Note: AI uses Apple Foundation Models (ships with iOS, no bundle impact)*

**Downloaded On-Demand (WiFi preferred):**
- Audio recitations (Quran + Duas)
- Additional content language packs (Quran/Hadith/Dua where available)

**Audio Download Strategy:**
- On-demand: Download when user first plays a surah
- Predictive: Background download of next surah/juz based on reading pattern
- Management: Settings → Storage → Downloaded Audio (delete/manage)
- Smart Cleanup: Auto-remove audio not played within retention period

**Smart Cleanup (Auto-Remove Unused Content):**
```swift
// MARK: - StorageCleanupService.swift

enum RetentionPeriod: String, CaseIterable {
    case oneMonth = "1 month"
    case threeMonths = "3 months"
    case sixMonths = "6 months"
    case never = "Never"

    var days: Int? {
        switch self {
        case .oneMonth: return 30
        case .threeMonths: return 90
        case .sixMonths: return 180
        case .never: return nil  // Never auto-delete
        }
    }
}

class StorageCleanupService {
    @AppStorage("retentionPeriod") var retentionPeriod: RetentionPeriod = .sixMonths

    /// Identifies audio files that haven't been played within retention period
    func getUnusedAudioFiles() async -> [AudioFile] {
        guard let days = retentionPeriod.days else { return [] }
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!

        return await audioRepository.getFilesLastPlayedBefore(cutoffDate)
    }

    /// Removes unused files (runs on background task or manually)
    func cleanupUnusedFiles() async -> StorageReclaimed {
        let unusedFiles = await getUnusedAudioFiles()
        var totalBytesReclaimed: Int64 = 0

        for file in unusedFiles {
            if await deleteFile(file) {
                totalBytesReclaimed += file.size
            }
        }

        return StorageReclaimed(bytes: totalBytesReclaimed, fileCount: unusedFiles.count)
    }
}
```

**Settings UI:**
```
Downloads & Storage
├── Downloaded Audio ──────────── 1.2 GB
│   ├── Quran (Al-Afasy) ──────── 800 MB
│   └── Quran (Sudais) ─────────── 400 MB
├── Smart Cleanup ─────────────── [Enabled]
│   └── Retention Period ────────── 6 months ▼
│                                    1 month
│                                    3 months
│                                    6 months (default)
│                                    Never
└── Clear All Downloads ─────────── [Clear]
```

**Predictive Audio Download Implementation:**

```swift
// MARK: - PredictiveDownloadService.swift

class PredictiveDownloadService {
    private let downloadManager: ContentDownloadManager
    private let quranRepository: QuranRepositoryProtocol

    /// Predict and queue next content based on user patterns
    func predictAndQueueDownloads() async {
        // Strategy 1: Next surah in sequence
        if let currentSurah = await quranRepository.getCurrentReadingProgress() {
            let nextSurah = currentSurah.surahNumber + 1
            if nextSurah <= 114 {
                await queueForBackgroundDownload(.surahAudio(number: nextSurah))
            }
        }

        // Strategy 2: Sequential juz completion
        if let currentJuz = await quranRepository.getCurrentJuz() {
            // Download remaining surahs in current juz
            let surahsInJuz = juzSurahMapping[currentJuz] ?? []
            for surah in surahsInJuz {
                await queueForBackgroundDownload(.surahAudio(number: surah))
            }
        }

        // Strategy 3: Frequently accessed content
        let frequentSurahs = await quranRepository.getMostReadSurahs(limit: 5)
        for surah in frequentSurahs {
            await queueForBackgroundDownload(.surahAudio(number: surah.number))
        }
    }

    /// Queue download for when WiFi is available
    func queueForBackgroundDownload(_ content: ContentType) async {
        guard !isAlreadyDownloaded(content) else { return }
        guard !isInDownloadQueue(content) else { return }

        await downloadManager.scheduleForWiFi(content)
    }
}

// Background task integration
extension AppDelegate {
    func scheduleBackgroundAudioDownload() {
        let request = BGProcessingTaskRequest(identifier: "com.safa.audioDownload")
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false // Can run on battery
        try? BGTaskScheduler.shared.submit(request)
    }
}
```

**Download Triggers:**
1. User finishes a surah → queue next surah
2. User opens Quran for first time today → check predictions
3. WiFi connected after being on cellular → process queue
4. Background refresh task → predictive downloads

**Disabled Feature Pattern:**
Unimplemented features display greyed out with "Coming soon" message rather than being hidden. This shows users what's planned while preventing confusion.

```swift
// MARK: - DisabledFeatureModifier.swift

struct DisabledFeatureModifier: ViewModifier {
    let isEnabled: Bool
    let featureName: String

    func body(content: Content) -> some View {
        if isEnabled {
            content
        } else {
            content
                .opacity(0.5)
                .disabled(true)
                .overlay(alignment: .bottomTrailing) {
                    Text("Coming soon")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(4)
                }
                .onTapGesture {
                    // Show toast: "This feature is coming in a future update"
                    ToastService.shared.show("\(featureName) coming in a future update")
                }
        }
    }
}

extension View {
    func disabledFeature(_ isEnabled: Bool, name: String) -> some View {
        modifier(DisabledFeatureModifier(isEnabled: isEnabled, featureName: name))
    }
}

// Usage:
FeatureCard(title: "Audio Pronunciations")
    .disabledFeature(FeatureFlags.audioPronunciations, name: "Audio Pronunciations")
```

### 3.3 Async Download Manager

```swift
class ContentDownloadManager: ObservableObject {
    @Published var downloadProgress: [ContentType: Double] = [:]

    /// Downloads large content only over WiFi
    func downloadContent(_ type: ContentType) async {
        // Check for WiFi connection
        guard isOnWiFi else {
            scheduleForWiFi(type)
            return
        }

        // Download in background with progress updates
        // Resume capability for interrupted downloads
        // Store in app's Documents directory
    }

    /// Monitors network and auto-resumes when WiFi available
    func monitorNetworkAndResume() {
        // NWPathMonitor to detect WiFi
        // Resume queued downloads
    }
}

enum ContentType {
    case quranAudio(reciter: String)
    case duaAudio
    case additionalTranslation(language: String)
}
```

**Download UI:**
- Settings → Downloads shows available content packs
- Progress indicators for active downloads
- "Download All" option for full offline experience
- Estimated sizes shown before download

### 3.4 Core Data Models

```swift
// Prayer tracking
Entity: PrayerLog
- id: UUID
- prayerType: String (fajr, dhuhr, asr, maghrib, isha)
- date: Date
- loggedAt: Date
- isOnTime: Bool
- isMakeup: Bool

// Quran progress
Entity: QuranProgress
- id: UUID
- surahNumber: Int16
- ayahNumber: Int16
- lastReadAt: Date
- isBookmarked: Bool

// User streaks
Entity: Streak
- id: UUID
- type: String (daily, prayer, quran, dhikr, learning)
- currentCount: Int32
- longestCount: Int32
- lastActivityDate: Date

// Gamification
Entity: UserStats
- totalHasanat: Int64
- currentLevel: Int16
- achievementsUnlocked: [String]
- lessonsCompleted: Int32

// Family
Entity: FamilyMember
- id: UUID
- name: String
- joinedAt: Date
- visibilitySettings: Data (JSON)
```

### 3.5 Bundled Content

**Quran Data** (bundled SQLite database):
- Full Arabic text (Uthmani script)
- English translation (licensed)
- Surah metadata (name, revelation type, ayah count)
- Juz boundaries
- Word-by-word data (for learning features)

**Hadith Data** (bundled SQLite database):
- Sahih Bukhari (~7,500 hadith)
- Sahih Muslim (~7,500 hadith)
- Other collections (Tirmidhi, Abu Dawood, Nasa'i, Ibn Majah)
- Riyad as-Salihin (topical compilation)
- Metadata: book, chapter, grading, narrator chain

**Dua & Dhikr** (bundled JSON):
- Morning/evening dhikr (complete sets)
- Daily duas (categorized)
- Arabic text + transliteration + translation
- Audio file references

**Audio Content** (downloaded async over WiFi):
- Quran recitations from multiple Qaris (licensed)
- Dua audio pronunciations
- Estimated total: ~2-5 GB for full audio library

### 3.6 CloudKit Sync

Cross-device synchronization for user data using CloudKit.

**Synced Data:**
- Prayer logs
- Quran bookmarks and progress
- Streaks and Hasanat
- Achievements
- Learning progress
- User preferences
- Family circle membership

**Not Synced (Device-Local):**
- Downloaded audio files (re-download on new device)
- Cache data

```swift
// CloudKit container setup
class CloudKitSyncService {
    private let container = CKContainer(identifier: "iCloud.com.safa.app")
    private let privateDatabase: CKDatabase

    init() {
        privateDatabase = container.privateCloudDatabase
    }

    /// Sync local Core Data changes to CloudKit
    func syncToCloud() async throws {
        // Use NSPersistentCloudKitContainer for automatic sync
        // Or manual CKRecord management for fine control
    }

    /// Handle incoming changes from other devices
    func handleRemoteChanges(_ notification: Notification) {
        // Merge changes into local Core Data
    }
}
```

**Sync Strategy:**
- Use `NSPersistentCloudKitContainer` for automatic Core Data ↔ CloudKit sync
- Background sync on app launch and periodically
- Conflict resolution: Last-write-wins for most data
- Graceful degradation if iCloud unavailable

---

## 4. Prayer Times Calculation

### 4.1 Approach

**Option A: Local Calculation (Recommended)**
- Use established algorithm (e.g., PrayTimes.org)
- No network dependency
- Full offline support
- User selects calculation method

**Option B: API-based**
- Use Aladhan API or similar
- Simpler implementation
- Requires network

**Recommendation**: Local calculation with algorithm library, with optional API fallback.

### 4.2 Calculation Methods to Support

| Method | Region |
|--------|--------|
| Muslim World League (MWL) | Europe, Far East |
| Islamic Society of North America (ISNA) | North America |
| Egyptian General Authority | Africa, Middle East |
| Umm Al-Qura, Makkah | Saudi Arabia |
| University of Islamic Sciences, Karachi | Pakistan, India |
| Institute of Geophysics, Tehran | Iran |

### 4.3 Qibla Direction

```swift
// Calculate Qibla bearing from user location to Kaaba
let kaabaCoordinates = CLLocationCoordinate2D(
    latitude: 21.4225,
    longitude: 39.8262
)

func calculateQiblaDirection(from userLocation: CLLocationCoordinate2D) -> Double {
    // Great circle bearing calculation
    // Returns degrees from North (0-360)
}
```

**Required**: CoreLocation + CoreMotion for compass heading

---

## 5. AI Companion (On-Device LLM)

### 5.1 Model Selection (Resolved)

**Decision: Apple Foundation Models + RAG**

| Aspect | Choice | Rationale |
|--------|--------|-----------|
| **Primary** | Apple Foundation Models | Zero bundle size, native optimization, iOS 18.4+ |
| **Fallback** | Feature disabled | Avoid 500MB+ bundle penalty for older iOS |
| **Knowledge** | RAG (Retrieval-Augmented Generation) | Accurate, cited responses from local Quran/Hadith DB |

**Why Apple Foundation Models:**
- Ships with iOS - no bundle size impact
- Optimized for Apple Silicon - fast, efficient
- Apple's privacy guarantees - users trust it
- Native Swift API - easy integration

### 5.2 Integration Architecture

```swift
import FoundationModels

class LLMService {
    private var session: LanguageModelSession?
    private let quranRepository: QuranRepositoryProtocol
    private let hadithRepository: HadithRepositoryProtocol

    var isAvailable: Bool {
        if #available(iOS 18.4, *) {
            return LanguageModelSession.isAvailable
        }
        return false
    }

    @available(iOS 18.4, *)
    func generateResponse(for question: String) async throws -> String {
        // 1. RAG: Search local databases for relevant content
        let relevantAyahs = try await quranRepository.searchAyahs(query: question)
        let relevantHadith = try await hadithRepository.search(query: question)

        // 2. Build context-enriched prompt
        let context = buildContext(ayahs: relevantAyahs, hadith: relevantHadith)
        let prompt = """
        You are Safa Assistant, a knowledgeable Islamic companion.

        CONTEXT (from authentic sources):
        \(context)

        USER QUESTION: \(question)

        Respond using the context above. Always cite sources.
        """

        // 3. Generate response
        let session = try LanguageModelSession()
        return try await session.respond(to: prompt)
    }
}
```

### 5.3 RAG (Retrieval-Augmented Generation)

RAG ensures accurate, cited responses without fine-tuning:

```
User asks: "What breaks wudu?"
        ↓
App searches local Hadith database for "wudu" + "invalidate" + "nullify"
        ↓
Relevant hadiths retrieved with sources
        ↓
Context injected into prompt with citations
        ↓
Apple Foundation Model generates response with source references
```

**Benefits:**
- Accurate Islamic knowledge from authenticated sources
- Proper citations (Quran chapter:verse, Hadith collection)
- No fine-tuning required
- Updates with database, not model

### 5.3 System Prompt Structure

```
You are Safa Assistant, a knowledgeable and humble Islamic companion.

GUIDELINES:
- Always cite sources (Quran chapter:verse, Hadith collection)
- Present multiple scholarly opinions when they exist
- Acknowledge differences between madhabs neutrally
- Recommend consulting scholars for complex personal matters
- Use warm, encouraging tone
- Include Arabic terms with transliteration and translation
- Never claim to be a scholar or mufti
- Decline political topics and controversial issues

RESPONSE FORMAT:
- Keep responses concise but complete
- Use clear structure with headings if needed
- Always provide source references
```

---

## 6. Key Feature Technical Specs

### 6.0 Haptic System Architecture

All haptic feedback should route through `HapticFeedbackService` using a typed event enum. No direct `UIImpactFeedbackGenerator` usage in feature views.

```swift
enum HapticEvent {
    case tap            // Light — navigation, toggle
    case selection      // Selection — picker changes
    case commit         // Medium — log prayer, start lesson
    case success        // Notification success — milestone reached
    case warning        // Notification warning — degraded state
    case error          // Notification error — action failed
    case qiblaLight     // Light periodic — getting closer
    case qiblaPerfect   // Success — facing Qibla
    case tasbeehTap     // Soft — per-count
    case tasbeehMilestone // Medium + success — 33/99 count
}

class HapticFeedbackService {
    static let shared = HapticFeedbackService()

    func play(_ event: HapticEvent) {
        guard !isReduceMotionEnabled else { return }
        switch event {
        case .tap: UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .selection: UISelectionFeedbackGenerator().selectionChanged()
        case .commit: UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .success: UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning: UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error: UINotificationFeedbackGenerator().notificationOccurred(.error)
        // ... Qibla and tasbeeh patterns
        }
    }

    private var isReduceMotionEnabled: Bool {
        UIAccessibility.isReduceMotionEnabled
    }
}
```

**Settings UI:** Haptics On/Off toggle + Intensity (Subtle/Balanced/Strong) + "Test Haptic" button.

### 6.1 Widgets (WidgetKit)

**v1 Priority:**
| Widget | Size | Priority |
|--------|------|----------|
| PrayerTimeWidget | Small | ✅ Must-have |
| PrayerTimesWidget | Medium | ✅ Must-have |
| DashboardWidget | Large | ✅ Must-have |
| StreakWidget | Small | Nice-to-have |
| DailyVerseWidget | Medium | v1.1 |

```swift
// Widget families to support (v1)
struct SafaWidgets: WidgetBundle {
    var body: some Widget {
        PrayerTimeWidget()      // Small - next prayer countdown
        PrayerTimesWidget()     // Medium - all 5 prayers
        DashboardWidget()       // Large - prayer + streak + verse
        StreakWidget()          // Small - if time permits
    }
}

// Timeline provider for prayer widget
struct PrayerTimelineProvider: TimelineProvider {
    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> Void) {
        // Generate entries for each prayer time
        // Refresh at each prayer time
    }
}
```

### 6.2 Live Activities (ActivityKit)

```swift
struct PrayerActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var prayerName: String
        var prayerTime: Date
        var remainingTime: TimeInterval
    }

    var calculationMethod: String
}

// Start activity 30 min before prayer
func startPrayerActivity(for prayer: Prayer) {
    let attributes = PrayerActivityAttributes(calculationMethod: userMethod)
    let state = PrayerActivityAttributes.ContentState(
        prayerName: prayer.name,
        prayerTime: prayer.time,
        remainingTime: prayer.time.timeIntervalSinceNow
    )

    let activity = try Activity.request(
        attributes: attributes,
        content: .init(state: state, staleDate: prayer.time),
        pushType: nil
    )
}
```

### 6.3 Background Tasks

```swift
// Register background tasks
BGTaskScheduler.shared.register(
    forTaskWithIdentifier: "com.safa.prayerRefresh",
    using: nil
) { task in
    handlePrayerRefresh(task: task as! BGAppRefreshTask)
}

// Schedule daily refresh
func schedulePrayerRefresh() {
    let request = BGAppRefreshTaskRequest(identifier: "com.safa.prayerRefresh")
    request.earliestBeginDate = Calendar.current.startOfDay(for: Date()).addingTimeInterval(86400)
    try? BGTaskScheduler.shared.submit(request)
}
```

### 6.4 Audio Playback

```swift
class AudioPlayer: ObservableObject {
    private var player: AVAudioPlayer?

    func playRecitation(surah: Int, ayah: Int, reciter: String) async {
        // Check if cached locally
        // If not, download from CDN
        // Configure audio session for background playback
        // Play with proper attribution
    }
}

// Audio session for background playback
func configureAudioSession() {
    let session = AVAudioSession.sharedInstance()
    try? session.setCategory(.playback, mode: .default)
    try? session.setActive(true)
}
```

### 6.5 Speech Recognition (Pronunciation)

```swift
class PronunciationChecker {
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ar-SA"))

    func checkPronunciation(expected: String) async -> PronunciationResult {
        // Record user audio
        // Transcribe with Speech framework
        // Compare to expected Arabic text
        // Return score and feedback
    }
}
```

### 6.6 Notifications (User-Respectful)

**Philosophy:** Notifications should be useful, not annoying. Respect attention.

```swift
class NotificationService {
    // MARK: - Prayer Notifications

    /// Schedule single prayer notification
    /// - Default: 15 min before, configurable per user
    /// - Mosque mode adds extra time for travel
    func schedulePrayerNotification(
        for prayer: Prayer,
        minutesBefore: Int = 15,
        mosqueMode: Bool = false
    ) {
        let leadTime = mosqueMode ? minutesBefore + 15 : minutesBefore
        let triggerDate = prayer.time.addingTimeInterval(-Double(leadTime * 60))

        let content = UNMutableNotificationContent()
        content.title = "\(prayer.name) Prayer"
        content.body = mosqueMode
            ? "Time to head to the mosque for \(prayer.name)"
            : "\(prayer.name) in \(minutesBefore) minutes"
        // Adhan sound system: 11 reciters in CAF format
        // Full-length files in Resources/Audio/Adhan/ for playback
        // 30-second clips in Resources/Audio/Adhan/Notifications/ for notification sounds
        // Per-prayer selection: regular adhan + separate Fajr adhan (includes "prayer is better than sleep")
        // Default: system sound (adhan off). When enabled, default reciter is Mishary Alafasy
        if adhanEnabled {
            let fileName = prayer.type == .fajr ? selectedFajrAdhan : selectedAdhan
            content.sound = UNNotificationSound(named: UNNotificationSoundName("\(fileName)_notification.caf"))
        } else {
            content.sound = .default
        }
        content.categoryIdentifier = "PRAYER_REMINDER"

        // Enable action to log prayer directly from notification
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.hour, .minute], from: triggerDate),
            repeats: false
        )

        let request = UNNotificationRequest(identifier: "prayer-\(prayer.id)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Event Notifications (Useful Only)

    /// Only schedule genuinely useful event reminders
    enum IslamicEvent {
        case eidPrayer           // "Eid prayer tomorrow morning"
        case zakatDue            // "Zakat due - Ramadan ending"
        case qurbaniReminder     // "Qurbani - Eid al-Adha in 3 days"
        case ashuraFasting       // "Ashura fasting tomorrow"
        case suhoor              // Ramadan suhoor alarm
        case iftar               // Ramadan iftar time
        case jumuah              // Friday prayer (optional)
    }

    func scheduleEventNotification(_ event: IslamicEvent, date: Date) {
        // Only meaningful, time-sensitive events
        // Never daily verse, streak reminders, or "come back" messages
    }

    // MARK: - Notification Actions

    /// Register actions - tapping "Done" logs the prayer
    func registerCategories() {
        let doneAction = UNNotificationAction(
            identifier: "PRAYER_DONE",
            title: "Done ✓",
            options: .foreground
        )

        let category = UNNotificationCategory(
            identifier: "PRAYER_REMINDER",
            actions: [doneAction],
            intentIdentifiers: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}
```

**What we NEVER send:**
- ❌ Daily verse/hadith push (opt-in only, off by default)
- ❌ Streak reminders ("You're losing your streak!")
- ❌ "Come back" re-engagement spam
- ❌ Multiple reminders per prayer
- ❌ Marketing or promotional content

### 6.6.1 Smart Adhan (Technical Implementation)

```swift
// In PrayerViewModel.scheduleNotification()
private func selectNotificationSound(for prayerType: PrayerType) async -> UNNotificationSound {
    let prefs = await PreferencesManager.shared.getPreferences()

    guard prefs.adhanEnabled else { return .default }

    // Smart Adhan: check location + ringer
    if prefs.smartAdhanEnabled {
        let isAtHome = isNearHomeLocation(prefs: prefs)
        let isRingerOn = checkRingerState()

        guard isAtHome && isRingerOn else { return .default }
    }

    // Play adhan
    let fileName = prayerType == .fajr ? prefs.selectedFajrAdhan : prefs.selectedAdhan
    return UNNotificationSound(named: UNNotificationSoundName("\(fileName)_notification.caf"))
}

private func isNearHomeLocation(prefs: UserPreferences) -> Bool {
    guard let homeLat = prefs.savedLatitude,
          let homeLng = prefs.savedLongitude,
          let current = locationService.coordinates else { return false }

    let home = CLLocation(latitude: homeLat, longitude: homeLng)
    let now = CLLocation(latitude: current.latitude, longitude: current.longitude)
    return home.distance(from: now) < 200 // 200m radius
}
```

**UserPreferences additions:**
- `smartAdhanEnabled: Bool` (default: false)

**Settings UI placement:** Below the adhan picker, inside the `if adhanEnabled` block.

### 6.6.2 Mosque Mode (v2 Technical Approach)

```swift
// Geofence registration
func registerMosqueGeofence(name: String, latitude: Double, longitude: Double) {
    let region = CLCircularRegion(
        center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
        radius: 100,  // 100m
        identifier: "mosque_\(name)"
    )
    region.notifyOnEntry = true
    region.notifyOnExit = true
    locationManager.startMonitoring(for: region)
}

// On entry: suppress sounds
func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
    if region.identifier.hasPrefix("mosque_") {
        isInMosque = true
        // Override notification sound to .default (no adhan)
    }
}
```

**Data model:** `MosqueLocation` with name, coordinates, radius. Stored in UserDefaults or Core Data.

**Battery:** iOS limits to 20 geofenced regions. Sufficient for "My Mosques" use case.

### 6.7 Accessibility Implementation

**Priority:** Best effort for v1, full support in v1.1

```swift
// MARK: - VoiceOver Labels

// Prayer time with full context
PrayerTimeRow(prayer: prayer)
    .accessibilityLabel("\(prayer.name) prayer at \(prayer.time.formatted()), in \(prayer.timeUntil)")
    .accessibilityHint("Double tap to log this prayer")

// Qibla compass with direction
CompassView(heading: qiblaHeading)
    .accessibilityLabel("Qibla direction: \(qiblaHeading) degrees \(cardinalDirection)")
    .accessibilityValue(isAligned ? "Aligned with Qibla" : "Turn \(turnDirection)")

// Tasbeeh counter
CounterButton(count: count)
    .accessibilityLabel("Tasbeeh count: \(count)")
    .accessibilityHint("Tap to increment")

// Arabic Quran text
AyahView(ayah: ayah)
    .accessibilityLabel("Surah \(surahName), Ayah \(ayahNumber)")
    .accessibilityHint("Double tap to play recitation")
```

```swift
// MARK: - Dynamic Type Support

// All text uses system fonts or scaled custom fonts
extension SafaTypography {
    static let arabicLarge = Font.custom("System", size: 28, relativeTo: .title)
    // relativeTo: enables Dynamic Type scaling
}

// Large content viewer for complex displays
PrayerTimesView()
    .accessibilityShowsLargeContentViewer()
```

```swift
// MARK: - RTL Arabic Content

// Arabic text always RTL, regardless of device language
Text(arabicAyah)
    .environment(\.layoutDirection, .rightToLeft)
    .multilineTextAlignment(.trailing)

// Mixed content handled automatically by SwiftUI
VStack {
    Text(arabicText)  // RTL
    Text(englishTranslation)  // LTR
}
```

```swift
// MARK: - Reduce Motion

@Environment(\.accessibilityReduceMotion) var reduceMotion

var body: some View {
    content
        .animation(reduceMotion ? nil : .spring(), value: isExpanded)
}
```

```swift
// MARK: - Qibla Haptic Feedback

class QiblaHapticService {
    private let generator = UIImpactFeedbackGenerator(style: .medium)

    /// Pulse haptics when approaching Qibla direction
    func provideDirectionalFeedback(degreesOff: Double) {
        if abs(degreesOff) < 5 {
            // Strong pulse - aligned!
            generator.impactOccurred(intensity: 1.0)
        } else if abs(degreesOff) < 15 {
            // Medium pulse - getting close
            generator.impactOccurred(intensity: 0.6)
        } else if abs(degreesOff) < 30 {
            // Light pulse - on track
            generator.impactOccurred(intensity: 0.3)
        }
    }
}
```

**v1.1 Accessibility Roadmap:**
- Audio directional feedback for Qibla
- Voice Control optimization
- Screen reader-optimized Quran reading mode

### 6.7.1 Localization & Internationalization Architecture (Scoped)

The product supports multi-language UI for most app surfaces while religious-content translation expands independently by verified datasets.

**Language rollout:**
- Phase 1 UI languages: English (`en`), Arabic (`ar`), Indonesian (`id`), Urdu (`ur`), Bengali (`bn`)
- Phase 2 UI languages: Malay (`ms`), French (`fr`), Hindi (`hi`), Turkish (`tr`), Persian (`fa`)
- Phase 3 UI language: Chinese Simplified (`zh-Hans`)

**What Apple/Xcode localization handles directly:**
- String extraction and management with String Catalogs (`.xcstrings`)
- Localized app metadata/assets in Xcode targets
- System locale formatting (date/time/number/plural rules)
- Per-app language selection behavior in iOS settings
- RTL/LTR layout direction via locale and semantic layout APIs

**What must be implemented by app/backend/content pipeline:**
- Quran/Hadith/Dua translation datasets per language
- Availability matrix for content by feature + language
- Content-language fallback logic and user messaging for missing translations
- AI response language quality controls and safety evaluation per language

**Hard scope boundary (v1):**
- Localize app shell + settings comprehensively
- Do not promise full Quran/Hadith/Dua translation parity across all UI languages
- Treat content translations as explicit language packs with release gates

```swift
// MARK: - Localization domain separation
enum LocalizationDomain {
    case localizableUI
    case localizedContent
}

struct LanguageSupportMatrix {
    let uiLanguages: Set<String>
    let quranTranslationLanguages: Set<String>
    let hadithTranslationLanguages: Set<String>
    let duaTranslationLanguages: Set<String>
}
```

```swift
// MARK: - Fallback policy
// UI fallback: selected UI language -> English
// Content fallback: selected content language -> English -> Arabic/transliteration label if available
```

**String and locale implementation requirements:**
- All user-facing UI text must use String Catalog keys (no hardcoded literals in SwiftUI views)
- Use semantic layout (`leading`/`trailing`) and locale-aware icons for RTL compatibility
- Keep numeric/date formatting locale-driven (`FormatStyle`, `Locale.current` or selected app locale)

**Language preference model:**
- `uiLanguageCode`: app shell language
- `contentLanguageCode`: preferred language for translation bodies
- `autoInferLanguage`: optional bootstrap from location inference, always user-overridable

```swift
struct LanguagePreferences: Codable {
    var uiLanguageCode: String        // e.g. "en", "ar", "fr"
    var contentLanguageCode: String   // e.g. "en", "ur"
    var autoInferLanguage: Bool
}
```

**Extension target requirements:**
- Widgets/Live Activities must use same localized string keys as main app
- Shared localization resources must be available in extension targets
- If a string key is missing in selected locale, fallback to English and log a non-fatal localization event

**Content language pack storage (separate translation table pattern):**
```sql
-- Additive table — doesn't modify base ayahs/hadiths tables
CREATE TABLE ayah_translations (
    ayah_id TEXT NOT NULL,       -- FK to ayahs table (e.g. "1:1")
    language TEXT NOT NULL,       -- ISO 639-1 code (e.g. "ur", "id", "fr")
    text TEXT NOT NULL,
    PRIMARY KEY (ayah_id, language)
);

-- Same pattern for hadith and dua translations
CREATE TABLE hadith_translations (
    hadith_id TEXT NOT NULL,
    language TEXT NOT NULL,
    text TEXT NOT NULL,
    PRIMARY KEY (hadith_id, language)
);

CREATE TABLE dua_translations (
    dua_id TEXT NOT NULL,
    language TEXT NOT NULL,
    text TEXT NOT NULL,
    PRIMARY KEY (dua_id, language)
);
```
This keeps the base install small (~90MB Quran + Hadith) and adds ~4-8MB per language pack downloaded on-demand.

**Pluralization requirements:**
- Arabic (`ar`): 6 plural forms (zero, one, two, few, many, other) — String Catalog handles via `.stringsdict` rules
- Bengali (`bn`), Hindi (`hi`), Urdu (`ur`): 2 plural forms (one, other)
- Indonesian (`id`), Malay (`ms`), Turkish (`tr`), Persian (`fa`), Chinese Simplified (`zh-Hans`): no grammatical plural — use `other` form only
- All plural-sensitive strings (e.g. "X days", "X prayers") must use String Catalog plural variants, not manual `if count == 1` checks

**Observability (privacy-safe):**
- Track missing-key rate by locale and screen
- Track fallback usage rate for missing content translations
- Never log religious text bodies, prompts, or translated passage payloads

### 6.7.2 Performance Architecture (Cross-Cutting)

Performance is a design-level concern, not a launch-gate afterthought. Every feature must be built with these patterns from the start.

**Budgets (enforced by automated tests):**

| Metric | Target | Hard Limit | Test |
|--------|--------|------------|------|
| Cold launch to interactive | < 1s p50, < 2s p95 | 3s blocks release | `AppLaunchPerformanceTests` |
| Screen transition | < 200ms | 500ms | Manual + Instruments |
| SQLite query (single row) | < 10ms | 50ms | `DatabasePerformanceTests` |
| SQLite query (list) | < 20ms | 50ms | `DatabasePerformanceTests` |
| FTS search (100 results) | < 100ms | 500ms | `DatabasePerformanceTests` |
| Prayer time calculation | < 5ms | 20ms | `DatabasePerformanceTests` |
| Repeated query (cached conn) | < 5ms avg | 10ms | `DatabasePerformanceTests` |
| Memory baseline | < 200MB | 300MB | Instruments |

**Mandatory patterns:**

1. **Compressed bundled data**: Large databases ship gzipped, decompress async on first launch (see `SQLiteService.preWarmDatabases()`). Never block UI for decompression.

2. **Persistent database connections**: `SQLiteService` caches read-only connections per database. Never open/close per query.

3. **Skeleton loaders over spinners**: Every async data load shows a shimmer placeholder that mirrors the final layout, not a generic spinner. Users perceive the app as faster when the structure appears immediately.

4. **Precompute on launch**: Prayer times, Hijri date, and streak data are computed in `SafaApp.task{}` before the user navigates. Widget data is synced in the same pass.

5. **Lazy ViewModel initialization**: Heavy ViewModels (Prayer, Quran, Hadith) are created in `.task{}` modifiers, not in `init()`, so the tab bar renders instantly.

6. **Background-only for non-critical work**: Spotlight indexing, notification scheduling, and database decompression run in background tasks that never block the main actor.

7. **Cache aggressively**: Repository results (collections, surahs) are cached in memory after first load. UserDefaults reads use App Group for widget sharing.

**Performance test requirements:**
- Every database query method must have a timing assertion (< 1s for search, < 50ms for single-row fetch)
- App launch test must exist and be run before release
- New features must not regress existing performance tests

### 6.8 Spotlight Search (CoreSpotlight)

Index Quran, Hadith, and Duas for iOS Spotlight search.

```swift
// MARK: - SpotlightIndexService.swift

import CoreSpotlight
import MobileCoreServices

class SpotlightIndexService {
    private let searchableIndex = CSSearchableIndex.default()

    /// Index all searchable content on first launch
    func indexAllContent() async {
        await indexSurahs()
        await indexPopularAyahs()
        await indexDuas()
        await indexHadith()
    }

    /// Index Quran surahs
    func indexSurahs() async {
        var items: [CSSearchableItem] = []

        for surah in allSurahs {
            let attributes = CSSearchableItemAttributeSet(contentType: .text)
            attributes.title = "Surah \(surah.englishName)"
            attributes.contentDescription = "\(surah.arabicName) - \(surah.ayahCount) ayahs"
            attributes.keywords = [surah.englishName, surah.arabicName, "quran", "surah"]

            let item = CSSearchableItem(
                uniqueIdentifier: "surah-\(surah.number)",
                domainIdentifier: "com.safa.quran",
                attributeSet: attributes
            )
            items.append(item)
        }

        try? await searchableIndex.indexSearchableItems(items)
    }

    /// Index popular ayahs (Ayatul Kursi, etc.)
    func indexPopularAyahs() async {
        let popularAyahs = [
            (surah: 2, ayah: 255, name: "Ayatul Kursi"),
            (surah: 1, ayah: 1, name: "Al-Fatiha"),
            (surah: 112, ayah: 1, name: "Surah Al-Ikhlas"),
            // ... more popular ayahs
        ]

        var items: [CSSearchableItem] = []
        for ayah in popularAyahs {
            let attributes = CSSearchableItemAttributeSet(contentType: .text)
            attributes.title = ayah.name
            attributes.contentDescription = "Quran \(ayah.surah):\(ayah.ayah)"
            attributes.keywords = [ayah.name.lowercased(), "quran", "ayah"]

            let item = CSSearchableItem(
                uniqueIdentifier: "ayah-\(ayah.surah)-\(ayah.ayah)",
                domainIdentifier: "com.safa.quran",
                attributeSet: attributes
            )
            items.append(item)
        }

        try? await searchableIndex.indexSearchableItems(items)
    }

    /// Index duas by category
    func indexDuas() async {
        // Index all duas with titles and keywords
    }
}
```

**Deep link handling:**
```swift
// In AppDelegate or SceneDelegate
func application(_ application: UIApplication,
                 continue userActivity: NSUserActivity,
                 restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
    if userActivity.activityType == CSSearchableItemActionType,
       let identifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String {
        // Parse identifier and navigate
        // "surah-2" → open Surah Al-Baqarah
        // "ayah-2-255" → open Ayatul Kursi
        // "dua-eating" → open dua for eating
        router.handleSpotlightResult(identifier)
        return true
    }
    return false
}
```

### 6.9 Interactive Widgets (App Intents)

Widgets with tap actions using App Intents (iOS 17+).

```swift
// MARK: - LogPrayerIntent.swift

import AppIntents
import WidgetKit

struct LogPrayerIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Prayer"
    static var description = IntentDescription("Mark a prayer as completed")

    @Parameter(title: "Prayer")
    var prayer: PrayerType

    func perform() async throws -> some IntentResult {
        // Log the prayer
        let repository = PrayerRepository.shared
        try await repository.logPrayer(prayer, at: Date())

        // Reload widget timeline
        WidgetCenter.shared.reloadTimelines(ofKind: "PrayerWidget")

        return .result()
    }
}

// MARK: - Interactive Prayer Widget

struct InteractivePrayerWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "InteractivePrayerWidget", provider: PrayerTimelineProvider()) { entry in
            InteractivePrayerWidgetView(entry: entry)
        }
        .configurationDisplayName("Prayer Times")
        .description("Log prayers with a tap")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct InteractivePrayerWidgetView: View {
    var entry: PrayerEntry

    var body: some View {
        HStack {
            ForEach(entry.prayers) { prayer in
                Button(intent: LogPrayerIntent(prayer: prayer.type)) {
                    VStack {
                        Text(prayer.name)
                            .font(.caption)
                        Image(systemName: prayer.isLogged ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(prayer.isLogged ? .green : .secondary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}
```

```swift
// MARK: - TasbeehIntent.swift

struct IncrementTasbeehIntent: AppIntent {
    static var title: LocalizedStringResource = "Increment Tasbeeh"

    func perform() async throws -> some IntentResult {
        // Increment counter in shared UserDefaults
        let defaults = UserDefaults(suiteName: "group.com.safa.app")!
        let current = defaults.integer(forKey: "tasbeehCount")
        defaults.set(current + 1, forKey: "tasbeehCount")

        // Reload widget
        WidgetCenter.shared.reloadTimelines(ofKind: "TasbeehWidget")

        return .result()
    }
}
```

### 6.10 StandBy Mode

StandBy uses WidgetKit - configure widgets for the StandBy display.

```swift
// MARK: - StandBy Widget Configuration

struct PrayerStandByWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PrayerStandByWidget", provider: PrayerTimelineProvider()) { entry in
            PrayerStandByView(entry: entry)
        }
        .configurationDisplayName("Prayer Times")
        .description("See prayer times in StandBy mode")
        .supportedFamilies([.systemSmall, .systemMedium])
        // StandBy uses existing widget families
    }
}

struct PrayerStandByView: View {
    var entry: PrayerEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(spacing: 8) {
            // Next prayer - large and prominent
            Text(entry.nextPrayer.name.uppercased())
                .font(.system(size: family == .systemMedium ? 32 : 24, weight: .bold))

            Text(entry.nextPrayer.time, style: .time)
                .font(.system(size: family == .systemMedium ? 48 : 36, weight: .light, design: .rounded))

            Text("in \(entry.nextPrayer.timeUntil)")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Prayer status row
            if family == .systemMedium {
                HStack(spacing: 16) {
                    ForEach(entry.prayers) { prayer in
                        VStack {
                            Text(prayer.shortName)
                                .font(.caption2)
                            Image(systemName: prayer.isLogged ? "checkmark" : "circle")
                                .font(.caption)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}
```

**StandBy considerations:**
- High contrast for bedside visibility
- Large, readable time display
- Minimal information density
- Works in both light and dark environments

### 6.11 Apple Intelligence Integration (App Entities)

Beyond interactive widgets, expose app content to the iOS system intelligence layer.

```swift
// MARK: - App Entities for Siri & System Intelligence

struct PrayerEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Prayer")
    static var defaultQuery = PrayerQuery()

    var id: String
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name) at \(time)")
    }

    let name: String
    let time: String
}

// Enables: "When is the next prayer?" without opening the app
struct GetNextPrayerIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Next Prayer Time"
    static var description = IntentDescription("Returns the next prayer time")

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let prayer = await PrayerService.shared.getNextPrayer()
        return .result(value: "\(prayer.name) at \(prayer.time)")
    }
}

// Enables: "Play the adhan"
struct PlayAdhanIntent: AppIntent {
    static var title: LocalizedStringResource = "Play Adhan"
    func perform() async throws -> some IntentResult {
        await AudioPlayerService.shared.playSelectedAdhan()
        return .result()
    }
}
```

**Exposed Intents:**
- `GetNextPrayerTime` — "When is the next prayer?"
- `GetPrayersLoggedToday` — "How many prayers have I logged?"
- `LogPrayer` — "Log Dhuhr prayer"
- `PlayAdhan` — "Play the adhan"
- `OpenSurah` — "Open Surah Yasin"
- `StartTasbeeh` — "Start tasbeeh for SubhanAllah"

**Shortcut Automations:**
- "When I arrive at the mosque → log my prayer"
- "At Fajr time → play adhan + show prayer card"

### 6.12 Assistive Access Mode

Simplified UI for users with cognitive disabilities (iOS 17+).

```swift
// MARK: - Assistive Access Detection

struct AssistiveAccessAdapter {
    static var isAssistiveAccessEnabled: Bool {
        // Check for Assistive Access or Guided Access
        UIAccessibility.isGuidedAccessEnabled
    }

    static func adaptedTabCount() -> Int {
        isAssistiveAccessEnabled ? 3 : 5  // Prayer, Qibla, Dhikr only
    }
}
```

**Simplified Layout:**
- 3 tabs only: Prayer, Qibla, Dhikr
- Next prayer: massive font, high contrast, full-width card
- Qibla: full-screen directional arrow, no compass chrome
- Tasbeeh: single large tap target filling screen
- No gamification (streaks, hasanat) in this mode
- Voice feedback for prayer logging confirmation
- Compatible with Switch Control and Voice Control

---

## 7. Networking

### 7.1 External APIs

| API | Purpose | Fallback |
|-----|---------|----------|
| **Aladhan API** | Prayer times (backup) | Local calculation |
| **Quran.com API** | Audio recitations CDN | Bundled subset |
| **Custom CDN** | Additional audio, images | Bundled content |

### 7.2 Network Layer

```swift
protocol APIClient {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
}

class NetworkService: APIClient {
    private let session: URLSession

    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        // Build request
        // Execute with retry logic
        // Decode response
    }
}
```

---

## 8. Security & Privacy

### 8.1 Data Privacy

- **No user accounts required** for core functionality
- **Location data**: Used only for prayer times/Qibla, not transmitted
- **No analytics tracking** beyond basic App Store metrics
- **Family features**: Opt-in only, user controls visibility
- **On-device AI**: No data sent to external servers

### 8.2 Local Data Protection

```swift
// Sensitive data in Keychain
class KeychainService {
    func store(_ data: Data, for key: String) throws
    func retrieve(for key: String) throws -> Data?
}

// Core Data encryption (optional)
let storeDescription = NSPersistentStoreDescription()
storeDescription.setOption(
    FileProtectionType.complete as NSObject,
    forKey: NSPersistentStoreFileProtectionKey
)
```

### 8.3 Legal Pages (Static In-App)

Privacy Policy and Terms of Service are rendered as static in-app views, not web links:

```swift
struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            // Render bundled markdown content
            Text(LocalizedStringKey(privacyPolicyContent))
                .padding()
        }
        .navigationTitle("Privacy Policy")
    }

    private var privacyPolicyContent: String {
        // Load from bundled file or hardcoded string
        Bundle.main.loadMarkdownFile("PRIVACY_POLICY")
    }
}
```

**Benefits:**
- Works fully offline
- No external hosting dependency
- Consistent with privacy-first design
- Faster loading (no network)

**Implementation:**
- Bundle `PRIVACY_POLICY.md` and `TERMS_OF_SERVICE.md` in app resources
- Use `AttributedString` or simple Text rendering for markdown
- Accessible via Settings → Privacy Policy / Terms of Service

### 8.4 Invite Friends (App Store Link Sharing)

Organic growth through easy app sharing with native iOS Share Sheet.

```swift
// MARK: - AppConstants.swift

struct AppConstants {
    /// App Store URL - update with actual ID after app submission
    static let appStoreURL = URL(string: "https://apps.apple.com/app/safa/id[APP_ID]")!

    /// TestFlight URL for pre-release
    static let testFlightURL = URL(string: "https://testflight.apple.com/join/[CODE]")!

    /// Returns appropriate URL based on app distribution
    static var shareURL: URL {
        #if DEBUG
        return testFlightURL
        #else
        return appStoreURL
        #endif
    }
}
```

```swift
// MARK: - InviteFriendsService.swift

class InviteFriendsService {
    /// Share message template with App Store link
    var shareMessage: String {
        """
        Assalamu Alaikum! 🌙

        I've been using Safa - a beautiful Islamic companion app for prayer times, Quran, and learning. No ads, no clutter.

        Download free: \(AppConstants.shareURL.absoluteString)

        May it benefit you! 🤲
        """
    }

    /// Items to share via ShareLink
    var shareItems: [Any] {
        [shareMessage, AppConstants.shareURL]
    }
}
```

```swift
// MARK: - InviteFriendsView.swift

struct InviteFriendsView: View {
    @State private var isShareSheetPresented = false
    private let inviteService = InviteFriendsService()

    var body: some View {
        Button {
            isShareSheetPresented = true
        } label: {
            Label("Invite Friends", systemImage: "person.badge.plus")
        }
        .sheet(isPresented: $isShareSheetPresented) {
            ShareSheet(items: inviteService.shareItems)
        }
    }
}

// UIKit ShareSheet wrapper for full control
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
```

**Integration Points:**
- `FamilyCircleView`: Prominent "Invite Friends" button
- `SettingsView` → About: "Share Safa" row
- Achievement unlock: Include app link in share card
- `OnboardingView` Page 3: Optional "I was invited" toggle (honor system for Hasanat)

**Hasanat Award (Honor System):**
- No tracking of referrals (privacy-first)
- New users can tap "I was invited" in onboarding
- This triggers +25 Hasanat for the inviter (via honor system, not enforced)
- Simple, respectful approach that aligns with Islamic values of trust

### 8.5 Calendar Integration (EventKit + .ics Export)

Export Islamic events to device calendar or .ics file.

```swift
// MARK: - CalendarExportService.swift

import EventKit

class CalendarExportService {
    private let eventStore = EKEventStore()

    // MARK: - EventKit Integration

    /// Request calendar access
    func requestAccess() async -> Bool {
        do {
            return try await eventStore.requestFullAccessToEvents()
        } catch {
            return false
        }
    }

    /// Add Islamic events to Apple Calendar
    func exportToCalendar(
        events: [IslamicCalendarEvent],
        calendarName: String = "Safa - Islamic Events"
    ) async throws {
        // Create or find Safa calendar
        let calendar = findOrCreateCalendar(named: calendarName)

        for event in events {
            let ekEvent = EKEvent(eventStore: eventStore)
            ekEvent.title = event.title
            ekEvent.startDate = event.date
            ekEvent.endDate = event.endDate ?? event.date.addingTimeInterval(3600)
            ekEvent.notes = event.notes
            ekEvent.calendar = calendar

            // Add alarm for day before
            ekEvent.addAlarm(EKAlarm(relativeOffset: -86400))

            try eventStore.save(ekEvent, span: .thisEvent)
        }
    }

    // MARK: - .ics Export

    /// Generate .ics file content
    func generateICSFile(events: [IslamicCalendarEvent]) -> String {
        var ics = """
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//Safa//Islamic Calendar//EN
        CALSCALE:GREGORIAN
        METHOD:PUBLISH
        X-WR-CALNAME:Safa Islamic Events

        """

        for event in events {
            ics += """
            BEGIN:VEVENT
            UID:\(event.id)@safa.app
            DTSTART:\(formatDate(event.date))
            DTEND:\(formatDate(event.endDate ?? event.date.addingTimeInterval(3600)))
            SUMMARY:\(event.title)
            DESCRIPTION:\(event.notes ?? "")
            END:VEVENT

            """
        }

        ics += "END:VCALENDAR"
        return ics
    }

    /// Share .ics file
    func shareICSFile(events: [IslamicCalendarEvent]) -> URL {
        let icsContent = generateICSFile(events: events)
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("safa-islamic-calendar.ics")
        try? icsContent.write(to: tempURL, atomically: true, encoding: .utf8)
        return tempURL
    }
}
```

**Events to export:**
- Eid al-Fitr & Eid al-Adha (with prayer times)
- Ramadan start/end
- Islamic New Year (1st Muharram)
- Ashura (10th Muharram)
- Mawlid an-Nabi (12th Rabi al-Awwal)
- Isra wal Mi'raj (27th Rajab)
- Laylatul Qadr (estimated odd nights)
- Day of Arafah

### 8.6 Apple Health Integration (Fasting)

Track Ramadan fasting hours in Apple Health.

```swift
// MARK: - HealthKitService.swift

import HealthKit

class HealthKitService {
    private let healthStore = HKHealthStore()

    /// Check if HealthKit is available
    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    /// Request authorization to write fasting data
    func requestFastingAuthorization() async -> Bool {
        guard isAvailable else { return false }

        let fastingType = HKCategoryType(.intermittentFasting)
        let typesToWrite: Set<HKSampleType> = [fastingType]

        do {
            try await healthStore.requestAuthorization(toShare: typesToWrite, read: [])
            return true
        } catch {
            return false
        }
    }

    /// Log a completed fast to Health
    func logFast(start: Date, end: Date) async throws {
        let fastingType = HKCategoryType(.intermittentFasting)

        let sample = HKCategorySample(
            type: fastingType,
            value: HKCategoryValue.notApplicable.rawValue,
            start: start,
            end: end
        )

        try await healthStore.save(sample)
    }
}
```

**User flow:**
1. User logs first Ramadan fast in Safa
2. Prompt: "Sync fasting to Apple Health?"
3. If accepted, request HealthKit permission
4. Each logged fast writes to Health automatically
5. Toggle in Settings → Ramadan → Sync to Health

**Privacy notes:**
- Write-only (never reads other Health data)
- Opt-in (not enabled by default)
- Can be disabled anytime in Settings

---

## 8.8 Graceful Degradation & Resilience

**Principle:** Never crash on external failure. Never silently fail. Inform the user and offer alternatives.

### 8.8.0 DegradedStateBanner Component

Shared reusable component for all inline degraded state indicators.

```swift
struct DegradedStateBanner: View {
    let icon: String          // SF Symbol name
    let message: String       // User-facing description
    let actionLabel: String?  // Optional action ("Open Settings", "Retry")
    let action: (() -> Void)? // Action callback
    let color: Color          // .orange for warning, .red for error

    var body: some View {
        HStack(spacing: SafaSpacing.xs) {
            Image(systemName: icon).font(.caption2)
            Text(message).font(SafaTypography.labelSmall)
            Spacer()
            if let actionLabel {
                Button(actionLabel) { action?() }
                    .font(SafaTypography.labelSmall)
            }
        }
        .foregroundColor(color)
        .padding(.horizontal, SafaSpacing.md)
        .padding(.vertical, SafaSpacing.xs)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.sm))
    }
}
```

**Standard variants:**
| State | Icon | Message | Action |
|-------|------|---------|--------|
| Location fallback | `location.slash` | "Using London, UK" | "Update" |
| Offline | `wifi.slash` | "Offline — changes saved locally" | nil |
| Compass accuracy | `exclamationmark.circle` | "Low compass accuracy" | "Calibrate" |
| Sync paused | `icloud.slash` | "Sync paused" | nil |
| Storage low | `externaldrive.badge.exclamationmark` | "Storage low" | "Manage" |

**Placement:** Inline above main content, never blocking. Subtle, not alarming.

### 8.8.1 Core Data Store Failure

**Current risk:** `fatalError()` on persistent store load failure — app crashes.

**Required fix:**
```swift
// BEFORE (crashes):
container.loadPersistentStores { _, error in
    if let error { fatalError("Core Data: \(error)") }
}

// AFTER (degrades):
container.loadPersistentStores { description, error in
    if let error {
        // Log error, fall back to in-memory store
        let inMemory = NSPersistentStoreDescription()
        inMemory.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [inMemory]
        container.loadPersistentStores { _, _ in }
        self.isDegradedMode = true
        // Show user: "Data may not persist. Restart the app or check storage."
    }
}
```

### 8.8.2 Notification Scheduling Failure

**Current risk:** `try?` silently swallows scheduling failures — user misses prayer alerts.

**Required fix:**
```swift
// Replace try? with proper error handling
do {
    try await UNUserNotificationCenter.current().add(request)
} catch {
    // Notify the ViewModel that scheduling failed
    await MainActor.run {
        self.notificationSchedulingFailed = true
    }
    // User sees: bell icon changes to warning state
}
```

**User-facing indicators:**
- Bell icon: `bell.badge.xmark` (orange) when scheduling failed
- Toast: "Prayer notification could not be set. Check notification permissions."
- Settings link to iOS notification settings

### 8.8.3 Compass Accuracy & Calibration

**Current risk:** No accuracy check — Qibla could point wrong direction silently.

**Required fix:**
```swift
func locationManager(_ manager: CLLocationManager, didUpdateHeading heading: CLHeading) {
    if heading.headingAccuracy < 0 {
        // Heading unreliable — show calibration prompt
        compassAccuracy = .unreliable
    } else if heading.headingAccuracy > 25 {
        // Low accuracy — show warning
        compassAccuracy = .low
    } else {
        compassAccuracy = .good
    }
    currentHeading = heading.magneticHeading
}
```

**User-facing indicators:**
- `.unreliable`: "Move your device in a figure-8 to calibrate"
- `.low`: Yellow accuracy indicator, Qibla still shown but with caveat
- `.good`: Normal green compass operation

### 8.8.4 Network & Sync Resilience

**Required patterns:**
```swift
// Exponential backoff for retries
func withRetry<T>(maxAttempts: Int = 3, _ operation: () async throws -> T) async throws -> T {
    var delay: TimeInterval = 1
    for attempt in 1...maxAttempts {
        do {
            return try await operation()
        } catch where attempt < maxAttempts {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            delay *= 2
        }
    }
    return try await operation() // Final attempt throws
}
```

**WiFi check fix:**
```swift
// Replace hardcoded true with real check
var isOnWiFi: Bool {
    guard let path = NWPathMonitor().currentPath else { return false }
    return path.usesInterfaceType(.wifi)
}
```

### 8.8.5 Audio Playback Failure

**Required fix:**
- Show toast on playback failure: "Could not play adhan. Check audio settings."
- Fall back to system notification sound if custom adhan file not found
- Resume downloads from where they left off (URLSession `downloadTask` with resume data)

### 8.8.6 Location Permission Denied

**Required fix:**
- Show inline banner: "Location unavailable — using London, UK"
- Settings deep-link button: "Update location in Settings"
- Manual location entry as fallback (city picker)

### 8.8.7 Degradation State Summary

| Component | Degraded State | User Indicator | Fallback |
|-----------|---------------|----------------|----------|
| Core Data | In-memory store | "Data may not persist" banner | All features work, no persistence |
| Location | Default coordinates | "Using London, UK" note | Manual city selection |
| Compass | No heading | "Calibrate device" prompt | Show bearing number only |
| Notifications | Scheduling failed | Orange bell icon + toast | Manual prayer checking |
| Network | Offline | Sync status indicator | Offline queue, all features work |
| Audio | Playback failed | Toast with error | System default sound |
| CloudKit | Quota exceeded | "Sync paused" indicator | Local-only mode |

---

## 9. Performance Considerations

### 9.1 App Size Budget

**Target: <100MB initial download** (aggressive optimization)

| Component | Target Size | Optimization |
|-----------|-------------|--------------|
| App binary | ~15 MB | Dead code stripping |
| Quran data | ~5 MB | Compressed SQLite (zstd) |
| Hadith collections | ~15 MB | Compressed SQLite (zstd) |
| Dua/Dhikr data | ~1 MB | JSON |
| UI assets | ~10 MB | Asset catalog optimization |
| LLM model | **0 MB** | Uses Apple Foundation Models (ships with iOS) |
| **Initial Download** | **<80 MB** | Target for App Store |
| **Audio (on-demand)** | ~2-5 GB | Downloaded per-surah as needed |

**Size Optimization Techniques:**
- **App Thinning**: Automatic device-specific asset delivery (~30% savings)
- **On-Demand Resources**: Audio as ODR, not in bundle
- **SQLite compression**: zstd/lz4 compression (~60% savings)
- **Asset catalogs**: Let Xcode optimize images
- **Swift package trimming**: Minimal dependencies
- **Dead code stripping**: Aggressive linker settings

**Decision**: Small app size is critical for downloads. Apple Foundation Models eliminate the biggest size concern (LLM). Audio downloads on-demand, not bundled.

### 9.2 Performance Budgets

| Metric | Target | Gate |
|--------|--------|------|
| App launch (cold) | p50 < 1s, p95 < 2s | Block release if p95 > 3s |
| Interaction latency | p95 < 200ms | Block release if p95 > 500ms |
| Memory baseline | < 200MB | Block release if > 300MB |
| Crash-free sessions | > 99.5% | Block release if < 99% |

### 9.3 Memory Management

- Lazy load Quran/Hadith pages
- Stream audio rather than load fully into memory
- LLM inference with memory mapping
- Aggressive image caching limits

### 9.3 Battery Optimization

- Batch location updates
- Efficient background refresh scheduling
- Avoid continuous compass updates (only when Qibla screen active)
- Audio session management

---

## 9.5 Dark Mode Token Architecture

Semantic color tokens with strict light/dark parity:

```swift
// Semantic tokens — use these, not raw colors
extension Color {
    static var sfBackground: Color { Color("Background") }        // Light: white, Dark: #1C1C1E
    static var sfCardBackground: Color { Color("CardBackground") } // Light: systemGray6, Dark: #2C2C2E
    static var sfPrimaryText: Color { Color("PrimaryText") }       // Light: #000000, Dark: #F2F2F7
    static var sfSecondaryText: Color { Color("SecondaryText") }   // Light: #8E8E93, Dark: #98989D
}
```

**Rules:**
- No hardcoded `Color.white` or `Color.black` in views — use semantic tokens
- Quran reading surface: extra-low glare dark background, never pure black
- Cards use subtle shadow/elevation differences, not just borders
- All new components must be verified in both themes before merge

---

## 9.6 Observability Architecture

**Philosophy:** Measure quality with metrics, not opinions. Respect user privacy absolutely.

### Event Schema

```swift
struct AnalyticsEvent {
    let name: String          // e.g., "prayer_logged", "quran_resumed"
    let flow: String          // e.g., "prayer", "quran", "onboarding"
    let context: [String: String] // e.g., ["prayer": "fajr", "source": "widget"]
    let result: String        // "success", "failure", "fallback"
    let durationMs: Int?      // Optional timing
}
```

### Event Categories

| Category | Examples | Purpose |
|----------|---------|---------|
| Product | onboarding_completed, prayer_logged, quran_resumed | Engagement funnels |
| Technical | app_launch, sync_completed, notification_scheduled | Health monitoring |
| Degraded | location_fallback, compass_unreliable, offline_mode | Reliability tracking |

### Privacy Rules
- **Never log:** User religious content, private notes, AI chat prompts/responses, prayer quality ratings
- **Log only:** Event metadata (action type, timing, outcome, state)
- **Minimise** retention window and aggregate early
- **Respect** user privacy settings and regional compliance

### Release Quality Gates
- Crash-free sessions > 99.5% → else block release
- Launch p95 < 3s → else block release
- Zero critical degraded-state regressions → else investigate

---

## 10. Testing Strategy

### 10.1 Testing Layers

| Layer | Framework | Coverage Target |
|-------|-----------|-----------------|
| Unit Tests | XCTest | Domain layer: 90%+ |
| Integration Tests | XCTest | Repositories: 80%+ |
| UI Tests | XCUITest | Critical flows: 70%+ |
| Snapshot Tests | swift-snapshot-testing | UI components |

### 10.2 Key Test Scenarios

- Prayer time calculation accuracy
- Qibla direction calculation
- Streak calculation edge cases
- Hijri date conversion
- LLM response quality (manual evaluation)
- Widget timeline generation
- Background task execution

---

## 11. Third-Party Dependencies

### 11.1 Proposed Dependencies

| Dependency | Purpose | Alternative |
|------------|---------|-------------|
| **Adhan** (swift) | Prayer time calculation | Custom implementation |
| **swift-markdown** | Rendering AI responses | AttributedString |
| **Nuke** | Image loading/caching | Native URLSession |
| **swift-collections** | Data structures | Foundation |

**Philosophy**: Minimize dependencies, prefer native solutions.

---

## 12. Resolved Decisions

| Decision | Resolution |
|----------|------------|
| App size | **<100MB target** - aggressive optimization, Apple FM eliminates LLM bundle |
| Offline capabilities | Comprehensive - all core features work offline |
| Audio strategy | **On-demand download** with predictive background fetch |
| CloudKit sync | Included in v1 |
| iPad support | iPhone only for v1 |
| Content sources | **Zero-cost**: Tanzil.net, Sahih Intl, Sunnah.com, Everyayah.com |
| LLM model | **Apple Foundation Models** (iOS 18.4+) with RAG |
| LLM fallback | Feature disabled on older iOS (no bundled model) |
| Knowledge grounding | **RAG** - retrieve from local Quran/Hadith DB, inject into context |
| Authentication | **None** - frictionless, iCloud handles sync |
| Disabled features | **Greyed out** with "Coming soon" message |
| Localization strategy | **Scoped multilingual UI** with staged content language packs |
| Invite friends | **App Store link via Share Sheet** - privacy-first, honor system |
| Calendar integration | **EventKit + .ics export** - native + universal compatibility |
| Health integration | **HealthKit** - Ramadan fasting hours (write-only, opt-in) |
| Spotlight Search | **CoreSpotlight** - index Quran, Hadith, Duas for iOS search |
| Interactive Widgets | **App Intents** - tap to log prayer or increment tasbeeh |
| StandBy Mode | **WidgetKit** - prayer times visible when charging |
| Future integrations | Planned for v1.1+ based on user feedback |
| Predictive downloads | **Background fetch** of next surah/juz based on reading patterns |
| watchOS companion | **v2** - haptic adhan, Digital Crown tasbeeh, complications |
| Apple Intelligence | **App Entities** for Prayer, Surah, Hadith + contextual Siri |
| Assistive Access | **Simplified 3-tab UI** auto-detected, large fonts, no gamification |
| Data sovereignty | **JSON/CSV export** of all user data + manual backup/restore |

## 13. Open Questions

1. **CDN provider**: Where to host audio files for download? (Consider Everyayah.com direct links)
2. **Beta distribution**: TestFlight strategy and beta tester recruitment?
3. **App Store category**: Which primary category? (Lifestyle, Education, Reference?)

---

## 14. Development Phases

| Phase | Focus | Key Deliverables |
|-------|-------|------------------|
| **1** | Core Infrastructure | Project setup, architecture, Core Data, prayer calculation |
| **2** | Prayer Features | Prayer times UI, Qibla compass, notifications, prayer logging |
| **3** | Quran | Quran reader, bookmarks, search, audio playback |
| **4** | Gamification | Hasanat system, streaks, achievements, progress tracking |
| **5** | Learning | Arabic lessons, Tajweed, pronunciation checker, spaced repetition |
| **6** | AI Companion | LLM integration, chat UI, system prompt tuning |
| **7** | Platform Features | Widgets, Live Activities, Focus Mode, Siri Shortcuts |
| **8** | Social Features | Family circle, sharing, CloudKit sync |
| **9** | Content & Polish | Hadith, Duas, Calendar, Wind-down mode, UI polish |
| **10** | Launch Prep | Testing, beta, App Store submission |
| **11** | v2: watchOS | Watch companion, complications, haptic adhan, Digital Crown tasbeeh |
| **12** | v2: Intelligence | App Entities, Siri context, Shortcut automations, Assistive Access |

---

## 15. watchOS Companion (v2)

### 15.1 Architecture

```
┌──────────────┐    WatchConnectivity    ┌──────────────┐
│   iPhone     │ ◄────────────────────► │  Apple Watch │
│   Safa App   │    (bidirectional)      │  Safa Watch  │
│              │                         │              │
│  UserDefaults│ ◄── App Group ────────► │  Shared Data │
│  (suite)     │                         │              │
└──────────────┘                         └──────────────┘
```

- **Target**: watchOS 10+ (SwiftUI native)
- **Sync**: `WCSession` for real-time + shared App Group `UserDefaults` for offline
- **Standalone**: Works without iPhone using cached prayer times + local compass

### 15.2 Watch Features

| Feature | Implementation | Notes |
|---------|---------------|-------|
| Next prayer complication | `WidgetKit` timeline | Corner, Circular, Rectangular |
| Haptic adhan | `WKInterfaceDevice.default().play(.notification)` | Distinct patterns per prayer |
| Tasbeeh counter | Digital Crown via `digitalCrownRotation` | `.rotationSensitivity(.medium)` |
| Qibla direction | `CLLocationManager` heading on watch | Standalone compass |
| Prayer logging | Tap complication → log intent | Syncs back to iPhone |

### 15.3 Haptic Patterns

```swift
// Fajr: strong triple-tap (wake up)
WKInterfaceDevice.default().play(.directionUp)
WKInterfaceDevice.default().play(.directionUp)
WKInterfaceDevice.default().play(.directionUp)

// Regular prayers: light double-tap
WKInterfaceDevice.default().play(.click)
WKInterfaceDevice.default().play(.click)
```

---

## 16. Data Sovereignty (v2)

### 16.1 Export Format

```json
{
  "schema_version": "1.0",
  "exported_at": "2026-02-06T12:00:00Z",
  "app_version": "1.0.0",
  "data": {
    "prayer_logs": [...],
    "streaks": [...],
    "bookmarks": [...],
    "reading_progress": {...},
    "achievements": [...],
    "preferences": {...}
  }
}
```

### 16.2 Implementation

```swift
struct DataExportService {
    func exportJSON() async throws -> Data  // Full export
    func exportCSV() async throws -> Data   // Prayer logs tabular
    func importJSON(_ data: Data) async throws  // Restore from backup
}
```

- **JSON Export**: All user data with ISO 8601 dates, UTF-8 encoded
- **CSV Export**: Prayer logs as tabular data (date, prayer, time, on_time)
- **"View All My Data" Screen**: Shows category counts and storage sizes
- **Per-category deletion**: Delete chat history without losing prayer logs

---

*Document Version: 1.0*
*Last Updated: February 8, 2026*
*Status: Pre-Production*
