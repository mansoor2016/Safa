# Safa - Task List

## Verification
```bash
xcodebuild -scheme Safa -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
xcodebuild -scheme Safa -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SafaTests -parallel-testing-enabled NO test
```

---

## Completed

Foundation, Core Data, Dependencies, AppRouter, design system, disabled feature pattern, location intelligence. Prayer times (7 methods), Qibla compass, prayer logging with optimistic undo, notification scheduling (single NotificationScheduler). Full Quran (6,236 ayahs) with FTS search, surah reader with bookmarks/reading progress/auto-scroll/progress ring, matched-geometry zoom transitions, native `.searchable()` on Quran page (matches Dua page UX), Quran deep link from Home resume card. Hadith (34,178 entries) with SQLite FTS. Gamification: hasanat (19 award types with HasanatTracker dedup), streaks (5 types), 24 achievements, levels 1-10. Widgets (lock screen + streak), App Group sharing, Spotlight indexing (SpotlightIndexService, 5 content types, deep links). 5 App Intents wired to real data (IntentHelpers). Live Activities: prayer countdown on lock screen + Dynamic Island (ActivityKit), lifecycle wiring in SafaApp. Haptics, skeleton loaders, degraded state banners, theme/dark mode foundation. JSON/CSV data export, per-category deletion. Analytics schema, privacy-safe logging. Onboarding 3-page flow with location intelligence. Ramadan mode with iftar platter/prayer progress/fasting tracker. Premium UI: nav bar material morph, bottom sheet standardization, hero card compression, sticky context chip, screen state transitions (ErrorView), zero-state quality pass, motion tokens (SafaMotion), elevation/surface tokens (SafaElevation/SafaSurface). Location settings correctness: saved coords on cold start, calculationMethod consolidated to PreferencesManager, madhab wired into PrayerTimeCalculator. Localization: 5 locales configured, ~960 strings in String Catalog (213 bulk-added Feb 11), all user-facing strings registered. Learning scaffolding (feature-flagged). Chat scaffolding (feature-flagged). UI polish (contextual nav, adaptive tab bar, home intent resolver, resume card adjacent to banners). Dark mode (Quran surface, screen-by-screen pass, banners/alerts/sheets). Search unification + share card upgrade + invite flow. Test coverage backfill (Domain 90%+, Repositories 80%+, conformance cleanup). Accessibility: Dynamic Type audit (UIFontMetrics, 15 sizes replaced, 5 @ScaledMetric, DT caps), VoiceOver rotor for Quran, accessibility labels (13 screens + helpers + 21 tests), large content + VoiceOver UI tests (18 DynamicTypeScalingTests), Minimal Motion profile (18 ReduceMotionTests). Platform integration: Focus Mode (FocusModeService + SleepFocusService, 6 notification categories), Siri Shortcuts (5 intents via IntentHelpers), platform verification tests (40 tests). Audio pipeline: 11 adhan files bundled (35 MB), AudioPlayerService (AVFoundation, interrupt handling, remote controls), audio background mode. Performance: AppLaunchPerformanceTests (< 2s target), home context precomputation. Dua favourites (quick access button + heart toggle), in-app review prompt (exponential backoff), banner visibility logic (HomeBannerResolver), developer settings (UX variant toggles, reset onboarding). Dua data migration to bundled JSON (57 duas across 12 categories, DuaDataLoader, DuaCategoriesViewModel, ~27 new authentic duas with Arabic/transliteration/translation/sources), Ramadan duas loaded from repository with occasion filter, Islamic event notification message polish. CloudKit/iCloud stripped (local-only Core Data). Family Circle feature removed (not needed for v1 or post-v1). Backwards compatibility verified: build + test matrix passes on iOS 17.5 (SE), iOS 18.6 (Pro Max), iOS 26 (17 Pro). Location change detection (30km threshold, adaptive 5/15min throttle, foreground GPS check → recalculate prayers/widgets/Live Activity/notifications + toast), autoUpdateLocationForPrayers preference + Settings toggle. Onboarding polish: CLGeocoder for real city names, vertical centering on pages 2/3, shorter Mosque Mode subtitle, removed "invited by a friend" toggle. Onboarding/notification flow fixes: master notification toggle kill-switch (cancels before auth check), tri-state launch prevents onboarding flash, skip preserves location-inferred values, notifications scheduled immediately after onboarding, Settings deep-link for denied location, Settings toggle sequential save→act with toast, testable helpers (NotificationSchedulerHelpers, NotificationToggleHandler, LaunchStateResolver, OnboardingHelpers). Review prompt fix: switched to Fallback color tokens (invisible content bug), 15-min minimum sleep before check, auto-opt-out on submit. Evening dhikr time-gating (Asr-based + 5 PM fallback, DailyGoalsHelpers). Qibla compass: live heading via Combine publishers, location source indicator, Settings deep-link, heading smoothing/wrap-around, QiblaCompassHelpers extracted (25 tests), Refresh Location button. Quick-action card sizing parity (fixed 28pt icon frame). Prayer settings expanded (Method + Madhab + Adjustments), real per-prayer minute offsets in UserPreferences + PrayerRepository, Settings/Prayer sync via shared PreferencesManager. Notification denied warning on onboarding + Settings with auto-dismiss on return from iOS Settings. Onboarding layout rewrite: removed GeometryReader/Spacer jitter, unified bottom bar, scoped animations. Quran tab first-load fix (synchronous ViewModel init). Quran settings gear (font, auto-scroll — syncs with global Settings). Home spacing fix (empty contextualReminders no longer creates phantom gap). Dead settings cleanup: removed "Show Arabic Text" and "Show Transliteration" toggles (saved but never read by any rendering code). Auto-scroll fix: AyahReaderView was reading from wrong UserDefaults key, now reads from PreferencesManager. Cross-surface settings sync tests (6 new PreferencesManager tests). Foreground notification fix (delegate for banner+sound), prayer notification 14-day scheduling with background refresh, test notification button in developer settings. Home Screen Quick Actions restored (Prayer Times + Qibla). Qibla compass redesign (card-based layout, responsive sizing via GeometryReader, extracted QiblaArrow/QiblaCompassWheel/QiblaStatusBanner/QiblaAlignmentIndicator, single priority-resolved status banner, context-aware Done button). Tasbeeh counter redesign (unified TasbeehDial, card layout, TasbeehHelpers extracted with 15 tests). Ramadan Qada reminder (one-off post-Eid alert for missed fasts, RamadanQadaReminderService with 18 correctness tests). Onboarding footer ergonomics (safeAreaInset placement, 32pt insets, 560pt max width, 44pt tap targets, ultraThinMaterial surface). Release script (bin/release couples version + git tag). 2292 tests pass on iOS 17/18/26 full matrix.

