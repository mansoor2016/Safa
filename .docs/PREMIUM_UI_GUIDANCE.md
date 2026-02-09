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

## Global Guardrails
- Prioritize readability over effect intensity.
- Use semantic layout for RTL compatibility.
- Keep animations tokenized (duration/curve) and consistent across screens.
- Respect accessibility settings (`Reduce Motion`, Dynamic Type, contrast).
- Avoid heavy effects in Quran reading mode; comfort first.

## Suggested Rollout Order
1. Navigation Bar Material Morph (Home + Prayer)
2. Hero Compression + Sticky Context Chip (Home)
3. Numeric Text Transitions (Home + Prayer + Dhikr)
4. Matched-Geometry Transition (Quran list -> reader)
5. Contextual Actions + Sticky Filter Rail (Quran/Hadith)

