# Safa - Task List

## Verification
```bash
xcodebuild -scheme Safa -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
xcodebuild -scheme Safa -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SafaTests -parallel-testing-enabled NO test
```

---

## Completed

Foundation, Core Data, Dependencies, AppRouter, design system, disabled feature pattern, location intelligence. Prayer times (7 methods), Qibla compass, prayer logging with optimistic undo, notification scheduling (single NotificationScheduler). Full Quran (6,236 ayahs) with FTS search, surah reader with bookmarks/reading progress/auto-scroll/progress ring, matched-geometry zoom transitions, native `.searchable()` on Quran page (matches Dua page UX). Hadith (34,178 entries) with SQLite FTS. Gamification: hasanat (20 award types with HasanatTracker dedup), streaks (5 types), 24 achievements, levels 1-10. Widgets (lock screen + streak), App Group sharing, Spotlight indexing (SpotlightIndexService, 5 content types, deep links). 5 App Intents wired to real data (IntentHelpers). Live Activities: prayer countdown on lock screen + Dynamic Island (ActivityKit), lifecycle wiring in SafaApp. Haptics, skeleton loaders, degraded state banners, theme/dark mode foundation. JSON/CSV data export, per-category deletion. Analytics schema, privacy-safe logging. Onboarding 3-page flow with location intelligence. Ramadan mode with iftar platter/prayer progress/fasting tracker. Premium UI: nav bar material morph, bottom sheet standardization, hero card compression, sticky context chip, screen state transitions (ErrorView), zero-state quality pass, motion tokens (SafaMotion), elevation/surface tokens (SafaElevation/SafaSurface). Location settings correctness: saved coords on cold start, calculationMethod consolidated to PreferencesManager, madhab wired into PrayerTimeCalculator. Localization: 5 locales configured, ~960 strings in String Catalog (213 bulk-added Feb 11), all user-facing strings registered. Learning scaffolding (feature-flagged). Chat scaffolding (feature-flagged). Family circle scaffolding. UI polish (contextual nav, adaptive tab bar, home intent resolver, resume card). Dark mode (Quran surface, screen-by-screen pass, banners/alerts/sheets). Search unification + share card upgrade + invite flow. Test coverage backfill (Domain 90%+, Repositories 80%+, conformance cleanup). Accessibility: Dynamic Type audit (UIFontMetrics, 15 sizes replaced, 5 @ScaledMetric, DT caps), VoiceOver rotor for Quran, accessibility labels (13 screens + helpers + 21 tests), large content + VoiceOver UI tests (18 DynamicTypeScalingTests), Minimal Motion profile (18 ReduceMotionTests). Platform integration: Focus Mode (FocusModeService + SleepFocusService, 7 notification categories), Siri Shortcuts (5 intents via IntentHelpers), platform verification tests (40 tests). Audio pipeline: 11 adhan files bundled (35 MB), AudioPlayerService (AVFoundation, interrupt handling, remote controls), audio background mode. Performance: AppLaunchPerformanceTests (< 2s target), home context precomputation. Dua favourites (quick access button + heart toggle), in-app review prompt (exponential backoff), banner visibility logic (HomeBannerResolver), developer settings (UX variant toggles, reset onboarding). Dua data migration to bundled JSON (57 duas across 12 categories, DuaDataLoader, DuaCategoriesViewModel, ~27 new authentic duas with Arabic/transliteration/translation/sources), Ramadan duas loaded from repository with occasion filter, Islamic event notification message polish.

---

## Launch Sequence (Prioritized)

Tasks ordered by: launch-blocking status, end-user value, what they unblock.

### Phase 1: Accessibility & Layout Confidence
**Why first:** Apple rejects apps with broken accessibility. Layout bugs on small/large screens generate 1-star reviews immediately. These are non-negotiable for a quality v1.

- [x] iPhone SE + Pro Max boundary testing — catch layout overflow/clipping on extreme sizes
  - Fixed EidGreetingCard overflow on 375pt screens (`.frame(width:)` → `.frame(maxWidth:)`)
  - Fixed CompassView hardcoded sizes — now derives from `@ScaledMetric compassSize`
  - Build-verified on iPhone 16e (375pt), iPhone 17 Pro (393pt), iPhone 17 Pro Max (430pt)
- [ ] Backwards compatibility testing — verify app builds and tests pass on iOS 17, 18, and 26 simulators
  - Deployment target lowered from 26.2 → 17.0 (all APIs are iOS 17+ compatible)
  - AI Companion (Foundation Models) already gated with `#available(iOS 18.4, *)`
  - Download iOS 17 and 18 simulator runtimes, then run `/build` and `/test` on each
  - Use `/build --matrix` or `/test --matrix` to verify across all device sizes

