# Safa - Development Task Breakdown

## Overview

This document tracks all development tasks for the Safa iOS app. Each phase includes:
- **Implementation tasks** - Code to write
- **Acceptance criteria** - How we verify it works correctly
- **Integration tests** - User flow verification
- **Milestone demo** - End-of-phase validation checkpoint

**Legend:**
- `[ ]` Not started
- `[x]` Completed
- `[~]` In progress
- `[!]` Blocked

**Verification Commands:**
```bash
# Build project
xcodebuild -scheme Safa -destination 'platform=iOS Simulator,name=iPhone 15' build

# Run all tests
xcodebuild -scheme Safa -destination 'platform=iOS Simulator,name=iPhone 15' test

# Run specific test class
xcodebuild -scheme Safa -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:SafaTests/{TestClassName} test

# Launch app in simulator
xcrun simctl boot "iPhone 15" && xcrun simctl launch booted com.safa.app
```

---

## Phase 0: Project Foundation

### 0.1 Repository & Git Setup
- [x] Initialize Xcode project with SwiftUI App template
- [x] Configure `.gitignore` for iOS/Xcode project
- [ ] Set up branch protection rules (main branch)
- [x] Create initial commit with project structure
- [x] Configure Git LFS for large files (audio, ML models)

### 0.2 Agent Guidance Documentation
- [x] Create `AGENT.md` with development conventions
- [x] Create `CLAUDE.md` with project-specific instructions
- [x] Document file naming conventions
- [x] Document code patterns (ViewModel, View, Repository)
- [x] Document testing conventions
- [x] Add example implementations for reference

### 0.3 Xcode Project Configuration
- [x] Set deployment target (iOS 17.0)
- [x] Configure App Group (`group.com.safa.app`)
- [ ] Create Widget extension target (`SafaWidgets`) - Add via Xcode: File > New > Target
- [ ] Create Intents extension target (`SafaIntents`) - Add via Xcode: File > New > Target
- [x] Configure build schemes (Debug, Release)
- [x] Set up bundle identifiers
- [x] Configure signing & capabilities

### 0.4 Core Directory Structure
- [x] Create `App/` directory with entry point files
- [x] Create `Core/` directory structure
- [x] Create `Domain/` directory structure
- [x] Create `Data/` directory structure
- [x] Create `Features/` directory with all feature folders
- [x] Create `Shared/` directory structure
- [x] Create `Resources/` directory structure

### Phase 0 Acceptance Criteria
- [ ] **AC-0.1**: Project builds successfully with zero warnings
- [ ] **AC-0.2**: App launches in simulator showing blank SwiftUI view
- [ ] **AC-0.3**: All folder structure matches `TECHNICAL.md` specification
- [ ] **AC-0.4**: Widget extension target builds independently
- [ ] **AC-0.5**: Git commit history is clean with meaningful messages

### Phase 0 Verification
```bash
# Verify build succeeds
xcodebuild -scheme Safa build

# Verify app launches
xcrun simctl launch booted com.safa.app

# Verify folder structure
find Safa -type d -name "*.swift" | head -20
```

### 🎯 Milestone 0: Project Skeleton
**Demo Checklist:**
- [ ] Fresh clone builds without errors
- [ ] App launches to empty screen in simulator
- [ ] Widget extension compiles
- [ ] All directories created per technical spec
- [ ] Documentation files in place

---

## Phase 1: Core Infrastructure

### 1.1 Dependencies Container
- [x] Create `Dependencies.swift` container class
- [x] Define all repository protocol stubs
- [x] Define all service protocol stubs
- [x] Implement SwiftUI Environment injection
- [x] Write unit tests for dependency resolution

### 1.2 App Router & Navigation
- [x] Create `AppRouter.swift` with NavigationPath
- [x] Define all `Destination` enum cases
- [x] Implement deep link URL parsing
- [x] Implement `handleDeepLink(_ url:)` method
- [x] Wire router to main app entry point
- [x] Write unit tests for deep link parsing

### 1.3 Core Data Stack
- [x] Create `Safa.xcdatamodeld` data model
- [x] Define `PrayerLogMO` managed object
- [x] Define `QuranProgressMO` managed object
- [x] Define `StreakMO` managed object
- [x] Define `UserStatsMO` managed object
- [x] Define `FamilyMemberMO` managed object
- [x] Create `CoreDataStack.swift` with container setup
- [x] Configure App Group shared store location
- [x] Configure CloudKit sync with `NSPersistentCloudKitContainer`
- [x] Write migration strategy for future schema changes
- [x] Write unit tests for Core Data CRUD operations

### 1.4 Domain Entities
- [x] Create `Prayer.swift` entity
- [x] Create `PrayerTime.swift` entity (in Prayer.swift)
- [x] Create `Surah.swift` entity (in Quran.swift)
- [x] Create `Ayah.swift` entity (in Quran.swift)
- [x] Create `Hadith.swift` entity
- [x] Create `Dua.swift` entity
- [x] Create `Streak.swift` entity (in Gamification.swift)
- [x] Create `Achievement.swift` entity (in Gamification.swift)
- [x] Create `UserStats.swift` entity (in Gamification.swift)
- [x] Create `Lesson.swift` entity (in Learning.swift)
- [x] Create `FamilyMember.swift` entity (in Family.swift)

