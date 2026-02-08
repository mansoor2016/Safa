# Safa - Development Task Breakdown

## Overview

This document tracks all development tasks for the Safa iOS app. Each phase includes:
- **Implementation tasks** - Code to write
- **Acceptance criteria** - How we verify it works correctly
- **Integration tests** - User flow verification
- **Milestone demo** - End-of-phase validation checkpoint

**Compact Mode (February 7, 2026):**
- This file now shows active backlog items only (`[ ]`, `[~]`, `[!]`).
- Completed items were compacted and archived in `.docs/TASKS_ARCHIVE_2026-02-07.md`.

**Legend:**
- `[ ]` Not started
- `[x]` Completed
- `[~]` In progress
- `[!]` Blocked

**Verification Commands:**
```bash
# Build project
xcodebuild -scheme Safa -destination 'platform=iOS Simulator,name=iPhone 17' build

# Run all tests
xcodebuild -scheme Safa -destination 'platform=iOS Simulator,name=iPhone 17' test

# Run specific test class
xcodebuild -scheme Safa -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:SafaTests/{TestClassName} test

# Launch app in simulator
xcrun simctl boot "iPhone 17" && xcrun simctl launch booted com.safa.app
```

---

## Phase 0: Project Foundation

### 0.1 Repository & Git Setup
- [ ] Set up branch protection rules (main branch)

### 0.2 Agent Guidance Documentation

### 0.3 Xcode Project Configuration
- [x] Set deployment target to iOS 26 (confirmed in `Safa.xcodeproj/project.pbxproj`)
- [x] Create Widget extension target in Xcode project (`SafaWidgetExtension`)
- [ ] Create Intents extension target in Xcode project (`SafaIntents`)
- [ ] [manual] Verify Apple Developer account/certificates/provisioning are valid for both `Mawj.Safa` and `Mawj.Safa.SafaWidgetExtension` by running on a physical iPhone

### 0.4 Core Directory Structure

### Phase 0 Acceptance Criteria
- [x] **AC-0.4**: Widget extension target builds independently

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
- [x] Widget extension compiles
- [ ] All directories created per technical spec
- [ ] Documentation files in place

---

## Phase 1: Core Infrastructure

### 1.1 Dependencies Container

### 1.2 App Router & Navigation

### 1.3 Core Data Stack

### 1.4 Domain Entities

### 1.5 Design System

### 1.5.1 Disabled Feature Pattern

### 1.6 Shared Utilities

### 1.7 Location Intelligence

### Phase 1 Acceptance Criteria

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

### 2.2 Qibla Calculation

### 2.3 Location Service

### 2.4 Prayer Repository

### 2.5 Prayer UI

### 2.6 Prayer Notifications

### 2.7 Prayer Quality Logs (Optional)
- [ ] Add optional lightweight prayer log fields: on-time, congregation, focus rating
- [ ] Keep private and non-judgmental — no gamification pressure on quality
- [ ] Show in personal progress only

### Phase 2 Acceptance Criteria

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
- [x] Populate full Quran data (6,236 ayahs, 114 surahs, 30 juz via tanzil.net JSON)
- [x] Wire QuranSearchView to SQLite FTS instead of hardcoded sample data
- [x] Add Quran data integrity tests (21 tests: surah counts, ayah counts, FTS search, juz boundaries)
- [ ] Verify translation accuracy (spot check 10 ayahs)

### 3.2 Quran Repository

### 3.3 Quran UI

### 3.4 Audio Playback

### 3.5 Predictive Audio Download

### 3.6 Smart Cleanup (Auto-Remove Unused Audio)

### Phase 3 Acceptance Criteria

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

### 4.2 Hasanat Logic

### 4.3 Streak Logic

### 4.4 Achievements
- [ ] Create achievement badge assets

### 4.5 Progress UI

### 4.6 Weekly Reflection Summary
- [ ] Aggregate weekly metrics (prayers logged, Quran continuity, streak trends)
- [ ] Design summary layout with suggested focus for next week
- [ ] Schedule weekly notification prompt (opt-in, not pushy)

