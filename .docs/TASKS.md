# Safa - Task List

## Verification
```bash
xcodebuild -scheme Safa -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
xcodebuild -scheme Safa -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SafaTests test
```

---

## Completed

Foundation, Core Data, Dependencies, AppRouter, design system, disabled feature pattern, location intelligence. Prayer times (7 methods), Qibla compass, prayer logging with optimistic undo, notification scheduling (single NotificationScheduler). Full Quran (6,236 ayahs) with FTS search, surah reader with bookmarks/reading progress/auto-scroll/progress ring, matched-geometry zoom transitions. Hadith (34,178 entries) with SQLite FTS. Gamification: hasanat (20 award types with HasanatTracker dedup), streaks (5 types), 24 achievements, levels 1-10. Widgets (lock screen + streak), App Group sharing, Spotlight indexing. 5 App Intents wired to real data. Haptics, skeleton loaders, degraded state banners, theme/dark mode foundation. JSON/CSV data export, per-category deletion. Analytics schema, privacy-safe logging. Onboarding 3-page flow with location intelligence. Ramadan mode with iftar platter/prayer progress/fasting tracker. Premium UI: nav bar material morph, bottom sheet standardization, hero card compression, sticky context chip, screen state transitions (ErrorView), zero-state quality pass, motion tokens (SafaMotion), elevation/surface tokens (SafaElevation/SafaSurface). Location settings correctness: saved coords on cold start, calculationMethod consolidated to PreferencesManager, madhab wired into PrayerTimeCalculator. Localization foundation: 5 locales configured, ~119 strings, String Catalog enabled. Learning scaffolding (feature-flagged). Chat scaffolding (feature-flagged). Family circle scaffolding.

---

## Remaining — Code-Only (no device/external dependency)

### UI Polish
- [x] Contextual navigation actions + sticky filter rail (Quran + Hadith search filter pills)
- [x] Adaptive tab bar visibility (behind FF `.adaptiveTabBar`, OFF by default)
- [x] Home intent resolver (context-aware quick actions based on time/streak)
- [x] Resume-where-you-left-off card on Home (Quran reading progress)

### Dark Mode
- [ ] Quran reading surface comfort tuning
- [ ] Screen-by-screen dark mode pass (Home, Prayer, Qibla, Quran, Dhikr, Settings, Onboarding)
- [ ] Banners, alerts, progress visuals, sheets dark mode pass

### Search & Sharing
- [ ] Unify search UI pattern across Quran/Hadith/Calendar
- [ ] Upgrade share cards with refined layout
- [ ] Improve invite flow with confirmation states

### Test Coverage
- [ ] 90%+ unit test coverage for Domain layer
- [ ] 80%+ unit test coverage for Repositories

---

## Remaining — Requires Device or External Resources

### Localization
- [ ] Widget extension String Catalog + shared localized keys
- [ ] RTL audit (Arabic UI flow, mirrored icons, mixed-script Dynamic Type)
- [ ] Language settings UI (App Language + Content Language + fallback chain)
- [ ] Translation content (ayah/hadith/dua tables, language pack download)
- [ ] Validation (pseudo-localization, pluralization rules, screenshot coverage)

### AI Companion
- [ ] Apple Foundation Models integration (requires iOS 26 SDK + device)
- [ ] Response streaming + quality acceptance testing

### Platform Features (code complete, needs device testing)
- [ ] Widgets (Lock Screen, Home Screen, interactive, StandBy)
- [ ] Live Activities / Dynamic Island prayer countdown
- [ ] Siri Shortcuts invocation testing
- [ ] Focus Mode integration
- [ ] Spotlight search result tap → navigation

### Social Features (scaffolding exists, needs multi-device testing)
- [ ] CloudKit sync between two devices
- [ ] Family circle create/join/privacy flows
- [ ] Update appStoreURL with real App ID

### Audio Content
- [ ] Dua audio pronunciations (needs audio files)
- [ ] Bundle Maghrib adhan audio file
- [ ] Connect audio player to AVFoundation
- [ ] Audio download/caching for recitations

### Accessibility (needs device testing)
- [ ] Dynamic Type scaling audit
- [ ] WCAG AA color contrast verification
- [ ] VoiceOver rotor flow for Quran navigation
- [ ] High-contrast mode refinement
- [ ] Minimal Motion profile
- [ ] UI tests for large content size + VoiceOver labels
- [ ] iPhone SE + Pro Max boundary testing

### Performance (needs Instruments profiling)
- [ ] AppLaunchPerformanceTests (target < 2s)
- [ ] Memory profiling (target < 200MB)
- [ ] Precompute home context for instant rendering
- [ ] Core Data fetch + LLM inference memory optimization
- [ ] Battery impact test

### Launch
- [ ] TestFlight setup + beta period
- [ ] App Store screenshots, description, preview video
- [ ] App Store Connect submission

---

## Remaining — Post-Launch

- [ ] Additional App Intents (PlayAdhan, OpenSurah, StartTasbeeh, location automations)
- [ ] Achievement badge assets + weekly reflection summary + progress dashboard
- [ ] Quran: transliteration data, CloudKit bookmark migration
- [ ] Prayer quality logs (on-time, congregation, focus rating)
- [ ] Ringer mode detection for Smart Adhan (no public iOS API)
- [ ] Resumable audio downloads, offline queue migration to Core Data
- [ ] Manual backup/restore
- [ ] Mosque Mode (geofence-based)
- [ ] watchOS companion app
- [ ] Assistive Access Mode (simplified 3-tab layout)

---

*Last Updated: February 10, 2026*
