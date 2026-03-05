# Safa - Task List

## Workflow

1. **Plan first** — sketch the UI approach and consider alternatives before writing code. Show iterations.
2. **TDD** — write failing tests that define the expected behavior, then implement until they pass.
3. **Verify** — use `/build` and `/test` skills (never raw xcodebuild).

Effort: **S** (<2h) · **M** (half day) · **L** (1-2 days) · **XL** (3+ days)

---

## P1 — Near-Term

| Effort | Task |
|--------|------|
| XL | Translation content (ayah/hadith/dua tables, language pack download) |
| M | Localization validation (pseudo-localization, pluralization rules, screenshot coverage) |
| L | Background audio adhan playback — AVAudioSession `.playback` bypasses silent switch, fallback when terminated |
| L | Women-focused prayer/fasting mode — period-aware prayer logging, optional reminder pause, and fiqh-safe UX copy |
| L | Mosque timetable integration (Iqamah/Jama'ah support) — let users follow local mosque times alongside calculated times |
| M | Progressive Learn rollout — ship ready tracks incrementally instead of keeping all Learn content gated |
| L | Monetization remaining — receipt validation, TestFlight sandbox testing, App Review submission (StoreKit 2 voluntary subscriptions, CommunitySupportCard, custom app icons already shipped) |
| XL | Learning section — build out the Learn tab with structured Islamic education content (tracks, lessons, quizzes). Content authoring pipeline, progress tracking, offline support. Currently feature-flagged as disabled |

## P2 — Later

| Effort | Task |
|--------|------|
| L | Audio download/caching for recitations |
| L | Resumable audio downloads, offline queue migration to Core Data |
| M | WCAG AA color contrast verification |
| M | High-contrast mode refinement |
| S | `os_signpost` on hot paths — prayer calc, Quran load, Core Data fetches |
| M | Remote feature flags via CloudKit — extend `FeatureFlags` to read from public DB |
| M | On-device event logging — screen views, key actions, aggregate for insights |
| S | `URLSessionTaskMetrics` network monitoring |
| M | Additional App Intents (PlayAdhan, OpenSurah, StartTasbeeh, location automations) |
| L | Weekly reflection summary (achievements removed, progress dashboard shipped) |
| M | Prayer quality logs (on-time, congregation, focus rating) |
| L | Manual backup/restore |
| L | Mosque Mode (geofence-based) |
| XL | watchOS companion app |
| M | Assistive Access Mode (simplified 3-tab layout) |
| M | Core Data fetch + LLM inference memory optimization |
| S | Islamic event notification deep links |
| M | In-app feedback flow — lightweight bug/feedback intake for better beta triage |
| L | Advanced memorization tools — spaced repetition flow for Quran review with lightweight daily sessions |
| L | Family Circle MVP — opt-in family sharing for streak/prayer/Quran progress with strict privacy controls (no leaderboards) |

---

## Completed

**v1.4–v2.7:** Prayer engine, Live Activity + widgets, Qibla, Quran reader (6,236 ayah transliteration), AI companion (Foundation Models, iOS 26 gate), progress dashboard, Settings refactor, location intelligence, os.Logger + MetricKit, daily verse (600), dua audit (57→120), RTL + VoiceOver (9 views), in-app language (9 langs), prayer grace window, dashboard redesign, Maghrib-aware day boundary, rak'ah breakdown, Ramadan NextPrayerCard, App Store submitted. **v2.8–v2.9:** App Store rejection fix, onboarding redesign (4 pages), voluntary subscriptions + custom app icons, preview asset fixes. **v2.10:** Stale PrayerView fix (scenePhase + forceFresh GPS + re-entrancy guard), duplicate Live Activity fix, deep link/Spotlight resolvers, midnight staleness fix, reload coalescing, GPS throttle, 4 SIGABRT crash fixes. **v2.11–v2.12:** Location + notification permission-denied UX (banners, disabled sub-toggles, forward-nav guard), privacy policy update, license change (Apache 2.0 → CC BY-NC-SA 4.0), Speech framework removal (unblock Xcode Cloud), README corrected, in-app prayer toast reminders (ending-soon + daily summary, configurable threshold, 23 tests). **v2.13:** Widget String Catalog (68 keys × 8 langs), RTL audit (icon mirroring, Dynamic Type, FlowLayout), localization audit (~76 keys × 8 langs, String(localized:) wrappers, localizedDisplayName, Eid banner, Dua Arabic fallback), fasting countdown grace periods (suhoor 15 min / iftar 30 min, TimelineView re-eval, DisplayState enum, 17 tests), Eid share localization (10 keys × 8 langs), Turkish-safe casing, atomic xcstrings script, single-turn AI chat (fresh conversation per interaction).

---

*Last Updated: March 5, 2026 — Condensed completed section, added single-turn AI chat fix.*