### Phase 4 Acceptance Criteria

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
- [ ] Create pronunciation audio files

### 5.2 Learning Repository

### 5.3 Pronunciation Checker
- [ ] Write unit tests with sample audio

### 5.4 Learning UI

### 5.5 Progressive Learn Rollout
- [ ] Audit which learning tracks have content ready
- [ ] Enable ready tracks individually via FeatureFlags instead of gating entire tab
- [ ] Add track-level "Coming Soon" for incomplete tracks

### 5.6 Micro-Practice Sessions
- [x] Define `PracticeSession` model (type, duration, content)
- [ ] Build 1-ayah read + reflection prompt flow
- [ ] Build 33-count dhikr quick session
- [ ] Build 1-hadith/day with save/share

### Phase 5 Acceptance Criteria

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

### 6.1 Apple Foundation Models Integration
- [~] Implement `LanguageModelSession` integration (placeholder - requires iOS 18.4 SDK)
- [~] Implement response streaming with Apple FM API (placeholder - requires iOS 18.4 SDK)

### 6.2 RAG (Retrieval-Augmented Generation)

### 6.3 System Prompt
- [~] Test with 20 diverse queries (test cases created in AICompanionQueryTests.swift, actual AI testing requires iOS 18.4+)

### 6.4 Chat Repository

### 6.5 Chat UI

### Phase 6 Acceptance Criteria
- [ ] **AC-6.2**: Response generates in under 5 seconds for simple query (iOS 18.4+)
- [ ] **AC-6.3**: "What is the dua before eating?" returns Bismillah with source citation
- [ ] **AC-6.4**: "What breaks the fast?" returns accurate fiqh information with Hadith reference
- [ ] **AC-6.9**: Chat works fully offline (Apple FM + local RAG)

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

### 7.1 Widgets (Prioritized)

- [x] Share prayer times from main app to widget via App Group UserDefaults (WidgetDataService)
- [x] Widget reads real calculated prayer times from App Group (falls back to London defaults)
- [x] Widget shows correct Hijri date from App Group
- [x] InteractivePrayerWidget reads real times + logged prayer state from App Group
- [x] StandByWidget reads next prayer + Fajr time from App Group
- [x] PrayerRepository migrated to App Group UserDefaults (with one-time migration)
- [x] Widget extension entitlements added for App Group access
- [ ] Add streak widget (AC-7.3 — not implemented)

### 7.1.1 Lock Screen Widgets
- [x] Implement `.accessoryCircular` widget (next prayer countdown ring)
- [x] Implement `.accessoryRectangular` widget (next prayer name + time + countdown)
- [x] Implement `.accessoryInline` widget (next prayer name and time, single line)
- [ ] Test Lock Screen widgets on device

### 7.1.2 Interactive Widgets
- [ ] Test interactive widgets on device

### 7.1.3 StandBy Mode
- [ ] Test in StandBy simulator

### 7.1.4 Spotlight Search (CoreSpotlight)

### 7.2 Live Activities

### 7.3 Focus Mode
- [ ] Test Focus Mode integration

### 7.4 Siri Shortcuts
- [ ] Test Siri invocations

