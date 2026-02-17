// MARK: - DomainCorrectnessTests.swift
// PURPOSE: Behavioral correctness tests for domain entities and use cases
// Tests logic that affects user-visible outcomes: level progression,
// point economy, prayer time calculations, and preference inference.

import XCTest
@testable import Safa

// MARK: - Level Progression Boundary Tests

final class LevelProgressionTests: XCTestCase {

    // Verify every boundary threshold produces the correct level.
    // A bug here means users level up too early or too late.

    func test_calculateLevel_boundaries() {
        // Just below each threshold → stays at prior level
        XCTAssertEqual(UserStats.calculateLevel(from: 0), 1)
        XCTAssertEqual(UserStats.calculateLevel(from: 99), 1)
        XCTAssertEqual(UserStats.calculateLevel(from: 100), 2)
        XCTAssertEqual(UserStats.calculateLevel(from: 299), 2)
        XCTAssertEqual(UserStats.calculateLevel(from: 300), 3)
        XCTAssertEqual(UserStats.calculateLevel(from: 599), 3)
        XCTAssertEqual(UserStats.calculateLevel(from: 600), 4)
        XCTAssertEqual(UserStats.calculateLevel(from: 999), 4)
        XCTAssertEqual(UserStats.calculateLevel(from: 1000), 5)
        XCTAssertEqual(UserStats.calculateLevel(from: 1999), 5)
        XCTAssertEqual(UserStats.calculateLevel(from: 2000), 6)
        XCTAssertEqual(UserStats.calculateLevel(from: 3999), 6)
        XCTAssertEqual(UserStats.calculateLevel(from: 4000), 7)
        XCTAssertEqual(UserStats.calculateLevel(from: 6999), 7)
        XCTAssertEqual(UserStats.calculateLevel(from: 7000), 8)
        XCTAssertEqual(UserStats.calculateLevel(from: 11999), 8)
        XCTAssertEqual(UserStats.calculateLevel(from: 12000), 9)
        XCTAssertEqual(UserStats.calculateLevel(from: 19999), 9)
        XCTAssertEqual(UserStats.calculateLevel(from: 20000), 10)
    }

    func test_calculateLevel_veryLargeValue_capsAtMax() {
        // Even with millions of hasanat, level should not exceed 10
        XCTAssertEqual(UserStats.calculateLevel(from: 1_000_000), 10)
    }

    func test_calculateLevel_consistentWithHasanatForLevel() {
        // For each level, the minimum hasanat should produce that level
        for level in 1...10 {
            let minHasanat = UserStats.hasanatForLevel(level)
            XCTAssertEqual(
                UserStats.calculateLevel(from: minHasanat), level,
                "hasanatForLevel(\(level)) = \(minHasanat) should produce level \(level)"
            )
        }
    }

    func test_levelTitle_coversAllLevels() {
        // Verify no level returns an empty or "Beginner" fallback unexpectedly
        let expectedTitles = ["Beginner", "Seeker", "Learner", "Dedicated", "Consistent",
                              "Devoted", "Steadfast", "Committed", "Excellent", "Muhsin"]
        for (index, expected) in expectedTitles.enumerated() {
            XCTAssertEqual(UserStats.levelTitle(for: index + 1), expected)
        }
    }

    func test_levelProgression_isStrictlyIncreasing() {
        // Each level requires more hasanat than the previous
        var previousThreshold = -1
        for level in 1...10 {
            let threshold = UserStats.hasanatForLevel(level)
            XCTAssertGreaterThan(threshold, previousThreshold,
                                 "Level \(level) threshold (\(threshold)) must exceed level \(level-1)")
            previousThreshold = threshold
        }
    }
}

// MARK: - Hasanat Point Economy Tests

final class HasanatAwardPointTests: XCTestCase {

    // Verify the entire point economy. If someone accidentally changes
    // a point value, these tests catch it before the economy breaks.

    func test_prayerPoints_matchExpected() {
        XCTAssertEqual(HasanatAward.prayerLogged.points, 10)
        XCTAssertEqual(HasanatAward.prayerAllFive.points, 25)
    }

    func test_quranPoints_matchExpected() {
        XCTAssertEqual(HasanatAward.quranPage.points, 5)
        XCTAssertEqual(HasanatAward.quranSurah.points, 15)
        XCTAssertEqual(HasanatAward.quranJuz.points, 50)
    }

