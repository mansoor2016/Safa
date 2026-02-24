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
| S | App Store Connect submission *(manual)* |
## P1 — Near-Term

| Effort | Task |
|--------|------|
| S | Memory profiling (target < 200MB) *(manual — Instruments)* |
| S | Battery impact test *(manual — Live Activity running)* |
| M | Dua audio pronunciations (needs audio files) — defer if unavailable |
| S | Audio playback verification *(manual device test)* |
| L | RTL audit (Arabic UI flow, mirrored icons, mixed-script Dynamic Type) (partial — layout direction + VoiceOver done across 9 views, icon mirroring + full Dynamic Type audit remaining) |
| M | Widget extension String Catalog + shared localized keys (partial — localized prayer names via App Group, full widget String Catalog remaining) |
| XL | Translation content (ayah/hadith/dua tables, language pack download) |
| M | Localization validation (pseudo-localization, pluralization rules, screenshot coverage) |
| L | Background audio adhan playback — AVAudioSession `.playback` bypasses silent switch, fallback when terminated |
| S | Critical alert entitlement — apply to Apple for `.criticalAlert` permission (process, not code) |
| L | Women-focused prayer/fasting mode — period-aware prayer logging, optional reminder pause, and fiqh-safe UX copy |
| L | Mosque timetable integration (Iqamah/Jama'ah support) — let users follow local mosque times alongside calculated times |
| M | Progressive Learn rollout — ship ready tracks incrementally instead of keeping all Learn content gated |
| M | More prominent non-adhan prayer notifications — current default system sound is too brief and easy to miss; users who enable prayer notifications want to be alerted. Explore longer/custom notification sounds, repeated alerts, or critical alert style to make non-adhan notifications harder to ignore. relevanceScore=1.0 already added. |
| L | Monetization strategy — research and implement sustainable revenue model (freemium tiers, Pro subscription, tip jar, or similar). Define free vs paid feature split, StoreKit 2 integration, paywall UI, restore purchases, receipt validation |
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
| M | Rak'ah prayer table — static table or contextual display for current prayer |
| M | In-app feedback flow — lightweight bug/feedback intake for better beta triage |
| L | Advanced memorization tools — spaced repetition flow for Quran review with lightweight daily sessions |
| L | Family Circle MVP — opt-in family sharing for streak/prayer/Quran progress with strict privacy controls (no leaderboards) |

---

## Completed

**v1.4–v1.5:** Live Activity reliability, widget staleness fix, prayer time accuracy (adhan-swift v1.5.0), Settings refactor, notification actions, TestFlight beta, adhan silent mode, Qibla compass polish, location geobox tightening, Ramadan navigation/copy, wudhu reminders, prayer stepper redesign, os.Logger + MetricKit, language settings, share banner fix, adhan sound fix (AAC→PCM), dead flags cleanup, Quran scroll unification, hasanat dedup exploit fix, in-app review prompt, large widget removed, progress dashboard (real data + calendar + charts), achievements removed, data deletion gaps fixed. **v1.6–v1.8:** AI companion Phase 0 pipeline (behind flag), Phase 1 (Foundation Models + iOS 26 gate, Dua RAG, citation validation, chat UI, Siri intent, QA/red-team benchmarks, topic detection, input safety). **v2.0:** AI UX hardening (stop/abort, error retry, cross-tab nav, accessibility labels, weak FoundationModels link), migration safety (per-message decode, auto-recovery), conversation switch safety, feature-claim parity audit (App Store listing + README aligned). **v2.0 polish:** Default MWL→Makkah (AppDefaults + LocationInferenceService + beta migration), Taraweeh counter fix (step-by-2, presets 8/12/20, per-day persistence), Ramadan post-Iftar suhoor countdown (subdued style), Quran transliteration (6,236 ayahs populated, reader toggle, font settings, backward-compat decoder). Release gate passed (20+ beta users, no major issues). **Post-v2.0 polish:** Ramadan prayer timetable (PrayerTimePreviewCard between iftar platter and progress), adhan onboarding (toggle + picker on page 2, saved to prefs), Mosque Mode removed from onboarding, notification relevanceScore=1.0. **v2.3:** Daily verse expansion (600 curated across 113 surahs), collapsible verse card, dhikr reminder cards removed. **v2.4:** Dua content audit (57→120 duas, 12→21 categories — istikharah, illness, parents, marriage, children, knowledge, hajj, weather, gratitude; existing categories expanded with prayer/daily/food/sleep/protection/travel/anxiety gaps filled). **v2.5:** RTL layout direction + VoiceOver accessibility (9 views), in-app language override (Settings picker + onboarding, 9 languages, reactive locale, widget/live activity/notification localization), 44 translation fixes (Turkish İmsak→Sabah namazı, Hasanat in native scripts, Urdu Settings consistency, French Nisab spelling). **v2.6:** 15-minute grace window ("Prayer time" across in-app, widgets, Live Activity, Dynamic Island, StandBy — with Codable backwards compat, stale data cleanup, boundary timeline entries), Progress Dashboard redesign (prayer consistency focus), Ramadan dua card subtitle change.

---

*Last Updated: February 24, 2026 — Added v2.6 completions (grace window, Progress Dashboard redesign, dua card subtitle).*