### 1.5 Design System
- [x] Create `Colors.swift` with color palette
- [x] Create `Typography.swift` with font styles
- [x] Create `Spacing.swift` with layout constants
- [x] Create `Theme.swift` theme manager
- [x] Create `PrimaryButton.swift` component
- [x] Create `SecondaryButton.swift` component
- [x] Create `ContentCard.swift` component
- [x] Create `LoadingView.swift` component
- [x] Create `EmptyStateView.swift` component

### 1.6 Shared Utilities
- [x] Create `Date+Extensions.swift`
- [x] Create `String+Extensions.swift`
- [x] Create `View+Extensions.swift`
- [x] Create `HijriDateConverter.swift`
- [x] Create `AppConstants.swift`
- [x] Create `IslamicConstants.swift`

### 1.7 Location Intelligence
- [x] Create `AppDefaults.swift` - centralized app defaults
- [x] Create `LocationInferenceService.swift`
- [x] Implement country-to-calculation-method mapping (50+ countries)
- [x] Implement country-to-madhab mapping
- [x] Implement country-to-language mapping
- [x] Implement coordinate-based fallback when country unknown
- [x] Implement high latitude detection and warnings
- [x] Integrate with `OnboardingView.swift`
- [x] Integrate with `SettingsView.swift`
- [x] Add `UserPreferences.applyLocationDefaults(from:)` method

### Phase 1 Acceptance Criteria
- [ ] **AC-1.1**: Dependencies inject correctly into SwiftUI views via Environment
- [ ] **AC-1.2**: Deep link `safa://prayer` navigates to prayer destination
- [ ] **AC-1.3**: Core Data saves and retrieves a test entity across app restart
- [ ] **AC-1.4**: All domain entities have Codable conformance
- [ ] **AC-1.5**: Design system colors render correctly in light/dark mode
- [ ] **AC-1.6**: Hijri date converter matches Islamic calendar for 10 test dates

### Phase 1 Integration Tests
- [ ] **IT-1.1**: App launches → Dependencies available in first view
- [ ] **IT-1.2**: Navigate via deep link → Correct screen displays
- [ ] **IT-1.3**: Save entity → Kill app → Relaunch → Entity persists

### Phase 1 Verification
```bash
# Run all Phase 1 tests
xcodebuild test -only-testing:SafaTests/CoreTests
xcodebuild test -only-testing:SafaTests/DomainTests

# Verify Core Data persistence
# Manual: Save data, force quit, relaunch, verify data exists
```

### 🎯 Milestone 1: Core Infrastructure
**Demo Checklist:**
- [ ] App launches with dependency injection working
- [ ] Navigate between 3 placeholder screens
- [ ] Deep link opens correct screen
- [ ] Core Data saves and retrieves test data
- [ ] Design system components render correctly
- [ ] Hijri date displays correctly
- [ ] **Record 2-minute walkthrough video**

---

## Phase 2: Prayer Features

### 2.1 Prayer Time Calculation
- [x] Create `PrayerTimeCalculator.swift`
- [x] Implement ISNA calculation method
- [x] Implement MWL calculation method
- [x] Implement Egyptian calculation method
- [x] Implement Makkah calculation method
- [x] Implement Karachi calculation method
- [x] Create `Coordinates.swift` model (in Prayer.swift)
- [x] Create `CalculationMethod.swift` enum (in Prayer.swift)
- [x] Write unit tests for each calculation method

### 2.2 Qibla Calculation
- [x] Create `QiblaCalculator.swift` (in PrayerTimeCalculator.swift)
- [x] Implement great circle bearing calculation
- [x] Write unit tests with known coordinates

### 2.3 Location Service
- [x] Create `LocationService.swift`
- [x] Implement location permission request
- [x] Implement current location fetch
- [x] Handle location errors gracefully
- [x] Cache last known location
- [x] Write unit tests with mock location

### 2.4 Prayer Repository
- [x] Create `PrayerRepositoryProtocol.swift`
- [x] Create `PrayerRepository.swift` implementation
- [x] Implement `getPrayers(for:location:)` method
- [x] Implement `logPrayer(_:at:)` method
- [x] Implement `getPrayerLogs(from:to:)` method
- [x] Write unit tests with mock data

### 2.5 Prayer UI
- [x] Create `PrayerView.swift` (feature entry)
- [x] Create `PrayerViewModel.swift`
- [x] Create `PrayerTimesListView.swift` (in PrayerView.swift)
- [x] Create `PrayerTimeRow.swift` component (in PrayerView.swift)
- [x] Create `QiblaCompassView.swift`
- [x] Create `CompassNeedle.swift` component (in QiblaCompassView.swift)
- [x] Create `PrayerLogView.swift`
- [x] Implement prayer time countdown logic
- [x] Add haptic feedback for interactions

### 2.6 Prayer Notifications
- [x] Create `NotificationService.swift`
- [x] Implement notification permission request
- [x] Schedule prayer time notifications
- [x] Implement configurable notification timing
- [x] Handle notification tap to open app
- [x] Write unit tests for notification scheduling

