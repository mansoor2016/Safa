# Safa - Development Task Breakdown

## Overview

This document tracks remaining development tasks for the Safa iOS app. Completed phases are summarized as rollups. Active backlog items use `[ ]` (not started), `[~]` (in progress), `[!]` (blocked).

**Verification:**
```bash
xcodebuild -scheme Safa -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
xcodebuild -scheme Safa -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SafaTests test
```

---

## Completed Rollups

- **Phase 0-1 (Foundation):** Project structure, Dependencies container, AppRouter, Core Data stack, domain entities, design system, disabled feature pattern, location intelligence — all shipped.
- **Phase 2 (Prayer):** Prayer time calculation (7 methods), Qibla compass, location service, prayer repository, prayer UI with logging, notification scheduling — all shipped. Remaining: optional prayer quality logs.
- **Phase 3 (Quran):** Full 6,236-ayah dataset, surah browsing, ayah reader, search with FTS, bookmarks, reading progress, predictive download service, smart cleanup — all shipped. Remaining: audio playback, download/caching, CloudKit bookmark sync, transliteration.
- **Phase 4 (Gamification):** UserStateManager, hasanat awards (20 types with dedup via HasanatTracker), streaks (5 types with daily dedup), 24 achievements, level system (1-10), progress card on home — all shipped. Remaining: achievement badge assets, weekly reflection summary, progress dashboard UI (marked coming soon).
- **Phase 5 (Learning):** Learning tracks, lesson content view, pronunciation checker UI — scaffolding shipped but feature-flagged as coming soon. Remaining: pronunciation audio files, content for tracks, micro-practice sessions.
- **Localization foundation:** Phase 1 locales configured (en/ar/id/ur/bn), ~119 strings localized, String Catalog enabled.
- **Content data:** Full Quran (6,236 ayahs) + Hadith (34,178 entries) in SQLite with FTS + integrity tests.
- **Platform baseline:** Widget extension, App Group sharing, lock-screen + streak widgets, Spotlight indexing.
- **UX systems:** Haptics, degraded state banners, skeleton loaders, theme/dark mode foundation.
- **Observability:** Analytics schema, onboarding/core instrumentation, privacy-safe logging.
- **Data sovereignty:** JSON export, CSV prayer logs, per-category deletion (6 categories, 20+ tests), transparency screen.
- **Prayer fixes:** Isha-before-Maghrib fix, monotonic ordering (21 tests), notification reliability, duplicate notification consolidation (3 systems → 1 NotificationScheduler).
- **Hasanat overhaul (Feb 9):** HasanatTracker dedup layer, prayer log-unlog-relog fix, prayerAllFive wired to all screens, 6 previously unused awards wired, ShareService rewired to UserStateManager, daily streak on app launch, totalPrayersLogged counter, 37 tests.
- **Notification consolidation (Feb 9):** Deleted NotificationService (496 lines) + protocol, all callers use NotificationScheduler.shared, legacy identifier cleanup, 17-scenario virtual walkthrough verified.
- **Test consolidation (Feb 9):** SharedMocks.swift, 25 duplicate tests removed, 6 inline mocks → 1 shared mock, -415 lines.
- **Premium UI (Feb 9):** Nav bar material morph (Home/Prayer/Ramadan), 25 bottom sheets standardized with .compactSheet()/.fullSheet(), progress section marked coming soon.
- **Ramadan (Feb 9):** Combined duplicate daily goals ("Read 1 Juz Quran"), Ramadan page restructured with iftar platter/prayer progress/fasting tracker/Khatm goal.
- **App Intents (Feb 9):** 5 intents wired to real data (GetPrayerTimes, GetNextPrayer, LogPrayer, GetQiblaDirection, GetDailyVerse).
- **Quran reader refinements (Feb 10):** Fixed "Continue Reading" bug (was always writing ayah 1), character-aware auto-scroll with new 0.25x-1x speed scale and per-ayah interval formula, bookmark toggle shows undo toast, auto-scroll settings toggle + 7s auto-hide control, green checkmark on completed surahs in list, auto-complete on scroll end, configurable progress ring (high-water mark vs current position) via long-press context menu with reset option. 8 new tests for progress ring, 4 updated auto-scroll tests. Design principle added: settings proximity (feature settings live close to feature, not in global Settings).
- **Onboarding fix (Feb 10):** Page 3 overflow fix — content wrapped in ScrollView, "Get Started" button pinned to bottom, reduced icon/spacing, removed extra whitespace before Bismillah.
- **Location settings correctness (Feb 10):** Fixed 3 critical bugs: (1) saved coordinates now used on cold start instead of falling back to London, (2) all calculationMethod reads consolidated to PreferencesManager (removed raw UserDefaults drift in PrayerViewModel/HomeView/RamadanView/NotificationScheduler), (3) madhab now wired into PrayerTimeCalculator — Asr time respects Hanafi vs Shafi selection. Added `PreferencesManager.loadPreferencesSync()` for non-async contexts. 8 regression tests covering madhab Asr impact, sync prefs reads, saved coordinate resolution.

