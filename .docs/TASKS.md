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

**v1.4–v2.0:** Prayer engine (adhan-swift v1.5.0, notification actions, wudhu reminders, adhan silent mode, grace window), Live Activity + widgets (reliability, staleness fix, boundary entries, Dynamic Island, StandBy), Qibla compass, Quran reader (scroll unification, transliteration for 6,236 ayahs), AI companion (Foundation Models + iOS 26 gate, Dua RAG, citation validation, chat UI, Siri intent, input safety, UX hardening), progress dashboard (real data + calendar + charts), Settings refactor, location intelligence, hasanat dedup fix, in-app review prompt, data deletion gaps, os.Logger + MetricKit. App Store submission + TestFlight release gate passed. Memory profiling + battery impact test (verified across TestFlight devices). **v2.3–v2.5:** Daily verse expansion (600 across 113 surahs), dua content audit (57→120 duas, 21 categories), RTL + VoiceOver accessibility (9 views), in-app language override (9 languages), 44 translation fixes. **v2.6:** 15-minute prayer grace window (all surfaces), Progress Dashboard redesign. **v2.7:** Maghrib-aware Islamic day boundary, Home declutter (interactive Khatm card), unified prayer progress style, Live Activity fixes, rak'ah prayer breakdown (madhab-aware before/after Fard split, long-press toggle, 40 correctness tests), Ramadan tab NextPrayerCard (replaces duplicate Suhoor/Iftar platter). App Store Connect submitted. **v2.8–v2.8.1:** App Store rejection fix (location permission flow), surah list row wrapping fix, madhab picker label cleanup, removed non-functional accessibility toggles, onboarding redesign (3→4 pages with separate About and Location). **v2.9:** Voluntary subscriptions (CommunitySupportCard, App Store Connect products, custom app icons as subscriber perk), preview asset fixes (imageset Contents.json, LFS pointers). **v2.10:** Fix stale PrayerView on foreground resume (@MainActor isolation, scenePhase observer, forceFresh GPS, re-entrancy guard with needsReload), fix duplicate Live Activities (deterministic reconcileActivities, orphan cleanup on all early exits, boundary loop continuation), extract deep link and Spotlight parsing into pure resolvers.

---

*Last Updated: March 2, 2026 — Appended v2.8–v2.10 completed work (App Store fixes, subscriptions, Live Activity dedup, stale PrayerView fix, deep link refactor).*