---

## Launch Sequence (Prioritized)

Tasks ordered by: launch-blocking status, end-user value, what they unblock.

### Phase 1: Accessibility & Layout Confidence
**Why first:** Apple rejects apps with broken accessibility. Layout bugs on small/large screens generate 1-star reviews immediately. These are non-negotiable for a quality v1.

- [x] iPhone SE + Pro Max boundary testing — catch layout overflow/clipping on extreme sizes
  - Fixed EidGreetingCard overflow on 375pt screens (`.frame(width:)` → `.frame(maxWidth:)`)
  - Fixed CompassView hardcoded sizes — now derives from `@ScaledMetric compassSize`
  - Build-verified on iPhone 16e (375pt), iPhone 17 Pro (393pt), iPhone 17 Pro Max (430pt)
- [x] Backwards compatibility testing — verified builds and tests pass on iOS 17, 18, and 26 simulators
  - Deployment target lowered from 26.2 → 17.0 (all APIs are iOS 17+ compatible)
  - AI Companion (Foundation Models) already gated with `#available(iOS 18.4, *)`
  - Matrix build: iOS 17.5 SE, iOS 18.6 Pro Max, iOS 26 17 Pro — all pass
  - Matrix test: 2098 tests on iOS 17.5/18.6, 390 on iOS 26 — all pass, 0 failures

