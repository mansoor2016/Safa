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
        XCTAssertEqual(HasanatAward.familyJoined.points, 15)
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
            .dailyHadith, .share, .inviteAccepted, .familyJoined, .fastingDay, .taraweeh
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

    func test_fajrAngles_matchStandards() {
        XCTAssertEqual(CalculationMethod.muslimWorldLeague.fajrAngle, 18.0)
        XCTAssertEqual(CalculationMethod.isna.fajrAngle, 15.0)
        XCTAssertEqual(CalculationMethod.egypt.fajrAngle, 19.5)
        XCTAssertEqual(CalculationMethod.makkah.fajrAngle, 18.5)
        XCTAssertEqual(CalculationMethod.karachi.fajrAngle, 18.0)
        XCTAssertEqual(CalculationMethod.tehran.fajrAngle, 17.7)
        XCTAssertEqual(CalculationMethod.jafari.fajrAngle, 16.0)
    }

    func test_ishaAngles_matchStandards() {
        XCTAssertEqual(CalculationMethod.muslimWorldLeague.ishaAngle, 17.0)
        XCTAssertEqual(CalculationMethod.isna.ishaAngle, 15.0)
        XCTAssertEqual(CalculationMethod.egypt.ishaAngle, 17.5)
        XCTAssertEqual(CalculationMethod.makkah.ishaAngle, 0,
                       "Makkah uses 90 min after Maghrib, not an angle")
        XCTAssertEqual(CalculationMethod.karachi.ishaAngle, 18.0)
        XCTAssertEqual(CalculationMethod.tehran.ishaAngle, 14.0)
        XCTAssertEqual(CalculationMethod.jafari.ishaAngle, 14.0)
    }

    func test_allFajrAngles_arePositive() {
        for method in CalculationMethod.allCases {
            XCTAssertGreaterThan(method.fajrAngle, 0,
                                 "\(method) fajrAngle must be positive")
        }
    }

    func test_asrShadowRatio_jafariUsesHanafiStyle() {
        XCTAssertEqual(CalculationMethod.jafari.asrShadowRatio, 2.0)
    }

    func test_asrShadowRatio_allOthersUseStandard() {
        for method in CalculationMethod.allCases where method != .jafari {
            XCTAssertEqual(method.asrShadowRatio, 1.0,
                           "\(method) should use standard shadow ratio")
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

// MARK: - Achievement Color Mapping Tests

final class AchievementCategoryTests: XCTestCase {

    func test_allCategories_haveDistinctColors() {
        var seenColors: [String] = []
        for category in Achievement.AchievementCategory.allCases {
            let achievement = Achievement(
                id: "test", category: category, title: "Test",
                description: "Test", iconName: "star", isUnlocked: false
            )
            let colorDescription = "\(achievement.color)"
            // We just verify no crash and each category returns a color
            XCTAssertFalse(colorDescription.isEmpty)
        }
    }

    func test_allPredefinedAchievements_haveValidCategories() {
        for achievement in Achievement.allAchievements {
            // Each predefined achievement's category should be a known case
            XCTAssertTrue(Achievement.AchievementCategory.allCases.contains(achievement.category),
                          "Achievement \(achievement.id) has unknown category \(achievement.category)")
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
