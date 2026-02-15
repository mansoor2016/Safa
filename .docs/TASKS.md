# Safa - Task List

## Workflow

1. **Plan first** — sketch the UI approach and consider alternatives before writing code. Show iterations.
2. **TDD** — write failing tests that define the expected behavior, then implement until they pass.
3. **Verify** — use `/build` and `/test` skills (never raw xcodebuild).

Effort: **S** (<2h) · **M** (half day) · **L** (1-2 days) · **XL** (3+ days)

---

## P0 — Ship Next

| Effort | Task |
|--------|------|
| L | App Store screenshots, description, preview video (partial — listing copy + screenshot/video guide done in `APP_STORE_LISTING.md`, screenshots + video still needed) |
| S | App Store Connect submission |

## P1 — Near-Term

| Effort | Task |
|--------|------|
| M | Qibla UX clarity — improve visual guidance (arrow/Kaaba semantics, clearer alignment state) |
| S | Ramadan navigation consistency — standardize entry behavior to follow Prayer tab flow |
| S | Convention clarity/disclaimer — messaging that timings vary by method/school/local mosque |
| M | Wudhu reminder (default off) — configurable notification 15 min before prayer, global + per-prayer controls, tests |
| S | Memory profiling (target < 200MB) *(manual — Instruments)* |
| S | Battery impact test *(manual — Live Activity running)* |
| M | Dua audio pronunciations (needs audio files) — defer if unavailable |
| S | Audio playback verification *(manual device test)* |
| L | Language settings UI (App Language + Content Language + fallback chain) |
| L | RTL audit (Arabic UI flow, mirrored icons, mixed-script Dynamic Type) |
| M | Widget extension String Catalog + shared localized keys |
| XL | Translation content (ayah/hadith/dua tables, language pack download) |
| M | Localization validation (pseudo-localization, pluralization rules, screenshot coverage) |
| L | Background audio adhan playback — AVAudioSession `.playback` bypasses silent switch, fallback when terminated |
| S | Critical alert entitlement — apply to Apple for `.criticalAlert` permission (process, not code) |
| M | `os.Logger` across features — structured leveled logging per feature category |
| S | MetricKit subscriber — crash/hang/launch diagnostics from Apple |

## P2 — Later

| Effort | Task |
|--------|------|
| XL | Apple Foundation Models integration (requires iOS 26 SDK + device) |
| M | Response streaming + quality acceptance testing |
| L | Audio download/caching for recitations |
| L | Resumable audio downloads, offline queue migration to Core Data |
| M | WCAG AA color contrast verification |
| M | High-contrast mode refinement |
| S | `os_signpost` on hot paths — prayer calc, Quran load, Core Data fetches |
| M | Remote feature flags via CloudKit — extend `FeatureFlags` to read from public DB |
| M | On-device event logging — screen views, key actions, aggregate for insights |
| S | `URLSessionTaskMetrics` network monitoring |
| M | Additional App Intents (PlayAdhan, OpenSurah, StartTasbeeh, location automations) |
| L | Achievement badge assets + weekly reflection summary + progress dashboard |
| M | Quran: transliteration data |
| M | Prayer quality logs (on-time, congregation, focus rating) |
| L | Manual backup/restore |
| L | Mosque Mode (geofence-based) |
| XL | watchOS companion app |
| M | Assistive Access Mode (simplified 3-tab layout) |
| M | Core Data fetch + LLM inference memory optimization |
| S | Islamic event notification deep links |
| S | Update appStoreURL with real App ID |
| M | Rak'ah prayer table — static table or contextual display for current prayer |
| M | In-app feedback flow — lightweight bug/feedback intake for better beta triage |

---

## Completed

Live Activity reliability (v1.4.3 — auto-recover on launch/foreground, stale detection, reattach after restart, settings toggle, onboarding gate, boundary task cleanup, duplicate/orphan prevention), widget stale prayer times fix (v1.4.1). Prayer time accuracy (v1.5.0 — replaced custom calculator with adhan-swift, 389 accuracy tests, 5 regional methods, auto high-latitude rule, sunnah times), calculation method visibility (prayer time preview card, method description footer, location-based recommendations sheet), Settings refactor (extracted 6 standalone views, thin NavigationLink menu), notification action buttons (lock screen Mark as Prayed + Open Qibla, deferred log pattern, 33 regression tests), developer settings (triple-tap access in all builds), Package.resolved for Xcode Cloud, draft icon cleanup, beta build pushed (v1.5.0 build 14 to TestFlight). Live Activity staleness fix (v1.5.1 — 90s staleDate buffer, stale UI fallback on lock screen + Dynamic Island, 4 staleness tests), release notes in version bump commits (bin/release auto-generates changelog from git history). Adhan silent mode awareness (footer hint + one-time toast on first enable, gated on auth status, 4 tests).

---

*Last Updated: February 15, 2026 — Adhan silent mode awareness shipped, App Store listing copy drafted*