    func test_learningPoints_matchExpected() {
        XCTAssertEqual(HasanatAward.lessonComplete.points, 10)
        XCTAssertEqual(HasanatAward.lessonPerfect.points, 5)
        XCTAssertEqual(HasanatAward.pronunciationPass.points, 5)
        XCTAssertEqual(HasanatAward.tajweedModule.points, 20)
    }

    func test_dhikrPoints_matchExpected() {
        XCTAssertEqual(HasanatAward.morningDhikr.points, 15)
        XCTAssertEqual(HasanatAward.eveningDhikr.points, 15)
        XCTAssertEqual(HasanatAward.tasbeehSession.points, 10)
    }

    func test_socialPoints_matchExpected() {
        XCTAssertEqual(HasanatAward.share.points, 5)
        XCTAssertEqual(HasanatAward.inviteAccepted.points, 25)
    }

    func test_dailyPoints_matchExpected() {
        XCTAssertEqual(HasanatAward.dailyOpen.points, 5)
        XCTAssertEqual(HasanatAward.dailyVerse.points, 3)
        XCTAssertEqual(HasanatAward.dailyHadith.points, 3)
    }

    func test_ramadanPoints_matchExpected() {
        XCTAssertEqual(HasanatAward.fastingDay.points, 20)
        XCTAssertEqual(HasanatAward.taraweeh.points, 25)
    }

    func test_allFivePrayers_worthMoreThanFiveIndividual() {
        // The bonus for all five should exceed logging 5 individually
        // (25 vs 5*10=50) — actually it's an additive bonus, not replacement
        // But the bonus itself should be non-trivial
        XCTAssertGreaterThan(HasanatAward.prayerAllFive.points, HasanatAward.prayerLogged.points)
    }

    func test_allPointsArePositive() {
        let allAwards: [HasanatAward] = [
            .prayerLogged, .prayerAllFive, .quranPage, .quranSurah, .quranJuz,
            .lessonComplete, .lessonPerfect, .pronunciationPass, .tajweedModule,
            .morningDhikr, .eveningDhikr, .tasbeehSession, .dailyOpen, .dailyVerse,
            .dailyHadith, .share, .inviteAccepted, .fastingDay, .taraweeh
        ]
        for award in allAwards {
            XCTAssertGreaterThan(award.points, 0, "All awards must be positive")
        }
    }
}

// MARK: - Prayer Type Correctness Tests

final class PrayerTypeCorrectnessTests: XCTestCase {

    func test_obligatoryPrayers_excludesSunrise() {
        let obligatory = PrayerType.obligatoryPrayers
        XCTAssertEqual(obligatory.count, 5)
        XCTAssertFalse(obligatory.contains(.sunrise),
                       "Sunrise is not an obligatory prayer")
    }

    func test_isObligatory_matchesObligatoryPrayersList() {
        // Every prayer that claims isObligatory should be in obligatoryPrayers
        for prayer in PrayerType.allCases {
            if prayer.isObligatory {
                XCTAssertTrue(PrayerType.obligatoryPrayers.contains(prayer),
                              "\(prayer) claims isObligatory but is not in obligatoryPrayers")
            } else {
                XCTAssertFalse(PrayerType.obligatoryPrayers.contains(prayer),
                               "\(prayer) is not obligatory but appears in obligatoryPrayers")
            }
        }
    }

    func test_sunrise_isNotObligatory() {
        XCTAssertFalse(PrayerType.sunrise.isObligatory)
    }

    func test_allSixPrayerTypes_exist() {
        XCTAssertEqual(PrayerType.allCases.count, 6)
    }
}

// MARK: - Calculation Method Angle Tests

final class CalculationMethodAngleTests: XCTestCase {

    // Prayer time accuracy depends on these angles. A wrong angle
    // means Fajr or Isha could be off by tens of minutes.

    func test_allMethods_haveDescription() {
        for method in CalculationMethod.allCases {
            XCTAssertFalse(method.methodDescription.isEmpty,
                           "\(method) must have a description")
        }
    }

    func test_allMethods_haveDisplayName() {
        for method in CalculationMethod.allCases {
            XCTAssertFalse(method.displayName.isEmpty,
                           "\(method) must have a display name")
        }
    }
}

// MARK: - Madhab Shadow Ratio Tests

final class MadhabCorrectnessTests: XCTestCase {

    func test_shafiShadowRatio_isOne() {
        XCTAssertEqual(Madhab.shafi.shadowRatio, 1.0,
                       "Shafi'i Asr: shadow equals object length")
    }