---

## Active Work: Localization (L10N)

**Dependency order:** L10N.2 → L10N.4 (RTL) → L10N.3 (settings) → L10N.5 (content) → L10N.6 (validation)

### L10N.2 Xcode Foundation (remaining)
- [ ] Enable String Catalog for SafaWidgetExtension target (shared keys)
- [ ] Ensure widgets and Live Activities consume shared localized keys
- [ ] Add localization lint/check in CI
- [ ] Publish feature-by-language support matrix

### L10N.4 RTL Readiness
- [ ] Audit major screens for semantic layout and mirrored icons
- [ ] Validate Arabic UI flow in key screens
- [ ] Validate mixed-script rendering with Dynamic Type
- [ ] Fix truncation/overlap for compact devices (iPhone SE)

### L10N.3 Language Settings
- [ ] Add Settings > Language section (App Language + Content Language)
- [ ] Persist language preferences (LanguagePreferences model)
- [ ] Implement runtime fallback chain
- [ ] Show "Not available" states for untranslated content

### L10N.5 Content Translation
- [ ] Create ayah/hadith/dua translation tables
- [ ] Implement on-demand language pack download + cache
- [ ] Define content availability manifest
- [ ] Add availability labels in Quran/Hadith/Dua surfaces

### L10N.6 Validation & Release Gates
- [ ] Pseudo-localization UI test pass
- [ ] Screenshot coverage for Phase 1 languages
- [ ] Verify pluralization rules (Arabic 6 forms, Bengali/Hindi/Urdu 2 forms, etc.)
- [ ] Track localization telemetry + block release on regression

---

## Active Work: Phase 6 — AI Companion

- [~] Apple Foundation Models integration (placeholder — requires iOS 26 SDK)
- [~] Response streaming (placeholder)
- [~] Test with 20 diverse queries (test cases created, actual AI testing requires device)
- [ ] Response quality acceptance: dua queries, fiqh queries, offline capability

---

## Active Work: Phase 7 — Platform Features

All code complete, needs device testing:
- [ ] Lock Screen widgets, Home Screen widgets, interactive widgets, StandBy mode
- [ ] Live Activities / Dynamic Island prayer countdown
- [ ] Siri Shortcuts (5 intents implemented — need device invocation testing)
- [ ] Focus Mode integration
- [ ] Spotlight search result tap → navigation

---

## Active Work: Phase 8 — Social Features

Code scaffolding exists, needs real multi-device testing:
- [ ] Update appStoreURL with real App ID after submission
- [ ] Test CloudKit sync between two devices
- [ ] Test family circle create/join/privacy flows

---

## Active Work: Phase 9 — Content & Polish

### Remaining feature work
- [ ] Dua audio pronunciations
- [ ] Bundle Maghrib adhan audio file
- [ ] Home intent resolver (context-aware quick actions + resume cards)

### Premium UI (remaining waves)
- [x] Screen state transitions (ErrorView component + wired into Prayer/Quran/Hadith/Home)
- [x] Hero card compression + sticky context chip (Home)
- [x] Optimistic action feedback with undo rail (prayer logging)
- [x] Matched-geometry card-to-detail transition (Quran list → reader)
- [ ] Contextual navigation actions + sticky filter rail
- [ ] Adaptive tab bar visibility
- [x] Zero-state quality pass (improved empty state messages with next-action guidance)