### Phase 2 Acceptance Criteria
- [ ] **AC-2.1**: Prayer times for New York match IslamicFinder.org within ±1 minute
- [ ] **AC-2.2**: Prayer times for London match IslamicFinder.org within ±1 minute
- [ ] **AC-2.3**: Prayer times for Makkah match IslamicFinder.org within ±1 minute
- [ ] **AC-2.4**: Prayer times for Karachi match IslamicFinder.org within ±1 minute
- [ ] **AC-2.5**: Prayer times for Sydney match IslamicFinder.org within ±1 minute
- [ ] **AC-2.6**: Qibla direction for New York matches Google Qibla within ±2°
- [ ] **AC-2.7**: Qibla direction for Tokyo matches Google Qibla within ±2°
- [ ] **AC-2.8**: Countdown timer updates every second without UI lag
- [ ] **AC-2.9**: Prayer notification fires within 5 seconds of scheduled time
- [ ] **AC-2.10**: Logged prayer persists after app restart

### Phase 2 Integration Tests
- [ ] **IT-2.1**: Grant location → Prayer times display for current location
- [ ] **IT-2.2**: Tap prayer row → Log prayer → Row shows checkmark
- [ ] **IT-2.3**: Open Qibla → Compass points in correct direction
- [ ] **IT-2.4**: Schedule notification → Background app → Notification fires
- [ ] **IT-2.5**: Log all 5 prayers → Daily completion indicator shows

### Phase 2 Verification
```bash
# Run prayer calculation tests
xcodebuild test -only-testing:SafaTests/PrayerTests

# Verify against external source
# Manual: Compare app times with islamicfinder.org for 5 cities

# Test notification timing
# Manual: Set notification for 1 min ahead, verify it fires
```

### 🎯 Milestone 2: Prayer Features Complete
**Demo Checklist:**
- [ ] App shows accurate prayer times for current location
- [ ] Change calculation method → times update correctly
- [ ] Countdown to next prayer updates in real-time
- [ ] Qibla compass points in correct direction
- [ ] Log a prayer → checkmark appears
- [ ] Notification fires at prayer time
- [ ] Prayer times match external source for 5 test cities
- [ ] **Record 3-minute demo video**

---

## Phase 3: Quran Reader

### 3.1 Quran Data
- [ ] Source and bundle `quran.sqlite` database
- [ ] Create database schema documentation
- [ ] Verify Arabic text encoding (UTF-8)
- [ ] Verify translation accuracy (spot check 10 ayahs)

### 3.2 Quran Repository
- [x] Create `QuranRepositoryProtocol.swift`
- [x] Create `QuranRepository.swift` implementation
- [ ] Implement `getAllSurahs()` method
- [ ] Implement `getAyahs(forSurah:)` method
- [ ] Implement `searchAyahs(query:)` method
- [ ] Implement `getBookmarks()` method
- [ ] Implement `addBookmark(_:)` method
- [ ] Implement `updateProgress(_:)` method
- [ ] Write unit tests

### 3.3 Quran UI
- [x] Create `QuranView.swift` (feature entry)
- [x] Create `QuranViewModel.swift`
- [x] Create `SurahListView.swift`
- [x] Create `SurahHeader.swift` component
- [x] Create `AyahReaderView.swift`
- [x] Create `AyahRow.swift` component
- [x] Implement Arabic text rendering with proper fonts
- [x] Implement translation toggle
- [x] Implement bookmarking
- [x] Implement reading progress tracking
- [x] Add search functionality

### 3.4 Audio Playback
- [x] Create `AudioPlayerService.swift`
- [x] Implement background audio session
- [x] Implement play/pause/seek controls
- [x] Implement ayah-by-ayah playback
- [x] Implement continuous surah playback
- [x] Create `AudioPlayerView.swift` UI
- [x] Implement download manager for audio files
- [x] Implement WiFi-only download setting

### Phase 3 Acceptance Criteria
- [ ] **AC-3.1**: All 114 surahs display with correct names (Arabic & English)
- [ ] **AC-3.2**: Surah Al-Fatiha displays exactly 7 ayahs
- [ ] **AC-3.3**: Surah Al-Baqarah displays exactly 286 ayahs
- [ ] **AC-3.4**: Arabic text renders with proper right-to-left formatting
- [ ] **AC-3.5**: Search "mercy" returns ayahs containing that word in translation
- [ ] **AC-3.6**: Bookmark persists after app restart
- [ ] **AC-3.7**: Audio plays correct ayah (verify first ayah of 3 surahs)
- [ ] **AC-3.8**: Audio continues in background when app minimized
- [ ] **AC-3.9**: Progress saves when leaving mid-surah and resuming
- [ ] **AC-3.10**: Audio downloads only on WiFi when setting enabled

### Phase 3 Integration Tests
- [ ] **IT-3.1**: Browse surahs → Select surah → Ayahs display correctly
- [ ] **IT-3.2**: Read ayah → Add bookmark → View bookmarks → Bookmark present
- [ ] **IT-3.3**: Play audio → Background app → Audio continues
- [ ] **IT-3.4**: Read to ayah 50 → Close app → Reopen → Resume at ayah 50
- [ ] **IT-3.5**: Search "Allah" → Results display → Tap result → Navigate to ayah

### Phase 3 Verification
```bash
# Run Quran tests
xcodebuild test -only-testing:SafaTests/QuranTests

# Verify ayah counts
# Manual: Spot check 5 surahs against quran.com for ayah count

# Verify audio sync
# Manual: Play Surah Al-Fatiha, verify each ayah highlights correctly
```