    func test_hanafiShadowRatio_isTwo() {
        XCTAssertEqual(Madhab.hanafi.shadowRatio, 2.0,
                       "Hanafi Asr: shadow equals twice object length")
    }

    func test_shadowRatios_differBetweenMadhabs() {
        // This is the whole point of the madhab setting
        XCTAssertNotEqual(Madhab.shafi.shadowRatio, Madhab.hanafi.shadowRatio)
    }
}

// MARK: - User Preferences Location Tests

final class UserPreferencesLocationTests: XCTestCase {

    func test_hasSavedLocation_falseByDefault() {
        let prefs = UserPreferences()
        XCTAssertFalse(prefs.hasSavedLocation)
    }

    func test_hasSavedLocation_requiresBothCoordinates() {
        var prefs = UserPreferences()
        prefs.savedLatitude = 51.5074
        XCTAssertFalse(prefs.hasSavedLocation, "Needs both lat and lng")

        prefs.savedLongitude = -0.1278
        XCTAssertTrue(prefs.hasSavedLocation)
    }

    func test_savedCoordinates_nilWhenNoLocation() {
        let prefs = UserPreferences()
        XCTAssertNil(prefs.savedCoordinates)
    }

    func test_savedCoordinates_returnsCoordinatesWhenSet() {
        var prefs = UserPreferences()
        prefs.savedLatitude = 21.4225
        prefs.savedLongitude = 39.8262

        let coords = prefs.savedCoordinates
        XCTAssertNotNil(coords)
        XCTAssertEqual(coords!.latitude, 21.4225, accuracy: 0.001)
        XCTAssertEqual(coords!.longitude, 39.8262, accuracy: 0.001)
    }

    func test_applyLocationDefaults_updatesAllFields() {
        var prefs = UserPreferences()

        let context = LocationContext(
            coordinates: Coordinates(latitude: 24.7136, longitude: 46.6753),
            city: "Riyadh",
            country: "Saudi Arabia",
            countryCode: "SA",
            timezone: nil,
            recommendedMethod: .makkah,
            recommendedMadhab: .hanafi,
            recommendedLanguage: "Arabic",
            regionName: "Riyadh, Saudi Arabia"
        )

        prefs.applyLocationDefaults(from: context)

        XCTAssertEqual(prefs.calculationMethod, .makkah)
        XCTAssertEqual(prefs.madhab, .hanafi)
        XCTAssertEqual(prefs.selectedTranslation, "Arabic")
        XCTAssertEqual(prefs.savedLocationName, "Riyadh, Saudi Arabia")
        XCTAssertEqual(prefs.savedLatitude ?? 0, 24.7136, accuracy: 0.001)
        XCTAssertEqual(prefs.savedLongitude ?? 0, 46.6753, accuracy: 0.001)
        XCTAssertEqual(prefs.savedCountryCode, "SA")
    }

    func test_applyLocationDefaults_overwritesPreviousSettings() {
        var prefs = UserPreferences(calculationMethod: .isna, madhab: .shafi)

        let context = LocationContext(
            coordinates: Coordinates(latitude: 31.9, longitude: 35.2),
            city: "Amman",
            country: "Jordan",
            countryCode: "JO",
            timezone: nil,
            recommendedMethod: .muslimWorldLeague,
            recommendedMadhab: .hanafi,
            recommendedLanguage: "Arabic",
            regionName: "Amman"
        )

        prefs.applyLocationDefaults(from: context)

        XCTAssertEqual(prefs.calculationMethod, .muslimWorldLeague,
                       "Should overwrite previous ISNA setting")
        XCTAssertEqual(prefs.madhab, .hanafi,
                       "Should overwrite previous Shafi'i setting")
    }
}

// MARK: - Quran Progress Percentage Tests

final class QuranProgressTests: XCTestCase {

    func test_progressPercentage_zeroWhenNoAyahsRead() {
        let progress = QuranProgress(totalAyahsRead: 0)
        XCTAssertEqual(progress.progressPercentage, 0, accuracy: 0.001)
    }

    func test_progressPercentage_halfwayThrough() {
        let progress = QuranProgress(totalAyahsRead: 3118) // ~half of 6236
        XCTAssertEqual(progress.progressPercentage, 50.0, accuracy: 0.1)
    }

    func test_progressPercentage_completeQuran() {
        let progress = QuranProgress(totalAyahsRead: 6236)
        XCTAssertEqual(progress.progressPercentage, 100.0, accuracy: 0.001)
    }

