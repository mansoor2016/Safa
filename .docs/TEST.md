# Safa - Testing Guide

## Overview

This document defines the testing strategy for Safa, including automated tests, manual QA, and pre-release smoke tests.

**Testing Philosophy:**
- SwiftUI scales natively - only boundary testing required for screen sizes
- Automate what's automatable, manual test what requires human judgment
- Fast pre-release smoke tests to catch regressions

---

## 1. Automated Testing

### 1.1 Unit Tests
**Current:** 1,700+ tests | **Target:** 90%+ domain coverage

```bash
# Run all unit tests
xcodebuild -scheme Safa -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SafaTests test

# Run specific test class
xcodebuild -scheme Safa -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SafaTests/PrayerModelTests test
```

### 1.2 UI Tests
```bash
# Run all UI tests
xcodebuild -scheme Safa -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SafaUITests test
```

### 1.3 Test Coverage by Layer

| Layer | Current | Target |
|-------|---------|--------|
| Domain Entities | ~90% | 90%+ |
| Use Cases | ~85% | 90%+ |
| Repositories | ~70% | 80%+ |
| Services | ~60% | 70%+ |
| ViewModels | ~50% | 70%+ |

---

## 2. Device Compatibility Matrix

### 2.1 Screen Size Boundaries

| Device | Screen | iOS | Test Priority |
|--------|--------|-----|---------------|
| iPhone SE (3rd gen) | 4.7" | 26.0+ | **Required** - smallest |
| iPhone 17 Pro Max | 6.9" | 26.0+ | **Required** - largest |

**SwiftUI scales natively** - if boundaries pass, middle sizes work.

### 2.2 iOS Version Matrix

**Target: iOS 26.0+** — Single version target, no multi-version matrix needed.

| iOS Version | Test Device | Status |
|-------------|-------------|--------|
| iOS 26.0 | iPhone 17 Pro simulator | Required |

### 2.3 Feature Availability

All features available on iOS 26.0+ (single target platform).

---

## 3. Pre-Release Smoke Tests

**Purpose:** Quick verification before any release. Should take < 15 minutes.

### 3.1 Critical Path Smoke Test (5 min)

| # | Test | Steps | Expected |
|---|------|-------|----------|
| 1 | **App Launch** | Cold start app | Launches < 2s, Home screen shows |
| 2 | **Prayer Times** | View Prayer tab | Shows 5 prayers with times for current location |
| 3 | **Qibla** | Open Qibla compass | Compass renders, direction shown |
| 4 | **Quran** | Open Quran > tap any Surah | Arabic text renders correctly (RTL) |
| 5 | **Log Prayer** | Tap to log any prayer | Checkmark appears, Hasanat awarded |
| 6 | **Navigation** | Tap all 5 tab bar items | Each tab loads without crash |

### 3.2 Feature Smoke Test (10 min)

| # | Feature | Test | Expected |
|---|---------|------|----------|
| 7 | **Learn** | Open Learn > start any lesson | Lesson content displays |
| 8 | **Dhikr** | Open Tasbeeh counter > tap 3x | Counter increments with haptics |
| 9 | **Hadith** | Open Hadith > view any hadith | Arabic + English text displays |
| 10 | **Settings** | Open Settings > change theme color | Theme updates app-wide |
| 11 | **Streak** | Check streak after logging prayer | Streak count visible |
| 12 | **Widget** | Add Prayer widget to home screen | Widget shows next prayer |
| 13 | **Search** | Search for "mercy" in Quran | Results appear |
| 14 | **Dark Mode** | Toggle system dark mode | App adapts correctly |

### 3.3 Boundary Smoke Test (Device-specific)

**Run on iPhone SE simulator:**

| # | Test | Expected |
|---|------|----------|
| 15 | Arabic text in Quran | No overflow, readable |
| 16 | Prayer time cards | All 5 visible, no truncation |
| 17 | Home screen | All elements fit |

**Run on iPhone 16 Pro Max simulator:**

| # | Test | Expected |
|---|------|----------|
| 18 | Layouts | Not excessively sparse |
| 19 | Dynamic Island | Prayer countdown shows (if active) |

### 3.4 AI Companion Smoke Test (iOS 18.4+ only)

| # | Test | Expected |
|---|------|----------|
| 20 | Open Chat | Chat interface loads |
| 21 | Ask "What is the dua before eating?" | Response generated with Bismillah |
| 22 | Verify offline | Works without internet |

**On iOS < 18.4:**

| # | Test | Expected |
|---|------|----------|
| 23 | Open Chat | Shows "Requires iOS 18.4" message |

---

## 4. Manual QA Checklist

### 4.1 Accessibility

| Test | Steps | Pass Criteria |
|------|-------|---------------|
| VoiceOver - Prayer | Enable VO, navigate Prayer screen | All elements announced |
| VoiceOver - Quran | Enable VO, read ayah | Arabic text read correctly |
| Dynamic Type | Set to largest text size | Text scales, no truncation |
| Reduce Motion | Enable reduce motion | Animations respect setting |

### 4.2 Edge Cases

| Test | Steps | Pass Criteria |
|------|-------|---------------|
| No Location | Deny location permission | Shows manual location entry |
| No Network | Enable airplane mode | Core features work offline |
| Low Battery | Enable Low Power Mode | App functions normally |
| Notifications Denied | Deny notification permission | App works, shows settings prompt |

### 4.3 Data Persistence

| Test | Steps | Pass Criteria |
|------|-------|---------------|
| Prayer Log | Log prayer > kill app > reopen | Prayer still logged |
| Streak | Build 3-day streak > kill app > reopen | Streak preserved |
| Bookmarks | Bookmark ayah > kill app > reopen | Bookmark present |
| Settings | Change settings > kill app > reopen | Settings preserved |

---

## 5. Regression Test Triggers

Run full smoke test when:
- [ ] New feature merged to main
- [ ] iOS SDK updated
- [ ] Major refactoring
- [ ] Before TestFlight build
- [ ] Before App Store submission

Run boundary tests when:
- [ ] UI layout changes
- [ ] New screens added
- [ ] Arabic text handling modified

---

## 6. Test Environments

### 6.1 Simulators Required

```
iPhone SE (3rd generation) - iOS 26.0  (smallest screen)
iPhone 17 Pro Max - iOS 26.0           (largest screen)
```

### 6.2 Physical Devices (Recommended for Beta)

- iPhone with iOS 26.0+ (target platform)
- iPhone SE (verify compact layout)

---

## 7. Test Commands Quick Reference

```bash
# Build
xcodebuild -scheme Safa -destination 'platform=iOS Simulator,name=iPhone 17' build

# All unit tests
xcodebuild -scheme Safa -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SafaTests test

# All UI tests
xcodebuild -scheme Safa -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SafaUITests test

# Specific test class
xcodebuild -scheme Safa -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SafaTests/PrayerModelTests test

# Test on iPhone SE
xcodebuild -scheme Safa -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation)' test

# Test on iPhone 16 Pro Max
xcodebuild -scheme Safa -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' test
```

---

*Last Updated: February 2026*