### 🎯 Milestone 3: Quran Reader Complete
**Demo Checklist:**
- [ ] Browse all 114 surahs
- [ ] Read Surah Al-Fatiha with Arabic + translation
- [ ] Arabic renders beautifully with proper font
- [ ] Search finds relevant ayahs
- [ ] Bookmark an ayah, find it in bookmarks
- [ ] Play audio for a surah
- [ ] Audio continues when app backgrounded
- [ ] Reading progress resumes correctly
- [ ] **Record 4-minute demo video**

---

## Phase 4: Gamification System

### 4.1 User State Manager
- [x] Create `UserStateManager.swift`
- [ ] Implement Hasanat tracking
- [ ] Implement level calculation
- [ ] Implement streak tracking (5 types)
- [ ] Implement achievement checking
- [ ] Make observable for UI updates

### 4.2 Hasanat Logic
- [x] Create `CalculateHasanatUseCase.swift`
- [x] Implement points for prayer logging
- [x] Implement points for Quran reading
- [x] Implement points for lesson completion
- [x] Implement points for dhikr
- [x] Implement Ramadan 2x multiplier
- [x] Write comprehensive unit tests

### 4.3 Streak Logic
- [x] Create `UpdateStreakUseCase.swift`
- [x] Implement daily streak calculation
- [x] Implement prayer streak calculation
- [x] Implement Quran streak calculation
- [x] Implement dhikr streak calculation
- [x] Implement learning streak calculation
- [x] Implement streak freeze logic
- [x] Handle timezone edge cases
- [x] Write comprehensive unit tests

### 4.4 Achievements
- [x] Create `CheckAchievementsUseCase.swift`
- [x] Define all achievement criteria (from DESIGN.md)
- [x] Implement achievement unlock logic
- [x] Implement achievement notification
- [ ] Create achievement badge assets

### 4.5 Progress UI
- [x] Create `ProgressDashboardView.swift`
- [x] Create `ProgressRing.swift` component
- [x] Create `StreakDisplay.swift` component
- [x] Create `AchievementBadge.swift` component
- [x] Create `LevelProgressBar.swift` component
- [x] Create `HasanatCounter.swift` component

### Phase 4 Acceptance Criteria
- [ ] **AC-4.1**: Logging prayer adds exactly 10 Hasanat
- [ ] **AC-4.2**: Reading 1 Quran page adds exactly 5 Hasanat
- [ ] **AC-4.3**: Completing lesson adds exactly 10 Hasanat
- [ ] **AC-4.4**: User reaches Level 2 at exactly 100 Hasanat
- [ ] **AC-4.5**: Daily streak increments after any qualifying activity
- [ ] **AC-4.6**: Streak resets to 0 after missing a day (without freeze)
- [ ] **AC-4.7**: Streak freeze prevents reset when used
- [ ] **AC-4.8**: "First Prayer" achievement unlocks on first prayer log
- [ ] **AC-4.9**: "Week Warrior" unlocks after 7-day prayer streak
- [ ] **AC-4.10**: Hasanat and streaks persist across app restart

### Phase 4 Integration Tests
- [ ] **IT-4.1**: Log prayer → Hasanat increases by 10 → Display updates
- [ ] **IT-4.2**: Read Quran page → Hasanat increases → Streak updates
- [ ] **IT-4.3**: Reach 100 Hasanat → Level changes to 2 → UI reflects
- [ ] **IT-4.4**: Activity 7 days in row → Streak shows 7 → Freeze earned
- [ ] **IT-4.5**: Miss day with freeze → Streak maintained → Freeze consumed
- [ ] **IT-4.6**: Unlock achievement → Notification shows → Badge in profile

### Phase 4 Verification
```bash
# Run gamification tests
xcodebuild test -only-testing:SafaTests/GamificationTests

# Test streak edge cases
xcodebuild test -only-testing:SafaTests/StreakTests

# Verify Hasanat calculations
# Manual: Perform known actions, verify exact point totals
```

### 🎯 Milestone 4: Gamification Complete
**Demo Checklist:**
- [ ] Start fresh → 0 Hasanat, Level 1, no streaks
- [ ] Log prayer → See Hasanat increase by 10
- [ ] Read Quran → See Hasanat increase by 5
- [ ] Reach Level 2 at 100 Hasanat
- [ ] View progress dashboard with all stats
- [ ] Unlock "First Prayer" achievement
- [ ] Streaks display and increment correctly
- [ ] All data persists after restart
- [ ] **Record 3-minute demo video**

---

## Phase 5: Learning Features

### 5.1 Learning Data
- [x] Create lesson content structure (JSON schema)
- [x] Create Arabic alphabet lessons (28 letters)
- [x] Create Tajweed rule lessons (basic rules)
- [ ] Create pronunciation audio files
- [x] Bundle learning content in app

### 5.2 Learning Repository
- [x] Create `LearningRepositoryProtocol.swift`
- [x] Create `LearningRepository.swift`
- [x] Implement `getTracks()` method
- [x] Implement `getLessons(forTrack:)` method
- [x] Implement `markLessonComplete(_:)` method
- [x] Implement `getLessonProgress()` method
- [x] Write unit tests

### 5.3 Pronunciation Checker
- [x] Create `PronunciationService.swift`
- [x] Implement Speech framework integration
- [x] Implement Arabic speech recognition
- [x] Implement pronunciation scoring algorithm
- [x] Handle microphone permissions
- [ ] Write unit tests with sample audio

