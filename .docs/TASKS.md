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
| M | Feature-claim parity audit for launch: align app behavior with QA/listing/docs (especially Learn/AI/Progress and "all features available" wording) |
| M | Release gate verification: full checks + pre-release smoke/boundary/manual checklist from `.docs/TEST.md` before App Store upload |
| L | App Store screenshots + preview video capture and final listing polish *(manual)* |
| S | App Store Connect submission *(manual)* |
## P1 — Near-Term

| Effort | Task |
|--------|------|
| S | Memory profiling (target < 200MB) *(manual — Instruments)* |
| S | Battery impact test *(manual — Live Activity running)* |
| M | Dua audio pronunciations (needs audio files) — defer if unavailable |
| S | Audio playback verification *(manual device test)* |
| L | RTL audit (Arabic UI flow, mirrored icons, mixed-script Dynamic Type) |
| M | Widget extension String Catalog + shared localized keys |
| XL | Translation content (ayah/hadith/dua tables, language pack download) |
| M | Localization validation (pseudo-localization, pluralization rules, screenshot coverage) |
| L | Background audio adhan playback — AVAudioSession `.playback` bypasses silent switch, fallback when terminated |
| S | Critical alert entitlement — apply to Apple for `.criticalAlert` permission (process, not code) |
| L | Women-focused prayer/fasting mode — period-aware prayer logging, optional reminder pause, and fiqh-safe UX copy |
| L | Mosque timetable integration (Iqamah/Jama'ah support) — let users follow local mosque times alongside calculated times |
| M | Progressive Learn rollout — ship ready tracks incrementally instead of keeping all Learn content gated |
| S | Ramadan page prayer timetable — show the daily prayer schedule (same as Prayer page) on the Ramadan screen so users can see prayer times alongside fasting info |
| S | Adhan sound selection in onboarding — present adhan toggle and sound picker during onboarding (currently only available in Settings post-onboarding) |
| S | Remove "coming soon" features from onboarding — remove Mosque Mode preview and any disabled-feature placeholders from onboarding flow; onboarding should only show functional options |
| M | More prominent non-adhan prayer notifications — current default system sound is too brief and easy to miss; users who enable prayer notifications want to be alerted. Explore longer/custom notification sounds, repeated alerts, or critical alert style to make non-adhan notifications harder to ignore |

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
| L | Weekly reflection summary (achievements removed, progress dashboard shipped) |
| M | Quran: transliteration data |
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

Live Activity reliability + staleness fix (v1.4.1–v1.4.3), widget stale prayer fix, prayer time accuracy (adhan-swift v1.5.0), calculation method visibility, Settings refactor, notification action buttons, developer settings, TestFlight beta (v1.5.0), release notes in version bumps, adhan silent mode awareness, convention clarity disclaimer (v1.5.2), location fallback fix, Eid/Ramadan copy cleanup, test tooling. Qibla compass polish + location geobox tightening. Ramadan navigation consistency + copy polish. Wudhu reminder notifications (v1.5.3). System Status removal (v1.5.4), prayer progress stepper redesign (v1.5.5). os.Logger structured logging (v1.5.6), MetricKit diagnostics subscriber (v1.5.7). Language settings UI with QuranTranslation picker (v1.5.8). Real TestFlight link + unified downloadURL across all share surfaces. Share banner dismissal fix (completionWithItemsHandler), duplicate review dialog removal, adhan notification sound fix (AAC→PCM re-encode), dead UX flags cleanup (inline header + adaptive tab bar), Quran scroll behavior unified with Duas/Home, dead feature flags removal, notification settings footer cleanup (v1.5.9). Hasanat dedup exploit fix (5 call sites routed through HasanatTracker, NSLock serialization, award-before-mark with rollback), MoreView progress rows combined, App Store ID set (6759136442), InviteFriends test fix (downloadURL vs appStore), lesson perfect score aligned to 100%. In-app review prompt (exponential backoff + action-triggered + UI polish), large widget removed (v1.5.10). Progress Dashboard wired to real data (daily hasanat recording, live repo queries for prayers/Quran/lessons, monthly prayer consistency calendar, weekly activity chart), TasbeehCounterView multi-cycle session fix, achievements system removed entirely (badges felt inappropriate for faith app — hasanat/streaks kept), data deletion gaps fixed (hasanat tracker keys + legacy achievements key), month boundary bug fixed, dead progressDashboard feature flag removed.

---

*Last Updated: February 17, 2026 — Progress Dashboard live, achievements removed, review prompt shipped, data deletion + month boundary fixes*
