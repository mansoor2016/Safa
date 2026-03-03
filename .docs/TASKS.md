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
| M | Dua audio pronunciations (needs audio files) — defer if unavailable |
| L | RTL audit (Arabic UI flow, mirrored icons, mixed-script Dynamic Type) (partial — layout direction + VoiceOver done across 9 views, icon mirroring + full Dynamic Type audit remaining) |
| M | Widget extension String Catalog + shared localized keys (partial — localized prayer names via App Group, full widget String Catalog remaining) |
| XL | Translation content (ayah/hadith/dua tables, language pack download) |
| M | Localization validation (pseudo-localization, pluralization rules, screenshot coverage) |
| L | Background audio adhan playback — AVAudioSession `.playback` bypasses silent switch, fallback when terminated |
| L | Women-focused prayer/fasting mode — period-aware prayer logging, optional reminder pause, and fiqh-safe UX copy |
| L | Mosque timetable integration (Iqamah/Jama'ah support) — let users follow local mosque times alongside calculated times |
| M | Progressive Learn rollout — ship ready tracks incrementally instead of keeping all Learn content gated |
| M | More prominent non-adhan prayer notifications — current default system sound is too brief and easy to miss. Custom notification sounds (longer/distinctive), time-sensitive interruption level, follow-up reminder before window ends. relevanceScore=1.0 already added. |
| L | Monetization strategy — research and implement sustainable revenue model (freemium tiers, Pro subscription, tip jar, or similar). Define free vs paid feature split, StoreKit 2 integration, paywall UI, restore purchases, receipt validation (partial — StoreKit 2 voluntary subscriptions implemented: CommunitySupportCard, App Store Connect products, custom app icons as subscriber perk. Remaining: receipt validation, TestFlight sandbox testing, App Review submission) |
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

**v1.4–v2.7:** Prayer engine, Live Activity + widgets, Qibla, Quran reader (transliteration for 6,236 ayahs), AI companion (Foundation Models + iOS 26 gate), progress dashboard, Settings refactor, location intelligence, os.Logger + MetricKit. Daily verse expansion (600), dua content audit (57→120), RTL + VoiceOver (9 views), in-app language (9 languages). Prayer grace window, Dashboard redesign, Maghrib-aware day boundary, rak'ah breakdown, Ramadan NextPrayerCard. App Store submitted. **v2.8–v2.9:** App Store rejection fix (location flow), onboarding redesign (4 pages), voluntary subscriptions (CommunitySupportCard, custom app icons), preview asset fixes. **v2.10:** Stale PrayerView fix (scenePhase observer, forceFresh GPS, re-entrancy guard), duplicate Live Activity fix (deterministic reconcile, orphan cleanup), deep link/Spotlight pure resolvers, midnight date staleness (significantTimeChangeNotification), loop-based reload coalescing, GPS throttle (shouldRefresh helper), fix 4 SIGABRT test crashes (remove @Observable from FeatureFlags, typed [Destination] array in AppRouter).

---

*Last Updated: March 3, 2026 — Condensed completed log (v1.4–v2.7 summary, v2.8–v2.10 detail).*