### 5.4 Learning UI
- [x] Create `LearnView.swift` (feature entry)
- [x] Create `LearnViewModel.swift`
- [x] Create `TrackListView.swift`
- [x] Create `LessonView.swift`
- [x] Create `LessonCard.swift` component
- [x] Create `PronunciationView.swift`
- [x] Create `PronunciationFeedback.swift` component
- [x] Implement progress through lessons

### Phase 5 Acceptance Criteria
- [ ] **AC-5.1**: All 4 learning tracks display (Arabic, Tajweed, Recitation, Dhikr)
- [ ] **AC-5.2**: Arabic track has 28 letter lessons
- [ ] **AC-5.3**: Completing lesson awards 10 Hasanat
- [ ] **AC-5.4**: Lesson progress saves and shows completion percentage
- [ ] **AC-5.5**: Audio pronunciation examples play correctly
- [ ] **AC-5.6**: Speech recognition activates on microphone permission grant
- [ ] **AC-5.7**: Pronunciation score returns value between 0-100
- [ ] **AC-5.8**: Perfect pronunciation score awards 5 bonus Hasanat
- [ ] **AC-5.9**: Track completion unlocks achievement

### Phase 5 Integration Tests
- [ ] **IT-5.1**: View tracks → Select track → See lessons → Complete lesson
- [ ] **IT-5.2**: Complete lesson → Hasanat increase → Progress updates
- [ ] **IT-5.3**: Attempt pronunciation → See score → Retry improves score
- [ ] **IT-5.4**: Complete all lessons in track → Achievement unlocks

### Phase 5 Verification
```bash
# Run learning tests
xcodebuild test -only-testing:SafaTests/LearningTests

# Test pronunciation service
# Manual: Speak Arabic letter, verify recognition works

# Verify lesson content
# Manual: Complete 3 lessons, verify content is educational
```

### 🎯 Milestone 5: Learning Features Complete
**Demo Checklist:**
- [ ] View all 4 learning tracks
- [ ] Start Arabic Foundations track
- [ ] Complete first letter lesson
- [ ] Listen to pronunciation audio
- [ ] Attempt pronunciation, see score
- [ ] View progress in track
- [ ] Hasanat awarded for completion
- [ ] Progress persists after restart
- [ ] **Record 3-minute demo video**

---

## Phase 6: AI Companion

### 6.1 LLM Integration
- [ ] Select and obtain final LLM model
- [ ] Convert model to Core ML format
- [x] Create `LLMService.swift`
- [ ] Implement model loading with progress
- [ ] Implement tokenization
- [ ] Implement inference
- [ ] Implement response streaming
- [ ] Optimize for memory usage
- [ ] Write performance tests

### 6.2 System Prompt
- [x] Create `SystemPrompts.swift`
- [x] Write comprehensive Islamic knowledge prompt
- [x] Include citation format requirements
- [x] Include madhab neutrality guidelines
- [x] Include boundary definitions
- [ ] Test with 20 diverse queries

### 6.3 Chat Repository
- [x] Create `ChatRepositoryProtocol.swift`
- [x] Create `ChatRepository.swift`
- [x] Implement conversation history storage
- [x] Implement `sendMessage(_:)` method
- [x] Implement `getConversations()` method
- [x] Write unit tests

### 6.4 Chat UI
- [x] Create `ChatView.swift` (feature entry)
- [x] Create `ChatViewModel.swift`
- [x] Create `MessageBubble.swift` component
- [x] Create `TypingIndicator.swift` component
- [x] Implement message input field
- [x] Implement conversation history view
- [x] Implement markdown rendering for responses
- [x] Add copy message functionality

### Phase 6 Acceptance Criteria
- [ ] **AC-6.1**: LLM loads in under 10 seconds on iPhone 15
- [ ] **AC-6.2**: Response generates in under 5 seconds for simple query
- [ ] **AC-6.3**: "What is the dua before eating?" returns Bismillah with source
- [ ] **AC-6.4**: "What breaks the fast?" returns accurate fiqh information
- [ ] **AC-6.5**: Political question is politely declined
- [ ] **AC-6.6**: Complex fiqh question recommends consulting a scholar
- [ ] **AC-6.7**: Response includes Quran/Hadith citations where applicable
- [ ] **AC-6.8**: Conversation history persists after app restart
- [ ] **AC-6.9**: Chat works fully offline (no network required)
- [ ] **AC-6.10**: Memory usage stays under 500MB during inference

### Phase 6 Integration Tests
- [ ] **IT-6.1**: Open chat → Type question → See response stream in
- [ ] **IT-6.2**: Ask about dua → Response includes Arabic + translation
- [ ] **IT-6.3**: Close app → Reopen → Previous conversation visible
- [ ] **IT-6.4**: Enable airplane mode → Chat still works

### Phase 6 Verification
```bash
# Test LLM performance
# Manual: Time model loading and response generation

# Test response quality
# Manual: Ask 20 questions from test set, evaluate responses

# Test offline capability
# Manual: Enable airplane mode, verify chat works
```

### 🎯 Milestone 6: AI Companion Complete
**Demo Checklist:**
- [ ] Open chat, see clean interface
- [ ] Ask "What is the dua before eating?" - get correct response
- [ ] Ask "How do I perform wudu?" - get step-by-step guide
- [ ] Ask political question - politely declined
- [ ] Response includes source citations
- [ ] Chat works with airplane mode on
- [ ] Conversation history persists
- [ ] Response time under 5 seconds
- [ ] **Record 4-minute demo video**