### Design system tokens
- [x] Motion tokens (durations, curves, spring presets)
- [x] Semantic elevation/surface tokens for card styles

### Dark mode
- [ ] Quran reading surface comfort tuning
- [ ] Dark mode pass: Home, Prayer, Qibla, Quran, Dhikr, Settings, Onboarding
- [ ] Dark mode pass: Banners, alerts, progress visuals, sheets
- [ ] Screenshot comparison: light vs dark

### Search & sharing
- [ ] Unify search UI pattern across Quran/Hadith/Calendar
- [ ] Upgrade share cards with refined layout
- [ ] Improve invite flow with confirmation states

### Observability
- [ ] Release quality gate checks for crash-free sessions and performance budgets

---

## Active Work: Phase 10 — Launch Preparation

### Accessibility
- [ ] Dynamic Type scaling audit
- [ ] WCAG AA color contrast verification
- [ ] VoiceOver rotor flow for Quran navigation
- [ ] High-contrast mode refinement
- [ ] "Minimal Motion" profile
- [ ] UI tests for large content size + VoiceOver labels

### Device testing
- [ ] iPhone SE (smallest) + iPhone 16 Pro Max (largest) boundary testing
- [ ] iOS 26.0 minimum version testing
- [ ] Dynamic Island / Live Activities on Pro models

### Test coverage
- [ ] 90%+ unit test coverage for Domain layer
- [ ] 80%+ unit test coverage for Repositories
- [ ] UI tests on SE + Pro simulators

### Performance
- [ ] AppLaunchPerformanceTests (XCTMetric, target < 2s)
- [ ] Profile launch time with Instruments (p50 < 1s, p95 < 2s)
- [ ] Profile memory usage (target < 200MB)
- [ ] Precompute home context for instant rendering
- [ ] Optimize Core Data fetch requests + LLM inference memory
- [ ] Battery impact test (1 hour usage)
- [ ] Image asset optimization
- [ ] Performance budget gates for release

### Dark mode QA
- [ ] Contrast audit, Quran readability, semantic token parity, screenshot comparison

### Beta & submission
- [ ] Set up TestFlight, recruit 50+ testers, feedback form
- [ ] 2-week beta period, triage critical bugs
- [ ] App Store screenshots, description, preview video
- [ ] Configure App Store Connect, submit for review, launch

---

## Deferred Backlog (Post-Launch)

### Cross-cutting gaps
- [ ] Bundle pronunciation audio files
- [ ] Create SafaIntents extension target
- [ ] QA pass for dark mode, accessibility, performance

### Remaining App Intents
- [ ] PlayAdhanIntent, OpenSurahIntent, StartTasbeehIntent
- [ ] Shortcuts automations (location-based prayer logging)

### Gamification remaining
- [ ] Achievement badge assets
- [ ] Weekly reflection summary
- [ ] Progress dashboard (marked coming soon)

### Quran remaining
- [ ] Connect audio player to AVFoundation
- [ ] Audio download/caching for recitations
- [ ] Migrate bookmarks to Core Data (CloudKit sync)
- [ ] Transliteration data

### Prayer remaining
- [ ] Optional prayer quality logs (on-time, congregation, focus rating)

### Smart Adhan
- [ ] Detect ringer mode (deferred — no public iOS API)

### Graceful degradation
- [ ] Resumable audio downloads
- [ ] Migrate offline queue from UserDefaults to Core Data

### Data sovereignty remaining
- [ ] Manual backup/restore

### v2 strategic
- [ ] Mosque Mode (geofence-based silent/vibrate)
- [ ] watchOS companion app (complications, haptic adhan, Digital Crown tasbeeh)
- [ ] Assistive Access Mode (simplified 3-tab layout)

---

*Last Updated: February 10, 2026 (session 2)*
*Completed-task archive: `.docs/TASKS_ARCHIVE_2026-02-08.md`*
