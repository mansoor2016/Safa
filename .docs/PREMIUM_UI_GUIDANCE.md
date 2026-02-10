# Safa - Premium UI Guidance

## Purpose
Capture the highest-impact premium UI enhancements to build on the current Home header collapse-on-scroll work.

## Top 5 Enhancements

### 1. Navigation Bar Material Morph
**What:** Start with a clean/near-transparent top bar at scroll origin, then transition to subtle blur + hairline divider as content scrolls.

**Best surfaces:**
- Home
- Prayer
- Learn

**Why it feels premium:**
- Gives depth and hierarchy without adding visual clutter.
- Makes scroll position/state feel intentional.

**Implementation notes:**
- Animate opacity/material based on scroll offset threshold.
- Keep transition duration short and consistent with app motion tokens.
- Respect `Reduce Motion`.

---

### 2. Hero Card Compression + Sticky Context Chip
**What:** Compress the Home hero card (e.g., next prayer) into a compact pinned chip after scrolling beyond the hero region.

**Best surfaces:**
- Home (primary)
- Ramadan (variant: Day X + next fasting milestone)

**Why it feels premium:**
- Preserves critical context while freeing vertical space.
- Maintains continuity between expanded and compact states.

**Implementation notes:**
- Use shared identity (matched geometry) between hero and chip.
- Keep chip tappable to jump back/open full card.
- Avoid excessive scale changes; prioritize readability.

---

### 3. Matched-Geometry Card-to-Detail Transition
**What:** Animate list card elements (title, subtitle, artwork) into their destination on push navigation.

**Best surfaces:**
- Quran list -> Surah reader
- Hadith list -> Hadith detail
- Learn track -> Lesson detail

**Why it feels premium:**
- Creates spatial continuity and reduces perceived navigation friction.
- Makes transitions feel crafted rather than default.

**Implementation notes:**
- Scope to high-frequency flows only.
- Disable or simplify under `Reduce Motion`.
- Keep nav push latency low; no heavy computation during transition.

---

### 4. Numeric Text Transitions for Live Values
**What:** Animate changing numbers using numeric-aware transitions (countdowns, streaks, counters).

**Best surfaces:**
- Next prayer countdown
- Streak/Hasanat values
- Tasbeeh counters

**Why it feels premium:**
- Improves legibility of changing values.
- Feels precise and polished vs abrupt value swaps.

**Implementation notes:**
- Use numeric text transitions instead of manual crossfade.
- Keep update cadence predictable (no jitter).
- Avoid animating many independent numbers simultaneously.

---

### 5. Contextual Navigation Actions + Sticky Filter Rail
**What:** Keep navigation bar actions context-aware and show sticky filter pills only when relevant.

**Best surfaces:**
- Quran (search/filter modes)
- Hadith (collection/grade filters)
- Calendar (event type filters)

**Why it feels premium:**
- Reduces noise by showing only useful controls.
- Makes dense screens feel lightweight and structured.

**Implementation notes:**
- Keep action count minimal (prefer 1-2 primary actions).
- Make filter rail appear after initial scroll or when search is active.
- Preserve state across tab switches and deep links.

## Core Interaction Behaviors

### Screen State Transitions (Required)
Every primary surface should define explicit visual states and transitions:
- `loading`
- `ready`
- `degraded`
- `offline`
- `success/committed action`

**Best surfaces:**
- Home
- Prayer
- Quran reader
- Settings status surfaces

**Implementation notes:**
- Transition states with consistent motion tokens and timing.
- Never jump-cut between incompatible states unless there is an error boundary.
- Pair degraded/offline states with immediate recovery action.

---

### Bottom Sheet Behavior Standards
Use bottom sheets as a first-class interaction surface, not ad-hoc modals.

**Best surfaces:**
- Home quick actions
- Prayer detail actions
- Share composer
- Filter/configuration controls

**Implementation notes:**
- Standardize detents and drag behavior across screens.
- Keep handle, corner radius, and background treatment consistent.
- Use sheets for focused, short tasks; escalate to full screen for long-form flows.

---

### Adaptive Tab Bar and Chrome Visibility
Navigation chrome should respond to intent while staying predictable.

**Best surfaces:**
- Home feed-like scroll surfaces
- Quran/Hadith list surfaces

**Implementation notes:**
- Hide tab bar only on deliberate downward reading scroll.
- Reveal tab bar immediately on upward intent or interaction pause.
- Do not oscillate visibility on tiny scroll deltas.

---

### Optimistic Actions with Undo
Immediate feedback should be the default for low-risk actions.

**Best surfaces:**
- Prayer log toggles
- Bookmarks/favorites
- Save/share confirmations

**Implementation notes:**
- Commit UI instantly, sync in background, and expose lightweight undo.
- Show failure reconciliation only if sync actually fails.
- Keep toasts/snackbars brief and non-blocking.

---

### Zero-State and Resume Quality
Empty surfaces should always teach the next action and reduce time-to-value.

**Best surfaces:**
- Learn tracks
- Bookmarks/history
- Family/social sections

**Implementation notes:**
- Provide one clear primary action on every zero state.
- Avoid decorative empties with no clear path forward.
- Prioritize "resume where you left off" rails on Home for Quran, Learn, and Dhikr.

## Global Guardrails
- Prioritize readability over effect intensity.
- Use semantic layout for RTL compatibility.
- Keep animations tokenized (duration/curve) and consistent across screens.
- Respect accessibility settings (`Reduce Motion`, Dynamic Type, contrast).
- Avoid heavy effects in Quran reading mode; comfort first.
- Keep trust cues explicit in sensitive surfaces (privacy-safe AI, local-first data, export transparency).
- Avoid engagement patterns that feel manipulative; nudge gently and purposefully.

## Rollout Progress
1. ~~Navigation Bar Material Morph~~ ✅ Shipped (Home + Prayer + Ramadan, Feb 9 2026)
2. ~~Hero Compression + Sticky Context Chip~~ ✅ Shipped (Home, Feb 9 2026)
3. ~~Numeric Text Transitions~~ ✅ Shipped (.contentTransition(.numericText()) on all live counters)
4. ~~Screen State Transitions~~ ✅ Shipped (ErrorView + wired into Prayer/Quran/Hadith/Home, Feb 9 2026)
5. ~~Optimistic Actions with Undo~~ ✅ Shipped (prayer logging + undo rail, Feb 9 2026)
6. ~~Bottom Sheet Standards~~ ✅ Shipped (25 sheets with .compactSheet()/.fullSheet(), Feb 9 2026)
7. Matched-Geometry Transition (Quran list → reader) — next
8. Contextual Actions + Sticky Filter Rail — remaining
9. Adaptive Tab Bar — remaining
10. Zero-State/Resume Rails — remaining