---

## Phase 7: Platform Features

### 7.1 Widgets
- [x] Create `PrayerTimeWidget.swift`
- [x] Create `PrayerTimeWidgetView.swift`
- [x] Implement prayer timeline provider
- [x] Create `StreakWidget.swift`
- [x] Create `StreakWidgetView.swift`
- [x] Create `DailyVerseWidget.swift`
- [x] Create `DashboardWidget.swift` (large)
- [x] Create `WidgetDataProvider.swift` (shared)
- [x] Test widget refresh behavior

### 7.2 Live Activities
- [x] Create `PrayerActivityAttributes.swift`
- [x] Implement Live Activity start logic
- [x] Implement Live Activity update logic
- [x] Create Dynamic Island compact view
- [x] Create Dynamic Island expanded view
- [x] Create Lock Screen live activity view
- [x] Test activity lifecycle

### 7.3 Focus Mode
- [x] Create Focus Mode configuration guide
- [x] Implement Focus Mode status checking
- [x] Create prayer Focus Mode filter
- [ ] Test Focus Mode integration

### 7.4 Siri Shortcuts
- [x] Create `PrayerTimeIntent.swift`
- [x] Create `NextPrayerIntent.swift`
- [x] Create `StartDhikrIntent.swift`
- [x] Implement intent handlers
- [x] Add Shortcuts app donations
- [ ] Test Siri invocations

### Phase 7 Acceptance Criteria
- [ ] **AC-7.1**: Small prayer widget shows next prayer name and time
- [ ] **AC-7.2**: Widget updates at each prayer time automatically
- [ ] **AC-7.3**: Streak widget shows current daily streak count
- [ ] **AC-7.4**: Live Activity shows countdown to next prayer
- [ ] **AC-7.5**: Dynamic Island shows prayer name and time remaining
- [ ] **AC-7.6**: Tapping Live Activity opens app to prayer screen
- [ ] **AC-7.7**: "Hey Siri, what's the next prayer?" returns correct answer
- [ ] **AC-7.8**: "Hey Siri, open Qibla" opens Qibla compass screen
- [ ] **AC-7.9**: Focus Mode silences non-prayer notifications

### Phase 7 Integration Tests
- [ ] **IT-7.1**: Add widget to home screen → Shows correct prayer time
- [ ] **IT-7.2**: Wait for prayer time → Widget updates automatically
- [ ] **IT-7.3**: Live Activity active → See on Lock Screen → Tap → App opens
- [ ] **IT-7.4**: Ask Siri next prayer → Hear correct response
- [ ] **IT-7.5**: Enable Focus Mode → Non-essential notifications blocked

### Phase 7 Verification
```bash
# Build widget extension
xcodebuild -scheme SafaWidgets build

# Test widget rendering
# Manual: Add each widget size, verify display

# Test Siri
# Manual: Test 5 Siri commands, verify responses
```

### 🎯 Milestone 7: Platform Features Complete
**Demo Checklist:**
- [ ] Add small prayer widget to home screen
- [ ] Add medium widget showing all prayer times
- [ ] Add streak widget showing current streak
- [ ] Live Activity shows prayer countdown
- [ ] Dynamic Island displays prayer info
- [ ] Ask Siri for next prayer time
- [ ] Ask Siri to open Qibla
- [ ] Enable Prayer Focus Mode
- [ ] **Record 4-minute demo video**

---

## Phase 8: Social Features

### 8.1 Family Circle
- [x] Create `FamilyRepositoryProtocol.swift`
- [x] Create `FamilyRepository.swift`
- [x] Implement invite link generation
- [x] Implement member joining flow
- [ ] Implement activity sharing logic
- [ ] Implement privacy controls

### 8.2 Family UI
- [x] Create `FamilyView.swift` (feature entry)
- [x] Create `FamilyViewModel.swift`
- [x] Create `FamilyCircleView.swift`
- [x] Create `FamilyMemberCard.swift` component
- [x] Create `InviteMemberView.swift`
- [x] Create privacy settings UI

### 8.3 Sharing
- [x] Implement verse sharing (ShareLink)
- [x] Implement achievement sharing
- [x] Create share card templates
- [x] Implement invite friend flow
- [x] Award Hasanat for sharing actions

### 8.4 CloudKit Sync
- [x] Configure CloudKit container
- [ ] Test sync between two devices
- [x] Implement conflict resolution
- [x] Handle offline scenarios gracefully
- [ ] Test sync performance

### Phase 8 Acceptance Criteria
- [ ] **AC-8.1**: Can create family circle and get invite link
- [ ] **AC-8.2**: Invite link opens app and prompts to join
- [ ] **AC-8.3**: Family member's streak visible in circle view
- [ ] **AC-8.4**: Privacy setting hides specific data from family
- [ ] **AC-8.5**: Sharing verse generates beautiful card with attribution
- [ ] **AC-8.6**: Sharing awards 5 Hasanat
- [ ] **AC-8.7**: Friend accepting invite awards 25 Hasanat
- [ ] **AC-8.8**: Data syncs between iPhone and iPad within 30 seconds
- [ ] **AC-8.9**: Offline changes sync when connection restored