### Phase 7 Acceptance Criteria
- [ ] **AC-7.1**: Small prayer widget shows next prayer name and time (code complete, needs device testing)
- [ ] **AC-7.2**: Widget updates at each prayer time automatically (code complete, needs device testing)
- [ ] **AC-7.3**: Streak widget shows current daily streak count (not implemented — no streak widget)
- [ ] **AC-7.4**: Live Activity shows countdown to next prayer (Live Activity code exists in main app)
- [ ] **AC-7.5**: Dynamic Island shows prayer name and time remaining (Live Activity code exists)
- [ ] **AC-7.6**: Tapping Live Activity opens app to prayer screen (needs device testing)
- [ ] **AC-7.7**: "Hey Siri, what's the next prayer?" returns correct answer (needs device testing)
- [ ] **AC-7.8**: "Hey Siri, open Qibla" opens Qibla compass screen (needs device testing)
- [ ] **AC-7.9**: Focus Mode silences non-prayer notifications (needs device testing)
- [ ] **AC-7.10**: Tap prayer in interactive widget → logs prayer without opening app (code complete, needs device testing)
- [ ] **AC-7.11**: Tap tasbeeh widget → counter increments (code complete, needs device testing)
- [ ] **AC-7.12**: StandBy mode shows prayer times in large, readable format (code complete, needs device testing)
- [ ] **AC-7.13**: Search "Ayatul Kursi" in iOS Spotlight → shows result from Safa (needs device testing)
- [ ] **AC-7.14**: Tap Spotlight result → opens correct content in Safa (needs device testing)

### Phase 7 Integration Tests
- [ ] **IT-7.1**: Add widget to home screen → Shows correct prayer time
- [ ] **IT-7.2**: Wait for prayer time → Widget updates automatically
- [ ] **IT-7.3**: Live Activity active → See on Lock Screen → Tap → App opens
- [ ] **IT-7.4**: Ask Siri next prayer → Hear correct response
- [ ] **IT-7.5**: Enable Focus Mode → Non-essential notifications blocked