### Phase 2: Widgets & Platform Integration
**Why second:** Widgets are the #1 daily engagement driver. Lock screen prayer times is a killer feature vs competitors. Code is complete — needs device verification for visual/interaction aspects.

- [ ] Widgets (Lock Screen, Home Screen, interactive, StandBy) — verify rendering, tap targets, data freshness *(manual device test)*
- [ ] Spotlight search result tap → navigation — verify deep links resolve to correct screens *(manual device test)*
- [ ] Siri Shortcuts invocation testing — verify intents work end-to-end *(manual device test)*

### Phase 3: Audio (Core Islamic Experience)
**Why third:** Hearing the adhan is deeply important culturally. Silent prayer notifications feel incomplete. Audio pipeline is fully implemented — needs device verification.

- [ ] Adhan silent mode awareness — inline helper text below adhan sound picker in settings ("Adhan plays as a notification sound. Make sure Silent Mode is off and ringer volume is up to hear it.") + one-time dismissible tip/toast on first adhan enable
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

### Audio Expansion
**Why deferred:** Full recitation audio requires large downloads, caching infrastructure, and offline queue. Ship basic adhan in v1, expand audio post-launch.

- [ ] Background audio adhan playback — silent notification triggers AVAudioSession `.playback` (bypasses silent switch) instead of relying on notification sound; graceful fallback when app is terminated by iOS
- [ ] Critical alert entitlement — apply to Apple for `.criticalAlert` permission so adhan notification sounds override silent mode natively
- [ ] Audio download/caching for recitations
- [ ] Resumable audio downloads, offline queue migration to Core Data

### Accessibility Polish
**Why deferred:** Core accessibility (Dynamic Type, VoiceOver, SE/Pro Max) ships in v1. These are refinements.

- [ ] WCAG AA color contrast verification
- [ ] High-contrast mode refinement

### Native Observability
**Why deferred:** App works fine without it. These are operational improvements that become valuable once real users are on the app — helps diagnose crashes, understand usage, and toggle features remotely.

- [ ] `os.Logger` across features — replace any remaining `print()`, structured leveled logging with per-feature categories (`prayer`, `quran`, `coredata`, etc.)
- [ ] MetricKit subscriber — crash diagnostics (`MXCrashDiagnostic`), hang reports (`MXHangDiagnostic`), launch time metrics, delivered by Apple within 24h with no backend needed
- [ ] `os_signpost` on hot paths — instrument prayer time calculation, Quran page load, Core Data fetches for Instruments profiling and MetricKit aggregation
- [ ] Remote feature flags via CloudKit — extend existing `FeatureFlags` to read from a CloudKit public database record, polled at launch, toggle features without app updates
- [ ] Lightweight on-device event logging — screen views, key actions (prayer logged, Quran page read, undo tapped) to Core Data, aggregate for usage insights
- [ ] `URLSessionTaskMetrics` network monitoring — capture DNS/TLS/request durations for any API calls, useful when network-dependent features are added

---

## Post-Launch Roadmap

- [ ] Additional App Intents (PlayAdhan, OpenSurah, StartTasbeeh, location automations)
- [ ] Achievement badge assets + weekly reflection summary + progress dashboard
- [ ] Quran: transliteration data
- [ ] Prayer quality logs (on-time, congregation, focus rating)
- [ ] Ringer mode detection for Smart Adhan (no public iOS API)
- [ ] Manual backup/restore
- [ ] Mosque Mode (geofence-based)
- [ ] watchOS companion app
- [ ] Assistive Access Mode (simplified 3-tab layout)
- [ ] Core Data fetch + LLM inference memory optimization
- [ ] Islamic event notification deep links — tap notification to open Quranic reference (e.g., Surah Al-Qadr 97:3 for Laylat al-Qadr) or dedicated event info screen
- [ ] Update appStoreURL with real App ID

---

*Last Updated: February 13, 2026 (added Native Observability section to post-v1 fast follows)*