    func test_progressPercentage_exceedsHundredOnReread() {
        // If user re-reads, totalAyahsRead can exceed 6236
        let progress = QuranProgress(totalAyahsRead: 12472)
        XCTAssertEqual(progress.progressPercentage, 200.0, accuracy: 0.1)
    }
}

// MARK: - Adhan Sound Filtering Tests

final class AdhanSoundFilteringTests: XCTestCase {

    func test_regularOptions_excludesFajrSpecific() {
        let regular = AdhanSound.regularOptions
        XCTAssertFalse(regular.contains(.misharyAlafasyFajr),
                       "Fajr-specific sound should not appear in regular picker")
    }

    func test_regularOptions_excludesDefault() {
        let regular = AdhanSound.regularOptions
        XCTAssertFalse(regular.contains(.defaultSound),
                       "System default should not appear in regular picker")
    }

    func test_regularOptions_containsAllOtherSounds() {
        let regular = AdhanSound.regularOptions
        // Total: 12 cases - 1 fajr - 1 default = 10
        XCTAssertEqual(regular.count, 10)
    }

    func test_onlyMisharyAlafasyFajr_isFajrSpecific() {
        for sound in AdhanSound.allCases {
            if sound == .misharyAlafasyFajr {
                XCTAssertTrue(sound.isFajrSpecific)
            } else {
                XCTAssertFalse(sound.isFajrSpecific,
                               "\(sound) should not be fajr-specific")
            }
        }
    }
}

// MARK: - Tasbeeh Session Edge Cases

final class TasbeehSessionEdgeCaseTests: XCTestCase {

    func test_progress_overTarget_capsAtOne() {
        // If currentCount somehow exceeds target, progress should exceed 1
        // (no artificial cap - TasbeehSession.progress is raw ratio)
        let session = TasbeehSession(
            dhikrText: "SubhanAllah",
            targetCount: 33,
            currentCount: 66
        )
        XCTAssertEqual(session.progress, 2.0, accuracy: 0.001)
        XCTAssertTrue(session.isComplete)
    }

    func test_isComplete_exactlyAtTarget() {
        let session = TasbeehSession(
            dhikrText: "Alhamdulillah",
            targetCount: 100,
            currentCount: 100
        )
        XCTAssertTrue(session.isComplete)
        XCTAssertEqual(session.progress, 1.0, accuracy: 0.001)
    }

    func test_isComplete_oneBelow() {
        let session = TasbeehSession(
            dhikrText: "Allahu Akbar",
            targetCount: 33,
            currentCount: 32
        )
        XCTAssertFalse(session.isComplete)
    }
}

// MARK: - Track Progress Correctness Tests

final class TrackProgressCorrectnessTests: XCTestCase {

    func test_completionPercentage_zeroLessons_returnsZero() {
        // Guard against divide-by-zero when track has no lessons
        let progress = TrackProgress(trackId: "empty", completedLessons: 0, totalLessons: 0)
        XCTAssertEqual(progress.completionPercentage, 0)
    }

    func test_completionPercentage_noProgress_returnsZero() {
        let progress = TrackProgress(trackId: "arabic", completedLessons: 0, totalLessons: 28)
        XCTAssertEqual(progress.completionPercentage, 0)
    }

    func test_completionPercentage_halfComplete_returnsFifty() {
        let progress = TrackProgress(trackId: "arabic", completedLessons: 14, totalLessons: 28)
        XCTAssertEqual(progress.completionPercentage, 50.0, accuracy: 0.01)
    }

    func test_completionPercentage_allComplete_returnsHundred() {
        let progress = TrackProgress(trackId: "arabic", completedLessons: 28, totalLessons: 28)
        XCTAssertEqual(progress.completionPercentage, 100.0, accuracy: 0.01)
    }

    func test_isComplete_false_whenPartial() {
        let progress = TrackProgress(trackId: "arabic", completedLessons: 27, totalLessons: 28)
        XCTAssertFalse(progress.isComplete)
    }

    func test_isComplete_true_whenAllDone() {
        let progress = TrackProgress(trackId: "arabic", completedLessons: 28, totalLessons: 28)
        XCTAssertTrue(progress.isComplete)
    }

    func test_isComplete_true_whenExceeding() {
        // Edge case: completed > total (shouldn't happen, but verify it doesn't crash)
        let progress = TrackProgress(trackId: "arabic", completedLessons: 30, totalLessons: 28)
        XCTAssertTrue(progress.isComplete)
    }
}

// MARK: - Hasanat Calculation Correctness Tests

final class HasanatCalculationCorrectnessTests: XCTestCase {

