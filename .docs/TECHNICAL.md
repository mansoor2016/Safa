# Safa - Technical Requirements Document

## Version 0.1 (Draft)

---

## 1. Platform & Technology Stack

### 1.1 Target Platform
- **Platform**: iOS only (iPhone)
- **Minimum iOS Version**: iOS 17.0 (for Live Activities, latest SwiftUI features)
- **Devices**: iPhone (no iPad optimization initially)

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
| **AVFoundation** | Audio playback (Quran recitation, adhkar) |
| **Speech** | Speech recognition for pronunciation |
| **CoreML** | On-device LLM inference |
| **CoreData** | Local persistence |
| **UserNotifications** | Prayer reminders, alerts |
| **BackgroundTasks** | Background refresh for prayer times |
| **StoreKit 2** | Donations/tips |
| **CloudKit** | Cross-device sync |
| **FamilyControls** | Family sharing features |
| **AppIntents** | Siri Shortcuts |

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
│   └── Services/
│       └── LocationInferenceService.swift  # Location-based settings inference
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
│   │   │   ├── AdhkarListView.swift
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
│   │       └── SleepAdhkarChecklist.swift
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
│   ├── Styles/
│   │   ├── Colors.swift              # Color palette
│   │   ├── Typography.swift          # Font styles
│   │   ├── Spacing.swift             # Layout constants
│   │   └── Theme.swift               # Theme manager
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
        self.locationService = LocationService()
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
| Dua & Adhkar | Bundled JSON → Core Data | Static content |
| Audio files (recitations) | Async download over WiFi + FileManager | Large files, cached |
| LLM model | Bundled in app | Required for offline |

### 3.2 Offline-First Strategy

The app is designed for comprehensive offline functionality. Modern device storage makes bundling content practical.

**Bundled at Install (Immediate Access):**
- Full Quran text (Arabic + English translation)
- All Hadith collections
- All Duas and Adhkar
- Prayer calculation algorithms
- LLM model for AI companion

**Downloaded Asynchronously (WiFi-Only):**
- Audio recitations (Quran + Duas)
- Additional translations (when localization added)

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

**Dua & Adhkar** (bundled JSON):
- Morning/evening adhkar (complete sets)
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

### 5.1 Model Selection

**Candidates** (need to evaluate):

| Model | Size | Pros | Cons |
|-------|------|------|------|
| **Phi-3 Mini (Q4)** | ~2GB | Good quality, Microsoft backing | Larger size |
| **Gemma 2B (Q4)** | ~1.5GB | Google backing, good performance | |
| **TinyLlama 1.1B** | ~600MB | Small, fast | Lower quality |
| **Llama 3.2 1B** | ~700MB | Meta, recent | Licensing check |
| **Apple Intelligence** | System | Native, optimized | iOS 18.1+, limited control |

**[QUESTION]: What's the acceptable app size? 2GB+ for better model, or <1GB for faster downloads?**

### 5.2 Core ML Integration

```swift
// Model loading
class LLMService {
    private var model: MLModel?

    func loadModel() async throws {
        let config = MLModelConfiguration()
        config.computeUnits = .cpuAndNeuralEngine
        model = try await SafaLLM.load(configuration: config)
    }

    func generateResponse(prompt: String, systemPrompt: String) async -> String {
        // Tokenize, inference, decode
    }
}
```

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

### 6.1 Widgets (WidgetKit)

```swift
// Widget families to support
struct SafaWidgets: WidgetBundle {
    var body: some Widget {
        PrayerTimeWidget()      // Small, Medium
        StreakWidget()          // Small
        DailyVerseWidget()      // Medium
        DashboardWidget()       // Large
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

---

## 9. Performance Considerations

### 9.1 App Size Budget

| Component | Estimated Size | Notes |
|-----------|----------------|-------|
| App binary | ~20 MB | |
| Quran data (Arabic + English) | ~50 MB | Bundled |
| Hadith collections | ~100 MB | Bundled |
| Dua/Adhkar data | ~5 MB | Bundled |
| LLM model | ~500MB - 2GB | Bundled (size TBD) |
| UI assets | ~10 MB | |
| **Initial Download** | **~700 MB - 2.2 GB** | Acceptable given modern storage |
| **Audio (async download)** | ~2-5 GB | Downloaded over WiFi |

**Decision**: App size is acceptable. Modern devices have ample storage, and comprehensive offline support is a feature, not a drawback.

### 9.2 Memory Management

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
| App size | Acceptable (700MB-2GB) - modern storage is ample |
| Offline capabilities | Comprehensive - all core features work offline |
| Audio downloads | Async over WiFi only |
| CloudKit sync | Included in v1 |
| iPad support | iPhone only for v1 |
| Content licensing | Assume available (translations, hadith, audio) |

## 13. Open Questions

1. **LLM model selection**: Which model? (Phi-3, Gemma, TinyLlama, etc.) - Deferred
2. **LLM fine-tuning**: Fine-tune on Islamic Q&A dataset vs extensive system prompt only?
3. **CDN provider**: Where to host audio files for download?
4. **Beta distribution**: TestFlight strategy and beta tester recruitment?
5. **App Store category**: Which primary category? (Lifestyle, Education, Reference?)

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

---

*Document Version: 1.0*
*Last Updated: February 2026*
*Status: Final*