### Phase 8 Integration Tests
- [ ] **IT-8.1**: Create circle → Generate link → Share → Other device joins
- [ ] **IT-8.2**: Log prayer on Device A → See update on Device B
- [ ] **IT-8.3**: Share verse → Opens share sheet → Share to Messages
- [ ] **IT-8.4**: Enable privacy → Family can't see hidden data

### Phase 8 Verification
```bash
# Test CloudKit sync
# Manual: Use two devices, verify data syncs

# Test family features
# Manual: Create circle, invite member, verify visibility

# Test sharing
# Manual: Share verse to Messages, verify card appearance
```

### 🎯 Milestone 8: Social Features Complete
**Demo Checklist:**
- [ ] Create family circle
- [ ] Generate and share invite link
- [ ] Second device joins circle
- [ ] See family member's streak
- [ ] Configure privacy settings
- [ ] Share a Quran verse
- [ ] Data syncs between devices
- [ ] Offline changes sync later
- [ ] **Record 4-minute demo video**

---

## Phase 9: Content & Polish

### 9.1 Hadith Feature
- [ ] Source and bundle `hadith.sqlite` database
- [x] Create `HadithRepositoryProtocol.swift`
- [x] Create `HadithRepository.swift`
- [x] Create `HadithView.swift`
- [x] Create `HadithViewModel.swift`
- [x] Create `CollectionListView.swift`
- [x] Create `HadithDetailView.swift`
- [x] Implement search functionality
- [x] Implement daily hadith feature

### 9.2 Dua & Adhkar Feature
- [x] Create and bundle `duas.json`
- [x] Create `DuaRepositoryProtocol.swift`
- [x] Create `DuaRepository.swift`
- [x] Create `DhikrView.swift`
- [x] Create `DhikrViewModel.swift`
- [x] Create `TasbeehCounterView.swift`
- [x] Create `CounterButton.swift` with haptics
- [x] Create `AdhkarListView.swift`
- [x] Create `DuaCategoryView.swift`
- [x] Implement morning/evening adhkar checklists
- [ ] Add audio pronunciations

### 9.3 Islamic Calendar
- [x] Create `CalendarView.swift`
- [x] Create `CalendarViewModel.swift`
- [x] Create `HijriDateCell.swift`
- [x] Implement Hijri date display
- [x] Highlight important Islamic dates
- [x] Implement event reminders

### 9.4 Ramadan Mode
- [x] Create `RamadanView.swift`
- [x] Create `RamadanViewModel.swift`
- [x] Create `FastingTrackerView.swift`
- [x] Create `TaraweehTrackerView.swift`
- [x] Create `ZakatCalculatorView.swift`
- [x] Implement auto-activation logic
- [x] Implement Suhoor/Iftar notifications
- [x] Create Ramadan home screen variant

### 9.5 Wind Down Mode
- [x] Create `WindDownView.swift`
- [x] Create `WindDownViewModel.swift`
- [x] Create `SleepAdhkarChecklist.swift`
- [x] Implement calming recitation player
- [x] Implement Fajr alarm setup
- [x] Integrate with iOS Sleep Focus

### 9.6 Settings
- [x] Create `SettingsView.swift`
- [x] Create `SettingsViewModel.swift`
- [x] Create `PrayerSettingsView.swift`
- [x] Create `NotificationSettingsView.swift`
- [x] Create `AppearanceSettingsView.swift`
- [x] Create `DownloadsView.swift`
- [x] Implement theme switching
- [x] Implement calculation method selection
- [x] Implement notification preferences

### 9.7 Onboarding
- [x] Create `OnboardingView.swift`
- [x] Create `OnboardingViewModel.swift`
- [x] Create `WelcomeView.swift`
- [x] Create `LocationPermissionView.swift`
- [x] Create `NotificationPermissionView.swift`
- [x] Create calculation method selection step
- [x] Implement first-launch detection

### 9.8 Home Screen
- [x] Create `HomeView.swift`
- [x] Create `HomeViewModel.swift`
- [x] Create `PrayerCountdownCard.swift`
- [x] Create `PrayerTimelineView.swift`
- [x] Create `ReminderCard.swift`
- [x] Implement contextual reminders logic
- [x] Create Ramadan home variant

### Phase 9 Acceptance Criteria
- [ ] **AC-9.1**: Browse 6 Hadith collections with correct hadith counts
- [ ] **AC-9.2**: Daily hadith displays different hadith each day
- [ ] **AC-9.3**: Tasbeeh counter increments with haptic feedback
- [ ] **AC-9.4**: Morning adhkar has complete checklist
- [ ] **AC-9.5**: Islamic calendar shows accurate Hijri dates
- [ ] **AC-9.6**: Ramadan mode activates during Ramadan month
- [ ] **AC-9.7**: Zakat calculator computes correctly for $10,000 savings
- [ ] **AC-9.8**: Wind down mode plays calming recitation
- [ ] **AC-9.9**: Onboarding completes and doesn't show again
- [ ] **AC-9.10**: Home screen shows contextual reminder based on time

### Phase 9 Integration Tests
- [ ] **IT-9.1**: Browse hadith → Search → Find specific hadith
- [ ] **IT-9.2**: Complete tasbeeh 33 times → Hasanat awarded
- [ ] **IT-9.3**: Fresh install → Complete onboarding → Home screen
- [ ] **IT-9.4**: Set Ramadan mode → Home screen transforms
- [ ] **IT-9.5**: Open app before Fajr → See Tahajjud reminder