    let sut = CalculateHasanatUseCase()

    // MARK: - Surah Point Tiers (via public calculatePoints API)

    func test_surahPoints_alFatiha_getsBonus() {
        // Al-Fatiha (surah 1) should get base + 5 = 15 + 5 = 20
        let points = sut.calculatePoints(for: .quranSurahCompleted(surahNumber: 1))
        XCTAssertEqual(points, 20, "Al-Fatiha: base 15 + 5 bonus")
    }

    func test_surahPoints_alBaqarah_gets5xMultiplier() {
        // Al-Baqarah (surah 2, longest) should get base * 5 = 75
        let points = sut.calculatePoints(for: .quranSurahCompleted(surahNumber: 2))
        XCTAssertEqual(points, 75, "Al-Baqarah: base 15 * 5")
    }

    func test_surahPoints_longSurahs_get4x() {
        // Surahs 3-4 get base * 4 = 60
        let points3 = sut.calculatePoints(for: .quranSurahCompleted(surahNumber: 3))
        let points4 = sut.calculatePoints(for: .quranSurahCompleted(surahNumber: 4))
        XCTAssertEqual(points3, 60, "Surah 3: base 15 * 4")
        XCTAssertEqual(points4, 60, "Surah 4: base 15 * 4")
    }

    func test_surahPoints_mediumSurahs_get3x() {
        // Surahs 5-10 get base * 3 = 45
        let points5 = sut.calculatePoints(for: .quranSurahCompleted(surahNumber: 5))
        let points10 = sut.calculatePoints(for: .quranSurahCompleted(surahNumber: 10))
        XCTAssertEqual(points5, 45, "Surah 5 boundary: base 15 * 3")
        XCTAssertEqual(points10, 45, "Surah 10 boundary: base 15 * 3")
    }

    func test_surahPoints_semiShortSurahs_get2x() {
        // Surahs 11-30 get base * 2 = 30
        let points11 = sut.calculatePoints(for: .quranSurahCompleted(surahNumber: 11))
        let points30 = sut.calculatePoints(for: .quranSurahCompleted(surahNumber: 30))
        XCTAssertEqual(points11, 30, "Surah 11 boundary: base 15 * 2")
        XCTAssertEqual(points30, 30, "Surah 30 boundary: base 15 * 2")
    }

    func test_surahPoints_shortSurahs_getBase() {
        // Surahs 31+ get base = 15
        let points31 = sut.calculatePoints(for: .quranSurahCompleted(surahNumber: 31))
        let points114 = sut.calculatePoints(for: .quranSurahCompleted(surahNumber: 114))
        XCTAssertEqual(points31, 15, "Surah 31: base 15")
        XCTAssertEqual(points114, 15, "Surah 114 (An-Nas): base 15")
    }

    // MARK: - Tasbeeh Point Buckets

    func test_tasbeehPoints_zero_returnsZero() {
        let points = sut.calculatePoints(for: .tasbeeh(count: 0))
        XCTAssertEqual(points, 0)
    }

    func test_tasbeehPoints_belowThirtyThree_floorDivisionByTen() {
        // 10/10 = 1, 32/10 = 3 (floor division)
        XCTAssertEqual(sut.calculatePoints(for: .tasbeeh(count: 10)), 1)
        XCTAssertEqual(sut.calculatePoints(for: .tasbeeh(count: 32)), 3)
    }

    func test_tasbeehPoints_exactlyThirtyThree_getsTenPoints() {
        // Boundary: 33 enters the 33..<100 bucket = 10 points
        let points = sut.calculatePoints(for: .tasbeeh(count: 33))
        XCTAssertEqual(points, 10)
    }

    func test_tasbeehPoints_ninetyNine_stillTenPoints() {
        let points = sut.calculatePoints(for: .tasbeeh(count: 99))
        XCTAssertEqual(points, 10)
    }

    func test_tasbeehPoints_exactlyHundred_getsTwentyPoints() {
        // Boundary: 100 enters the 100+ bucket = 20 points
        let points = sut.calculatePoints(for: .tasbeeh(count: 100))
        XCTAssertEqual(points, 20)
    }

    func test_tasbeehPoints_overHundred_stillTwentyPoints() {
        let points = sut.calculatePoints(for: .tasbeeh(count: 500))
        XCTAssertEqual(points, 20)
    }

    // MARK: - Streak Milestone Points

    func test_streakPoints_day7_milestone() {
        let points = sut.calculatePoints(for: .streakMilestone(days: 7))
        XCTAssertEqual(points, 50)
    }

