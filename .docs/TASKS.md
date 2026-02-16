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
## P1 — Near-Term

| Effort | Task |
|--------|------|
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
| L | App Store screenshots, description, preview video (partial — listing copy + screenshot/video guide done in `APP_STORE_LISTING.md`, screenshots + video still needed) *(manual)* |
| S | App Store Connect submission *(manual)* |

---

## Completed

Live Activity reliability (v1.4.3), widget stale prayer fix (v1.4.1), prayer time accuracy with adhan-swift (v1.5.0), calculation method visibility, Settings refactor, notification action buttons, developer settings, Package.resolved, draft icon cleanup, TestFlight beta (v1.5.0 build 14), Live Activity staleness fix (v1.5.1), release notes in version bumps, adhan silent mode awareness, convention clarity disclaimer (v1.5.2), location fallback fix, Eid/Ramadan copy cleanup, test tooling accuracy. Qibla compass polish (Canvas tick marks, semibold upright cardinals, thicker ring/arrow, instruction text under title), tightened location geoboxes (Qatar/UAE/Kuwait/SG/MY/ID), fallback bounding box tests, compass wheel logic tests, CalculationMethod shortDisplayName tests. Ramadan navigation consistency (conditional tab switch vs push, injectable isRamadanActive for tests), copy polish ("No ads", Qibla instruction clarified). Wudhu reminder notifications (opt-in toggle + 5/10/15/20 min picker, generalReminder category, dynamic daysAhead for 64-notification limit, empty-enabledPrayers cancellation bugfix).

---

*Last Updated: February 16, 2026 — Wudhu reminder feature completed, task audit*