### Phase 2: Widgets & Platform Integration
**Why second:** Widgets are the #1 daily engagement driver. Lock screen prayer times is a killer feature vs competitors. Code is complete — needs device verification for visual/interaction aspects.

- [ ] Widgets (Lock Screen, Home Screen, interactive, StandBy) — verify rendering, tap targets, data freshness *(manual device test)*
- [ ] Spotlight search result tap → navigation — verify deep links resolve to correct screens *(manual device test)*
- [ ] Siri Shortcuts invocation testing — verify intents work end-to-end *(manual device test)*

### Phase 3: Audio (Core Islamic Experience)
**Why third:** Hearing the adhan is deeply important culturally. Silent prayer notifications feel incomplete. Audio pipeline is fully implemented — needs device verification.

- [ ] Dua audio pronunciations (needs audio files) — defer if files unavailable, wire player now
- [ ] Audio playback verification — test adhan plays, backgrounding works *(manual device test)*

### Phase 4: Performance
**Why here:** Slow launch = uninstall. Profile after features are stable, not before. Quick wins likely in lazy loading and deferred init.

- [ ] Memory profiling (target < 200MB) *(manual — Instruments profiling)*
- [ ] Battery impact test *(manual — device with Live Activity running)*

### Phase 5: TestFlight & Launch
**Why last:** Ship to real users once accessibility, widgets, audio, and performance are solid.

- [ ] TestFlight setup + beta period
- [ ] App Store screenshots, description, preview video
- [ ] App Store Connect submission

---

## Post-v1 Fast Follows

### Localization (unlocks 80%+ of TAM)
**Why deferred:** Can ship v1 English-only. Language settings UI + RTL audit unlocks Arabic/Urdu/Turkish/Malay — the majority of the target market. Translation content added incrementally per locale.

- [ ] Language settings UI (App Language + Content Language + fallback chain)
- [ ] RTL audit (Arabic UI flow, mirrored icons, mixed-script Dynamic Type)
- [ ] Widget extension String Catalog + shared localized keys
- [ ] Translation content (ayah/hadith/dua tables, language pack download)
- [ ] Validation (pseudo-localization, pluralization rules, screenshot coverage)

### AI Companion
**Why deferred:** Requires iOS 26 SDK (not yet GA). Feature-flagged and scaffolded. High novelty but not core to prayer/Quran daily workflow.

- [ ] Apple Foundation Models integration (requires iOS 26 SDK + device)
- [ ] Response streaming + quality acceptance testing

### Social Features
**Why deferred:** Requires multi-device testing + paid Apple Developer account for CloudKit. Social features are engagement boosters, not core value proposition.

- [ ] CloudKit sync between two devices
- [ ] Family circle create/join/privacy flows
- [ ] Update appStoreURL with real App ID

### Audio Expansion
**Why deferred:** Full recitation audio requires large downloads, caching infrastructure, and offline queue. Ship basic adhan in v1, expand audio post-launch.

- [ ] Audio download/caching for recitations
- [ ] Resumable audio downloads, offline queue migration to Core Data

### Accessibility Polish
**Why deferred:** Core accessibility (Dynamic Type, VoiceOver, SE/Pro Max) ships in v1. These are refinements.

- [ ] WCAG AA color contrast verification
- [ ] High-contrast mode refinement

---

## Post-Launch Roadmap

- [ ] Additional App Intents (PlayAdhan, OpenSurah, StartTasbeeh, location automations)
- [ ] Achievement badge assets + weekly reflection summary + progress dashboard
- [ ] Quran: transliteration data, CloudKit bookmark migration
- [ ] Prayer quality logs (on-time, congregation, focus rating)
- [ ] Ringer mode detection for Smart Adhan (no public iOS API)
- [ ] Manual backup/restore
- [ ] Mosque Mode (geofence-based)
- [ ] watchOS companion app
- [ ] Assistive Access Mode (simplified 3-tab layout)
- [ ] Core Data fetch + LLM inference memory optimization
- [ ] Islamic event notification deep links — tap notification to open Quranic reference (e.g., Surah Al-Qadr 97:3 for Laylat al-Qadr) or dedicated event info screen

---

*Last Updated: February 12, 2026 (SE/Pro Max layout fixes, deployment target 26.2→17.0, build/test --matrix commands)*
