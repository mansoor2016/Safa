# Location Settings Correctness - Implementation Plan

## Purpose
Fix correctness issues in location-driven prayer settings so app behavior is consistent after restart and user-configured preferences are reliably applied across Prayer, Home, Ramadan, and notification scheduling.

## Problem Summary
Current behavior has three correctness gaps:
1. Saved location can be bypassed after restart because location resolution may fall back to default coordinates (London) when no live GPS fix exists.
2. Calculation method persistence is split between `UserPreferences` and raw `UserDefaults` keys, causing drift between Settings and runtime consumers.
3. Madhab selection is persisted but not reliably applied to Asr calculation behavior.

## Objectives
1. Establish one canonical source of truth for prayer settings and saved location coordinates.
2. Ensure effective coordinates on app cold start prefer user-saved location over default fallback.
3. Ensure selected calculation method and madhab are applied consistently in all prayer-time consumers.
4. Remove raw-key drift by consolidating reads/writes to preference-backed settings with migration support.
5. Add regression coverage for restart behavior and settings propagation.

## Scope
### In Scope
- Prayer-time settings resolution path (coordinates, calculation method, madhab).
- Home/Prayer/Ramadan/NotificationScheduler consumers.
- Legacy key migration for `calculationMethod`.
- Unit/integration tests for settings consistency.

### Out of Scope
- Redesign of onboarding UX.
- CloudKit sync enablement.
- Broader localization or theme changes.

## Implementation Plan
### Phase 1: Canonical Settings Resolver
- Introduce a centralized resolver (service/helper) that returns:
  - effective coordinates
  - effective calculation method
  - effective madhab
- Resolution order for coordinates:
  1. Live GPS coordinates (if recent and authorized)
  2. Saved user coordinates from `UserPreferences`
  3. App default coordinates (last fallback only)
- Resolution order for method/madhab:
  1. `UserPreferences`
  2. Legacy raw key (migration path)
  3. `AppDefaults`

### Phase 2: Persistence Consolidation
- Replace raw `UserDefaults` reads/writes for `calculationMethod` in runtime surfaces with preference-backed access.
- Add one-time migration from legacy `UserDefaults["calculationMethod"]` into `UserPreferences.calculationMethod`.
- Ensure Settings and Onboarding writes are reflected through the same persistence channel.

### Phase 3: Madhab Application Correctness
- Ensure Asr computation uses selected madhab shadow ratio (`Madhab.shadowRatio`) or an equivalent explicit mapping.
- Verify no calculation path silently ignores user-selected madhab.

### Phase 4: Consumer Alignment
Update all relevant consumers to use canonical resolved settings:
- Prayer feature load path
- Home prayer cards
- Ramadan prayer/iftar/suhoor derivations
- Notification scheduling prayer calculation path

### Phase 5: Testing and Regression Safety
Add/extend tests for:
- Cold start with no GPS but saved location present -> saved location used.
- Settings change in Settings screen -> reflected in Home, Prayer, Ramadan, and scheduler paths.
- Madhab change causes expected Asr-time difference.
- Migration path from legacy key to preferences works once and remains stable.

## Acceptance Criteria
1. **Saved Location Priority**
- After app restart, with location permission denied or unavailable and saved location present, prayer times use saved coordinates (not default London).

2. **Single Source of Truth**
- Calculation method and madhab are read from canonical preference-backed settings in Prayer/Home/Ramadan/NotificationScheduler; no conflicting raw-key runtime reads remain.

3. **Madhab Effectiveness**
- Changing madhab in Settings changes Asr-time behavior according to expected shadow-ratio rules.

4. **Consistency Across Surfaces**
- A method/madhab change in Settings is reflected without mismatch in:
  - Prayer view
  - Home next-prayer card
  - Ramadan prayer timing
  - Notification scheduling

5. **Migration Safety**
- Legacy `calculationMethod` key migrates successfully to `UserPreferences` once, without regression for existing users.

6. **Test Coverage**
- Automated tests cover cold-start coordinate resolution, setting propagation, madhab impact, and legacy-key migration.

## Risks and Mitigations
- **Risk:** Hidden raw-key usage remains in codepaths.
  - **Mitigation:** Add static search check in CI for disallowed direct keys.
- **Risk:** Behavior changes alter previously expected timings for some users.
  - **Mitigation:** Add migration notes and verify with deterministic calculation tests.

## Done Definition
Implementation is complete when all acceptance criteria pass in automated tests and manual verification confirms no Settings/Prayer timing drift after app restart.
