# Safa - Task List

## Verification
```bash
xcodebuild -scheme Safa -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
xcodebuild -scheme Safa -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SafaTests test
```

---

## Completed

Foundation, Core Data, Dependencies, AppRouter, design system, disabled feature pattern, location intelligence. Prayer times (7 methods), Qibla compass, prayer logging with optimistic undo, notification scheduling (single NotificationScheduler). Full Quran (6,236 ayahs) with FTS search, surah reader with bookmarks/reading progress/auto-scroll/progress ring, matched-geometry zoom transitions, native `.searchable()` on Quran page (matches Dua page UX). Hadith (34,178 entries) with SQLite FTS. Gamification: hasanat (20 award types with HasanatTracker dedup), streaks (5 types), 24 achievements, levels 1-10. Widgets (lock screen + streak), App Group sharing, Spotlight indexing. 5 App Intents wired to real data. Live Activities: prayer countdown on lock screen + Dynamic Island (ActivityKit), lifecycle wiring in SafaApp. Haptics, skeleton loaders, degraded state banners, theme/dark mode foundation. JSON/CSV data export, per-category deletion. Analytics schema, privacy-safe logging. Onboarding 3-page flow with location intelligence. Ramadan mode with iftar platter/prayer progress/fasting tracker. Premium UI: nav bar material morph, bottom sheet standardization, hero card compression, sticky context chip, screen state transitions (ErrorView), zero-state quality pass, motion tokens (SafaMotion), elevation/surface tokens (SafaElevation/SafaSurface). Location settings correctness: saved coords on cold start, calculationMethod consolidated to PreferencesManager, madhab wired into PrayerTimeCalculator. Localization: 5 locales configured, ~960 strings in String Catalog (213 bulk-added Feb 11), all user-facing strings registered. Learning scaffolding (feature-flagged). Chat scaffolding (feature-flagged). Family circle scaffolding. UI polish (contextual nav, adaptive tab bar, home intent resolver, resume card). Dark mode (Quran surface, screen-by-screen pass, banners/alerts/sheets). Search unification + share card upgrade + invite flow. Test coverage backfill (Domain 90%+, Repositories 80%+, conformance cleanup).

---

## Launch Sequence (Prioritized)

Tasks ordered by: launch-blocking status, end-user value, what they unblock.

### Phase 1: Accessibility & Layout Confidence
**Why first:** Apple rejects apps with broken accessibility. Layout bugs on small/large screens generate 1-star reviews immediately. These are non-negotiable for a quality v1.

- [x] Dynamic Type scaling audit — SafaTypography uses UIFontMetrics, 15 hardcoded sizes replaced, 5 @ScaledMetric containers, DT caps on grids
- [ ] iPhone SE + Pro Max boundary testing — catch layout overflow/clipping on extreme sizes
- [x] VoiceOver rotor flow for Quran navigation — critical for visually impaired Muslims (underserved audience)
- [x] Accessibility labels on 13 high-traffic screens + View+Accessibility.swift helpers + 21 tests
- [x] UI tests for large content size + VoiceOver labels — 18 DynamicTypeScalingTests + VoiceOver label tests
- [x] Minimal Motion profile — 18 ReduceMotionTests verifying SafaMotion tokens + critical animation audit

### Phase 2: Widgets & Platform Integration
**Why second:** Widgets are the #1 daily engagement driver. Lock screen prayer times is a killer feature vs competitors. Code is complete — just needs device verification.

- [ ] Widgets (Lock Screen, Home Screen, interactive, StandBy) — verify rendering, tap targets, data freshness
- [ ] Spotlight search result tap → navigation — verify deep links resolve to correct screens
- [ ] Siri Shortcuts invocation testing — verify 5 wired intents work end-to-end
- [ ] Focus Mode integration — low effort, niche value but quick win
- [x] Platform integration verification tests — 40 tests covering widget data, Spotlight parsing, Siri intents, Focus modes

### Phase 3: Audio (Core Islamic Experience)
**Why third:** Hearing the adhan is deeply important culturally. Silent prayer notifications feel incomplete. One bundled adhan + AVFoundation wiring enables the core sound experience.

- [ ] Bundle Maghrib adhan audio file — ship one high-quality adhan sound
- [ ] Connect audio player to AVFoundation — wire existing AudioService to real playback
- [ ] Dua audio pronunciations (needs audio files) — defer if files unavailable, wire player now

### Phase 4: Live Activities
**Why fourth:** Highly visible differentiating feature. Prayer countdown on Dynamic Island / lock screen keeps users aware without opening the app. Strong retention signal.

- [x] Live Activities / Dynamic Island prayer countdown — ActivityKit integration, lock screen + Dynamic Island views, lifecycle wiring

### Phase 5: Performance
**Why fifth:** Slow launch = uninstall. Profile after features are stable, not before. Quick wins likely in lazy loading and deferred init.

- [ ] AppLaunchPerformanceTests (target < 2s)
- [ ] Memory profiling (target < 200MB)
- [ ] Precompute home context for instant rendering
- [ ] Battery impact test

### Phase 6: TestFlight & Launch
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

---

*Last Updated: February 11, 2026*