### 🎯 Milestone 9: Content & Polish Complete
**Demo Checklist:**
- [ ] Fresh install shows onboarding flow
- [ ] Complete onboarding, arrive at home screen
- [ ] Home shows contextual reminder
- [ ] Browse and search Hadith
- [ ] Use tasbeeh counter with haptics
- [ ] Complete morning adhkar checklist
- [ ] View Islamic calendar with Hijri dates
- [ ] Enable Ramadan mode, see transformed home
- [ ] Calculate Zakat
- [ ] Start wind down mode
- [ ] Change theme in settings
- [ ] **Record 5-minute demo video**

---

## Phase 10: Launch Preparation

### 10.1 Testing
- [ ] Achieve 90%+ unit test coverage for Domain layer
- [ ] Achieve 80%+ unit test coverage for Repositories
- [x] Write UI tests for critical user flows
- [ ] Perform manual QA on all features
- [ ] Test on iPhone 15, 15 Pro, SE (3rd gen)
- [ ] Test accessibility (VoiceOver)
- [ ] Test with Low Power Mode
- [ ] Test localization readiness

### 10.2 Performance Optimization
- [ ] Profile app launch time (target <2s)
- [ ] Profile memory usage (target <200MB baseline)
- [ ] Optimize Core Data fetch requests
- [ ] Optimize LLM inference memory
- [ ] Test battery impact over 1 hour usage
- [ ] Optimize image assets

### 10.3 Beta Testing
- [ ] Set up TestFlight
- [ ] Recruit 50+ beta testers
- [ ] Create feedback form
- [ ] Run 2-week beta period
- [ ] Triage and fix critical bugs
- [ ] Incorporate top feedback items

### 10.4 App Store Submission
- [ ] Create App Store screenshots (6.7", 6.1", 5.5")
- [ ] Write App Store description
- [ ] Create 30-second app preview video
- [ ] Configure App Store Connect metadata
- [ ] Set up pricing (Free)
- [ ] Submit for App Review
- [ ] Address any review feedback
- [ ] Launch!

### Phase 10 Acceptance Criteria
- [ ] **AC-10.1**: App launches in under 2 seconds on iPhone 15
- [ ] **AC-10.2**: Baseline memory usage under 200MB
- [ ] **AC-10.3**: No crash reports in 2-week beta
- [ ] **AC-10.4**: Beta tester satisfaction >80%
- [ ] **AC-10.5**: All critical bugs fixed
- [ ] **AC-10.6**: App Review approval received
- [ ] **AC-10.7**: App live on App Store

### Phase 10 Verification
```bash
# Run full test suite
xcodebuild test -scheme Safa

# Check test coverage
xcov --project Safa.xcodeproj --scheme Safa --minimum_coverage_percentage 80

# Profile performance
# Use Instruments: Time Profiler, Allocations, Energy Log
```

### 🎯 Milestone 10: Launch Ready
**Final Demo Checklist:**
- [ ] Complete fresh install experience
- [ ] All features working end-to-end
- [ ] Performance meets targets
- [ ] No critical bugs
- [ ] Beta feedback addressed
- [ ] App Store assets ready
- [ ] App approved and live
- [ ] **Record 10-minute complete walkthrough video**

---

## Progress Summary

| Phase | Tasks | Completed | ACs | ACs Passed | Progress |
|-------|-------|-----------|-----|------------|----------|
| 0: Foundation | 20 | 14 | 5 | 0 | 70% |
| 1: Infrastructure | 45 | 45 | 6 | 0 | 100% |
| 2: Prayer | 28 | 28 | 10 | 0 | 100% |
| 3: Quran | 24 | 20 | 10 | 0 | 83% |
| 4: Gamification | 22 | 18 | 10 | 0 | 82% |
| 5: Learning | 20 | 18 | 9 | 0 | 90% |
| 6: AI Companion | 20 | 12 | 10 | 0 | 60% |
| 7: Platform | 20 | 18 | 9 | 0 | 90% |
| 8: Social | 16 | 14 | 9 | 0 | 88% |
| 9: Content | 50 | 45 | 10 | 0 | 90% |
| 10: Launch | 24 | 2 | 7 | 0 | 8% |
| **Total** | **289** | **234** | **95** | **0** | **81%** |

### File Statistics
- **Swift Files:** 138 (103 main + 35 tests)
- **JSON Data Files:** 8
- **Unit Test Files:** 35

### Critical Gaps
- **Data files not bundled**: quran.sqlite, hadith.sqlite, pronunciation audio
- **LLM not integrated**: Model selection and Core ML conversion pending
- **Acceptance Criteria**: 0/95 verified - need validation pass

---

## Milestone Video Archive

| Milestone | Status | Video Link |
|-----------|--------|------------|
| M0: Project Skeleton | Pending | - |
| M1: Core Infrastructure | Pending | - |
| M2: Prayer Features | Pending | - |
| M3: Quran Reader | Pending | - |
| M4: Gamification | Pending | - |
| M5: Learning | Pending | - |
| M6: AI Companion | Pending | - |
| M7: Platform Features | Pending | - |
| M8: Social Features | Pending | - |
| M9: Content & Polish | Pending | - |
| M10: Launch Ready | Pending | - |

---

*Last Updated: February 5, 2026 (Session Update - 81% Complete, added location intelligence)*