### Phase 7 Verification
```bash
# Build widget extension
xcodebuild -scheme SafaWidget build

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

### 8.2 Family UI

### 8.3 Sharing

### 8.3.1 Invite Friends (App Store Link)
- [ ] Update `appStoreURL` placeholder with real App ID after submission

### 8.4 CloudKit Sync
- [ ] Test sync between two devices
- [ ] Test sync performance

### Phase 8 Acceptance Criteria
- [ ] **AC-8.8**: Data syncs between iPhone and iPad within 30 seconds (needs multi-device test)

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
- [ ] Populate full Hadith data (currently sample data only)

### 9.2 Dua & Adhkar Feature
- [ ] Add audio pronunciations

### 9.3 Islamic Calendar

### 9.3.1 Calendar Integration (EventKit + .ics)

### 9.4 Ramadan Mode

### 9.4.0 Apple Health Integration (Fasting)

### 9.4.1 Ramadan Home Banner
- [ ] Bundle Maghrib adhan audio file

### 9.5 Wind Down Mode

### 9.6 Settings

### 9.7 Onboarding (Streamlined 3-page flow)

### 9.8 Home Screen

### 9.9 Haptic System Unification
- [x] Define `HapticEvent` enum with all use cases (tap, commit, success, warning, qibla, tasbeeh, milestone)
- [x] Create event-to-style mapping in `HapticFeedbackService` (`play(_:)` dispatcher)
- [x] Replace all direct `UIImpactFeedbackGenerator` calls in feature views with service calls (20 locations across 13 files)
- [ ] Add Haptics settings section (On/Off, Intensity: Subtle/Balanced/Strong, Test button)
- [x] Gate haptics on `UIAccessibility.isReduceMotionEnabled` (in `play(_:)` dispatcher)
- [x] Unit tests for event mapping and preference gating (22 tests in HapticFeedbackServiceTests)

### 9.10 Degraded State Banners
- [x] Create shared `DegradedStateBanner` component (icon + message + optional action)
- [x] Apply to: Location fallback, Compass accuracy, Offline mode, Audio failure, Sync paused (5 standard variants)
- [x] Replace ad-hoc inline indicators with consistent banner component (PrayerView updated)
- [x] Add "System Status" sheet in Settings (location, notifications, sync, storage, network)

### 9.11 Home Intent Resolver
- [ ] Build `HomeIntentResolver` service (returns 1-3 prioritised actions based on time + streak + recency)
- [ ] Create reusable `ResumeCard` component (last surah, last lesson, last dhikr)
- [ ] Update HomeView with context-aware quick actions

### 9.12 Motion & Spacing Tokens
- [ ] Define motion tokens in design system (durations, curves, spring presets)
- [ ] Define semantic elevation/surface tokens for card styles
- [ ] Apply tokens across Home/Prayer/Quran/Learn for consistency
- [ ] Add skeleton loaders for key screens
- [ ] Smooth numeric transitions for counters and streaks

### 9.13 Search & Navigation Coherence
- [ ] Unify search UI pattern across Quran/Hadith/Calendar
- [x] Restructure "More" tab: Daily Practice, Knowledge & Tools, Progress, Settings
- [x] Normalise screen entry points through AppRouter destinations (deep links use selectedTab for quran/prayer/learn)

### 9.14 Dark Mode Implementation
- [x] Wire existing ThemeManager into SafaApp (.safaTheme() modifier, .preferredColorScheme())
- [x] Add System/Light/Dark appearance picker in Settings > Appearance
- [x] Wire accent color changes through ThemeManager
- [x] Add ThemeManager unit tests (16 tests: persistence, enum mapping, options)
- [ ] Define semantic color tokens with light/dark parity (Background, Card, Text tiers, Accent, Status)
- [ ] Tune Quran reading surface for night comfort (low-glare, no pure-black + harsh-white)
- [ ] Dark mode pass: Home, Prayer, Qibla
- [ ] Dark mode pass: Quran reader and search
- [ ] Dark mode pass: Dhikr, counters, Settings, Onboarding
- [ ] Dark mode pass: Banners, alerts, progress visuals, sheets
- [ ] Screenshot/snapshot coverage for key screens in both themes

### 9.15 Sharing & Social Polish
- [ ] Upgrade share cards with refined layout presets and export quality
- [ ] Add cleaner share composer flow for verses/hadith/achievements
- [ ] Improve invite flow with clear post-share confirmation states

### 9.16 Observability Instrumentation
- [x] Define analytics event schema (name, flow, context, result, durationMs)
- [x] Instrument onboarding completion funnel (AnalyticsEvent.onboardingCompleted)
- [x] Instrument core actions: prayer log, Quran resume, dhikr completion (standard events defined)
- [x] Instrument degraded-state frequency and recovery rates (locationFallback, syncFallback, notificationFailed)
- [x] Implement privacy rules: never log religious content, private notes, AI prompts (service doc + buffer-only)
- [ ] Add release quality gate checks for crash-free sessions and performance budgets

### Phase 9 Acceptance Criteria

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

### 10.1 Accessibility
- [ ] Verify Dynamic Type scaling on all screens
- [ ] Verify color contrast meets WCAG AA (4.5:1)
- [ ] Complete Dynamic Type support audit for all major screens
- [ ] Improve VoiceOver rotor flow for Quran ayah navigation
- [ ] Refine high-contrast mode for core cards and charts
- [ ] Add "Minimal Motion" profile that suppresses all non-essential animation
- [ ] UI tests for large content size and VoiceOver labels on critical screens

### 10.2 Device Compatibility & Testing

**Supported Device Range:**
- **Minimum iOS**: 26.0 (uses latest SwiftUI, @Observable, NavigationPath)
- **AI Companion**: Disabled by default via FeatureFlags (iOS version gate removed — feature not yet implemented)
- **Supported iPhones**: iPhone XS (2018) and newer (~6 years of devices)

**Note:** SwiftUI scales layouts natively. Only boundary testing required.

#### 10.2.1 Screen Size Boundary Testing
- [ ] Test on iPhone SE simulator (4.7" - smallest supported)
- [ ] Test on iPhone 16 Pro Max simulator (6.9" - largest)
- [ ] Verify Arabic text doesn't overflow on SE
- [ ] Verify layouts don't look sparse on Pro Max
- [ ] Spot check: Quran reader, Prayer cards, Home screen

#### 10.2.2 iOS Version Testing
- [ ] Test on iOS 26.0 (minimum supported)
- [ ] Test on iOS 18.4+ (verify AI Companion activates)
- [ ] Verify "Requires iOS 18.4" fallback message works

#### 10.2.3 Feature Verification
- [ ] Dynamic Island displays correctly (Pro models)
- [ ] Live Activities work
- [x] AI Companion disabled via FeatureFlags (shows "Coming Soon" on home and More tab)

#### 10.2.4 Test Coverage
- [ ] Achieve 90%+ unit test coverage for Domain layer
- [ ] Achieve 80%+ unit test coverage for Repositories
- [ ] Run UI tests on iPhone SE + iPhone 16 Pro simulators

#### 10.2.5 Manual QA
- [ ] Perform manual QA on all features
- [ ] Test VoiceOver on critical flows
- [ ] Test Dynamic Type at largest setting
- [ ] Test with Low Power Mode
- [ ] Test in Dark Mode

### 10.3 Performance Optimization
- [ ] Profile app launch time (target: p50 < 1s, p95 < 2s)
- [ ] Profile memory usage (target: < 200MB baseline)
- [ ] Add skeleton loading states for Home, Prayer, Quran screens
- [ ] Precompute and cache home context for instant rendering
- [ ] Optimize Core Data fetch requests
- [ ] Optimize LLM inference memory
- [ ] Test battery impact over 1 hour usage
- [ ] Optimize image assets
- [ ] Set up performance budget gates for release (block if p95 > 3s or crash-free < 99%)

### 10.3.1 Dark Mode QA
- [ ] Dark mode contrast audit for all primary screens
- [ ] Verify Quran reading surface readability in dark mode
- [ ] Verify all semantic tokens have light/dark parity
- [ ] Screenshot comparison: light vs dark for key flows

### 10.3.2 Observability & Release Quality
- [ ] Quality dashboards operational (crash rate, launch time, feature adoption)
- [ ] Release gating thresholds set and validated
- [ ] Regression prevention: UI snapshots + flow checks in CI

### 10.4 Beta Testing
- [ ] Set up TestFlight
- [ ] Recruit 50+ beta testers
- [ ] Create feedback form
- [ ] Run 2-week beta period
- [ ] Triage and fix critical bugs
- [ ] Incorporate top feedback items

### 10.5 App Store Submission
- [x] **Verify deployment target is iOS 26** (confirmed in project.pbxproj)
- [ ] Create App Store screenshots (6.9", 6.7", 6.1", 5.5" - all supported sizes)
- [ ] Write App Store description (highlight device compatibility)
- [ ] Create 30-second app preview video
- [ ] Configure App Store Connect metadata
- [ ] Set minimum iOS version to 26.0 in App Store Connect
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

### Active Snapshot (Updated February 7, 2026)
- **Version:** 1.1 (auto build number from git commit count)
- **Tests passing:** 1,616+ (all green)
- Blocked tasks: 0

### Project Reality Checks
- Xcode targets currently configured: `Safa`, `SafaTests`, `SafaUITests`, `SafaWidgetExtensionExtension` (intents extension target not yet created)
- Deployment target in project build settings: iOS 26.2
- Device family in app target: `1,2` (iPhone + iPad)

### File Statistics
- **Swift Files:** 200+ (134 app + 63 unit tests + 2 UI tests + 4 widget files on disk)
- **JSON Data Files:** 5 (SampleQuranData, SampleHadithData, SampleDuaData, SampleLearningData, NamesOfAllahData)
- **SQLite Databases:** 2 (quran.sqlite at 4.2MB with full data, hadith.sqlite)
- **Unit Test Files:** 63 (in SafaTests/) + 2 UI test files (in SafaUITests/)
- **`func test` inventory:** 1,616+

### Critical Gaps
- **Quran data:** COMPLETE — Full 6,236 ayahs populated from tanzil.net, FTS5 search index built
- **Hadith data:** `scripts/create_hadith_database.py` generates sample data only. **Full population needed** (~30,000 hadiths from sunnah.com)
- **Pronunciation audio**: Audio files not yet bundled
- **AI Companion**: RAG system implemented (RAGService.swift), Apple Foundation Models placeholder ready. Feature disabled by default via FeatureFlags until implementation is complete.
- **Widget extension target created** (`SafaWidgetExtensionExtension`). Intents extension target still missing.
- **Old `SafaWidget/` folder** is orphaned (code ported to `SafaWidgetExtension/`). Can be removed after verification.

### Recently Enabled Features
The following features have complete implementations and are now enabled by default:
- **Spotlight Search** - iOS Spotlight integration for surahs, ayahs, duas, hadith
- **Calendar Export** - Export Islamic events to Apple Calendar or .ics file
- **Prayer Calendar Export** - Export prayer times to calendar
- **HealthKit Sync** - Log Ramadan fasts to Apple Health
- **Predictive Download** - Auto-download next surah audio
- **Smart Cleanup** - Auto-remove unused audio after retention period

### Content Sources (Resolved)
| Content | Source | Status |
|---------|--------|--------|
| Quran Arabic | Tanzil.net (Uthmani) via quran-json | **Complete** — 6,236 ayahs |
| Translation | Sahih International via quran-json | **Complete** — 6,236 ayahs |
| Hadith | Sunnah.com | Schema ready, needs full data |
| Audio | Everyayah.com + King Fahd | Not integrated |
| Tafsir | Ibn Kathir (English) | Not integrated |
| Duas/Adhkar | Hisnul Muslim | Sample data only |

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

### Recent Changes (February 7, 2026)

Features implemented in the latest session:

- **Quran Data Population**: Full 6,236 ayahs from tanzil.net data (4.2MB SQLite with FTS5 index)
- **QuranSearchView**: Wired to SQLite FTS instead of hardcoded sample data, with filter modes (All, Arabic, Translation, Surah Name)
- **Quran Data Integrity Tests**: 21 tests verifying 114 surahs, 6,236 ayahs, FTS search, juz boundaries
- **App Group Widget Data Sharing**: WidgetDataService writes real prayer times to shared container; all widgets now show accurate data instead of hardcoded London times
- **Widget Entitlements**: SafaWidgetExtension App Group entitlements for reading shared data
- **PrayerRepository Migration**: Moved from UserDefaults.standard to App Group UserDefaults with one-time migration
- **Dark Mode**: Wired existing ThemeManager into SafaApp; System/Light/Dark appearance picker in Settings
- **Version 1.1**: Bumped version, added auto build number from git commit count since last version tag
- **xcode-build Skill**: Rewritten with two-step approach to avoid false positives; added linker/signing error fallback
- **Duas Quick Links**: Reordered to Morning → After Prayer → Food & Drink → Sleep

### Previous Changes (February 6, 2026)

- **Prayer Progress Indicator**: Compact (home) and expanded (prayer page) with tappable dots to log/unlog prayers
- **Adhan Sound System**: 11 reciters in CAF format, per-prayer notification sounds, full-length playback, Fajr-specific adhan
- **Share Banner**: Card on home page, permanently dismisses after sharing
- **Settings Overhaul**: Unified feedback form, share section at top, adhan picker, Ramadan banner toggle, accessibility marked as not yet functional
- **Collapsible Ramadan Banner**: Repositioned between quick actions and daily verse, collapsed by default (expanded during Ramadan), shows 30 days before
- **Prayer Times Page**: Removed redundant checkboxes, added per-prayer bell notification icons, play/stop adhan button, removed Today's Prayers timeline from home
- **Tab Navigation**: "See All" and Next Prayer switch to Prayer tab via AppRouter.selectedTab (not push)
- **Location Fallback**: Default to London, UK when GPS unavailable
- **Build/Test Tooling**: `/build` and `/test` commands, `xcode-build` skill for filtered Xcode output

### DONE: Quran Data Population (Completed February 7, 2026)

All 6,236 ayahs populated from quran-json (tanzil.net data). Database: 4.2MB with FTS5 index.
QuranSearchView wired to repository FTS. 21 data integrity tests + 30 search VM tests passing.

**Remaining Quran work:**
- [ ] Connect audio player UI to AVFoundation for actual playback
- [ ] Implement audio download/caching for recitations
- [ ] Migrate bookmarks/progress from UserDefaults to Core Data (CloudKit sync)
- [ ] Add transliteration data (quran.com API or similar)

### TODO: Graceful Degradation & Resilience

**Priority: HIGH — Must fix before launch**

#### Critical (App Stability)

#### High (Incorrect Behavior)

#### Medium (User Experience)
- [ ] **Audio: Add resumable downloads** — Use URLSession resume data so interrupted downloads don't restart from zero.

#### Low (Robustness)
- [ ] **Offline queue: Migrate from UserDefaults to Core Data** — Current queue isn't crash-safe.

### TODO: Ramadan Page Enhancement

**Priority: MEDIUM — Enhance existing RamadanView**


### TODO: Smart Adhan (Location-Aware Notification Sounds)

**Priority: MEDIUM — v1 enhancement to existing notification system**

Design: One toggle, two automatic modes. No settings explosion.

| Condition | Behaviour |
|-----------|-----------|
| At Home + ringer on | Adhan sound (if adhan enabled) |
| Away from home OR silent mode | Standard iOS notification tone |

- [ ] Detect silent/ringer mode via `AVAudioSession` or system settings — deferred (iOS has no public API for ringer state detection; would require AudioToolbox private API)

### TODO: v2 Strategic Enhancements

**Priority: FUTURE — Post-launch features**

#### Mosque Mode
- [ ] Define mosque geofence data model (user-defined locations or mosque database)
- [ ] Implement CLCircularRegion monitoring for mosque zones (~100m radius)
- [ ] Auto-switch to silent/vibrate when entering mosque zone
- [ ] Adjust notification delivery: haptic only, no sound while in mosque
- [ ] Integrate with iOS Focus modes (if possible)
- [ ] Settings UI: "My Mosques" list with add/remove
- [ ] Show "In Mosque" indicator on prayer page when inside geofence
- [ ] Test geofence entry/exit transitions

#### watchOS Companion App
- [ ] Create watchOS target in Xcode
- [ ] Implement prayer time complications (Corner, Circular, Rectangular)
- [ ] Implement haptic adhan with distinct patterns per prayer
- [ ] Implement Digital Crown tasbeeh counter
- [ ] Implement standalone Qibla compass on watch
- [ ] Set up WatchConnectivity for iPhone ↔ Watch sync
- [ ] Test standalone mode (without iPhone)

#### Data Sovereignty & Export
- [x] Implement JSON export of all user data (preferences, stats, streaks, achievements, bookmarks, progress)
- [x] Implement CSV export for prayer logs (last 30 days)
- [x] Build "View All My Data" transparency screen (DataExportView with export descriptions)
- [ ] Implement manual backup/restore
- [ ] Add per-category data deletion

#### Apple Intelligence (App Intents)
- [ ] Define Prayer, Surah, Hadith as AppEntities
- [ ] Implement GetNextPrayerIntent for Siri
- [ ] Implement PlayAdhanIntent
- [ ] Implement OpenSurahIntent
- [ ] Implement StartTasbeehIntent
- [ ] Test Shortcuts automations (location-based prayer logging)

#### Assistive Access Mode
- [ ] Detect Assistive Access / Guided Access mode
- [ ] Build simplified 3-tab layout (Prayer, Qibla, Dhikr)
- [ ] Implement large-font prayer card
- [ ] Implement full-screen Qibla arrow
- [ ] Implement single-button tasbeeh
- [ ] Test with Switch Control and Voice Control

*Last Updated: February 8, 2026*
*Completed-task archive: `.docs/TASKS_ARCHIVE_2026-02-07.md`*