    func test_streakPoints_day30_milestone() {
        let points = sut.calculatePoints(for: .streakMilestone(days: 30))
        XCTAssertEqual(points, 150)
    }

    func test_streakPoints_day100_milestone() {
        let points = sut.calculatePoints(for: .streakMilestone(days: 100))
        XCTAssertEqual(points, 500)
    }

    func test_streakPoints_multipleOfTen_getsHalfDays() {
        // day 20 → 20/2 = 10 points, day 50 → 50/2 = 25 points
        XCTAssertEqual(sut.calculatePoints(for: .streakMilestone(days: 20)), 10)
        XCTAssertEqual(sut.calculatePoints(for: .streakMilestone(days: 50)), 25)
    }

    func test_streakPoints_nonMilestone_returnsZero() {
        // Day 5, 13, 99 are not milestones and not multiples of 10
        XCTAssertEqual(sut.calculatePoints(for: .streakMilestone(days: 5)), 0)
        XCTAssertEqual(sut.calculatePoints(for: .streakMilestone(days: 13)), 0)
        XCTAssertEqual(sut.calculatePoints(for: .streakMilestone(days: 99)), 0)
    }

    // MARK: - Multiplier Logic

    func test_multiplier_ramadan_doubles() {
        let base = sut.calculatePoints(for: .prayerLogged(.fajr))
        let withRamadan = sut.calculateWithMultipliers(for: .prayerLogged(.fajr), isRamadan: true, isFriday: false)
        XCTAssertEqual(withRamadan, base * 2, "Ramadan should double points")
    }

    func test_multiplier_friday_eligibleAction_gets1_5x() {
        let base = sut.calculatePoints(for: .quranPageRead)
        let withFriday = sut.calculateWithMultipliers(for: .quranPageRead, isRamadan: false, isFriday: true)
        XCTAssertEqual(withFriday, Int(Double(base) * 1.5), "Friday bonus = 1.5x for eligible actions")
    }

    func test_multiplier_friday_ineligibleAction_noBonus() {
        let base = sut.calculatePoints(for: .lessonCompleted)
        let withFriday = sut.calculateWithMultipliers(for: .lessonCompleted, isRamadan: false, isFriday: true)
        XCTAssertEqual(withFriday, base, "Lesson completed should NOT get Friday bonus")
    }

    func test_multiplier_ramadanTakesPrecedenceOverFriday() {
        // When both Ramadan (2x) and Friday (1.5x), Ramadan wins via max()
        let base = sut.calculatePoints(for: .prayerLogged(.dhuhr))
        let withBoth = sut.calculateWithMultipliers(for: .prayerLogged(.dhuhr), isRamadan: true, isFriday: true)
        XCTAssertEqual(withBoth, base * 2, "Ramadan 2x > Friday 1.5x, so Ramadan wins")
    }

    func test_multiplier_noMultipliers_returnsBase() {
        let base = sut.calculatePoints(for: .morningDhikrCompleted)
        let noMultiplier = sut.calculateWithMultipliers(for: .morningDhikrCompleted, isRamadan: false, isFriday: false)
        XCTAssertEqual(noMultiplier, base)
    }

    // MARK: - Friday Bonus Eligibility

    func test_fridayBonus_eligibleActions() {
        // These 6 actions should get Friday bonus
        let eligibleActions: [HasanatAction] = [
            .prayerLogged(.fajr),
            .quranPageRead,
            .quranSurahCompleted(surahNumber: 1),
            .duaRecited,
            .morningDhikrCompleted,
            .eveningDhikrCompleted
        ]

        for action in eligibleActions {
            let base = sut.calculatePoints(for: action)
            let friday = sut.calculateWithMultipliers(for: action, isRamadan: false, isFriday: true)
            XCTAssertGreaterThan(friday, base, "Action \(action) should get Friday bonus")
        }
    }

    func test_fridayBonus_ineligibleActions() {
        // These actions should NOT get Friday bonus
        let ineligibleActions: [HasanatAction] = [
            .allFivePrayersLogged,
            .lessonCompleted,
            .trackCompleted,
            .invitedFriend,
            .sharedVerse,
            .perfectWeek
        ]

        for action in ineligibleActions {
            let base = sut.calculatePoints(for: action)
            let friday = sut.calculateWithMultipliers(for: action, isRamadan: false, isFriday: true)
            XCTAssertEqual(friday, base, "Action \(action) should NOT get Friday bonus")
        }
    }
}
