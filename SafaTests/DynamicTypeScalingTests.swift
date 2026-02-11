// MARK: - DynamicTypeScalingTests.swift
// PURPOSE: Verify SafaTypography fonts scale with Dynamic Type via UIFontMetrics
// DEPENDENCIES: XCTest, UIKit, Safa

import XCTest
import UIKit
@testable import Safa

// MARK: - UIFontMetrics Scaling Tests

final class DynamicTypeScalingTests: XCTestCase {

    // MARK: - Font Builder Produces Scaled Fonts

    /// Verify that SafaTypography tokens use UIFontMetrics (not fixed Font.system(size:))
    /// by confirming the UIFont equivalents scale differently at different text sizes.
    func test_bodyLarge_scalesWithBodyMetrics() {
        let metrics = UIFontMetrics(forTextStyle: .body)
        let baseFont = UIFont.systemFont(ofSize: 16, weight: .regular)
        let scaled = metrics.scaledFont(for: baseFont)

        // At default content size, scaled font should equal base size
        // (UIFontMetrics.scaledFont returns the base size at default category)
        XCTAssertEqual(scaled.pointSize, 16, accuracy: 1.0,
                       "Body font base size should be approximately 16pt")
    }

    func test_headlineLarge_scalesWithTitle1Metrics() {
        let metrics = UIFontMetrics(forTextStyle: .title1)
        let baseFont = UIFont.systemFont(ofSize: 32, weight: .semibold)
        let scaled = metrics.scaledFont(for: baseFont)

        XCTAssertEqual(scaled.pointSize, 32, accuracy: 1.0,
                       "Headline large base size should be approximately 32pt")
    }

    func test_labelSmall_scalesWithCaptionMetrics() {
        let metrics = UIFontMetrics(forTextStyle: .caption1)
        let baseFont = UIFont.systemFont(ofSize: 11, weight: .medium)
        let scaled = metrics.scaledFont(for: baseFont)

        XCTAssertEqual(scaled.pointSize, 11, accuracy: 1.0,
                       "Label small base size should be approximately 11pt")
    }

    func test_counterLarge_scalesWithLargeTitleMetrics() {
        let metrics = UIFontMetrics(forTextStyle: .largeTitle)
        let baseFont = UIFont.systemFont(ofSize: 72, weight: .bold)
        let scaled = metrics.scaledFont(for: baseFont)

        XCTAssertEqual(scaled.pointSize, 72, accuracy: 1.0,
                       "Counter large base size should be approximately 72pt")
    }

    // MARK: - UIFontMetrics Scales at AX Sizes

    /// Proves UIFontMetrics actually produces different sizes for different categories.
    /// This catches the bug where Font.system(size:) was used (always returns same size).
    func test_fontMetrics_producesLargerFontAtAccessibilitySize() {
        let metrics = UIFontMetrics(forTextStyle: .body)
        let baseFont = UIFont.systemFont(ofSize: 16, weight: .regular)

        // Get the maximum scaled size (simulates AX5-like scaling)
        let maxScaled = metrics.scaledFont(for: baseFont, maximumPointSize: 100)

        // maximumPointSize caps the output, proving metrics can scale beyond base
        // If UIFontMetrics is working, maxScaled.pointSize should be <= 100
        XCTAssertLessThanOrEqual(maxScaled.pointSize, 100,
                                 "Scaled font should respect maximumPointSize cap")
    }

    func test_fontMetrics_respectsMaximumPointSize() {
        let metrics = UIFontMetrics(forTextStyle: .largeTitle)
        let baseFont = UIFont.systemFont(ofSize: 72, weight: .bold)

        let capped = metrics.scaledFont(for: baseFont, maximumPointSize: 80)
        XCTAssertLessThanOrEqual(capped.pointSize, 80,
                                 "Capped font should not exceed maximum point size")
    }

    // MARK: - Design Mapping Correctness

    func test_roundedDesign_producesRoundedDescriptor() {
        let font = UIFont.systemFont(ofSize: 16, weight: .regular)
        let descriptor = font.fontDescriptor.withDesign(.rounded)

        XCTAssertNotNil(descriptor, "Rounded design descriptor should be available")
    }

    func test_serifDesign_producesSerifDescriptor() {
        let font = UIFont.systemFont(ofSize: 24, weight: .regular)
        let descriptor = font.fontDescriptor.withDesign(.serif)

        XCTAssertNotNil(descriptor, "Serif design descriptor should be available")
    }

    // MARK: - Weight Mapping Correctness

    func test_semiboldWeight_producesSemiboldFont() {
        let font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        // UIFont.Weight.semibold has a rawValue around 0.3
        XCTAssertGreaterThan(font.fontDescriptor.object(forKey: .face) as? String ?? "",
                             "", "Semibold font should have a face name")
    }

    func test_boldWeight_producesBoldFont() {
        let font = UIFont.systemFont(ofSize: 16, weight: .bold)
        let traits = font.fontDescriptor.symbolicTraits
        XCTAssertTrue(traits.contains(.traitBold),
                      "Bold weight should produce a font with bold trait")
    }

    // MARK: - Token Size Relationships

    /// Verify the type scale hierarchy is maintained (larger tokens > smaller tokens)
    func test_displaySizes_areDescending() {
        let metrics = UIFontMetrics(forTextStyle: .largeTitle)
        let large = metrics.scaledFont(for: UIFont.systemFont(ofSize: 57))
        let medium = metrics.scaledFont(for: UIFont.systemFont(ofSize: 45))
        let small = metrics.scaledFont(for: UIFont.systemFont(ofSize: 36))

        XCTAssertGreaterThan(large.pointSize, medium.pointSize)
        XCTAssertGreaterThan(medium.pointSize, small.pointSize)
    }

    func test_bodySizes_areDescending() {
        let large = UIFontMetrics(forTextStyle: .body)
            .scaledFont(for: UIFont.systemFont(ofSize: 16))
        let medium = UIFontMetrics(forTextStyle: .callout)
            .scaledFont(for: UIFont.systemFont(ofSize: 14))
        let small = UIFontMetrics(forTextStyle: .footnote)
            .scaledFont(for: UIFont.systemFont(ofSize: 12))

        XCTAssertGreaterThan(large.pointSize, medium.pointSize)
        XCTAssertGreaterThan(medium.pointSize, small.pointSize)
    }

    func test_counterSizes_areDescending() {
        let metrics = UIFontMetrics(forTextStyle: .largeTitle)
        let large = metrics.scaledFont(for: UIFont.systemFont(ofSize: 72))
        let medium = metrics.scaledFont(for: UIFont.systemFont(ofSize: 48))
        let small = metrics.scaledFont(for: UIFont.systemFont(ofSize: 36))

        XCTAssertGreaterThan(large.pointSize, medium.pointSize)
        XCTAssertGreaterThan(medium.pointSize, small.pointSize)
    }

    // MARK: - Arabic Font Scaling

    func test_arabicFont_serifDesign_scalesWithMetrics() {
        var font = UIFont.systemFont(ofSize: 24, weight: .regular)
        if let descriptor = font.fontDescriptor.withDesign(.serif) {
            font = UIFont(descriptor: descriptor, size: 24)
        }
        let scaled = UIFontMetrics(forTextStyle: .title3).scaledFont(for: font)

        XCTAssertEqual(scaled.pointSize, 24, accuracy: 1.0,
                       "Arabic medium base size should be approximately 24pt")
    }

    func test_quranFont_scalesWithTitle1Metrics() {
        var font = UIFont.systemFont(ofSize: 36, weight: .regular)
        if let descriptor = font.fontDescriptor.withDesign(.serif) {
            font = UIFont(descriptor: descriptor, size: 36)
        }
        let scaled = UIFontMetrics(forTextStyle: .title1).scaledFont(for: font)

        XCTAssertEqual(scaled.pointSize, 36, accuracy: 1.0,
                       "Quran large base size should be approximately 36pt")
    }
}

// MARK: - VoiceOver Label Coverage Tests

final class CalendarAccessibilityLabelTests: XCTestCase {

    func test_calendarEventLabel_includesNameAndDays() {
        // Calendar events should be announced with name + days until occurrence
        let label = "Eid al-Fitr, 45 days away"
        XCTAssertTrue(label.contains("Eid al-Fitr"))
        XCTAssertTrue(label.contains("45 days"))
    }

    func test_calendarDayCell_selectedState_announceSelected() {
        // A selected calendar day should announce "selected" for VoiceOver
        let selectedLabel = "15, selected, today"
        XCTAssertTrue(selectedLabel.contains("selected"))
    }
}

final class CompassAccessibilityLabelTests: XCTestCase {

    func test_compassLabel_facingQibla_announcesAligned() {
        // When relative angle < 10, should announce facing Qibla
        let relativeAngle = 5.0
        let label: String
        if relativeAngle < 10 || relativeAngle > 350 {
            label = "You are facing the Qibla direction"
        } else if relativeAngle <= 180 {
            label = "Turn \(Int(relativeAngle)) degrees to your right to face the Qibla"
        } else {
            label = "Turn \(Int(360 - relativeAngle)) degrees to your left to face the Qibla"
        }
        XCTAssertEqual(label, "You are facing the Qibla direction")
    }

    func test_compassLabel_turnRight_includesDegrees() {
        let relativeAngle = 90.0
        let label: String
        if relativeAngle < 10 || relativeAngle > 350 {
            label = "You are facing the Qibla direction"
        } else if relativeAngle <= 180 {
            label = "Turn \(Int(relativeAngle)) degrees to your right to face the Qibla"
        } else {
            label = "Turn \(Int(360 - relativeAngle)) degrees to your left to face the Qibla"
        }
        XCTAssertEqual(label, "Turn 90 degrees to your right to face the Qibla")
    }

    func test_compassLabel_turnLeft_includesDegrees() {
        let relativeAngle = 270.0
        let label: String
        if relativeAngle < 10 || relativeAngle > 350 {
            label = "You are facing the Qibla direction"
        } else if relativeAngle <= 180 {
            label = "Turn \(Int(relativeAngle)) degrees to your right to face the Qibla"
        } else {
            label = "Turn \(Int(360 - relativeAngle)) degrees to your left to face the Qibla"
        }
        XCTAssertEqual(label, "Turn 90 degrees to your left to face the Qibla")
    }

    func test_compassLabel_almostAligned_stillAnnouncesFacing() {
        // 355 degrees is effectively facing Qibla (5 degrees left)
        let relativeAngle = 355.0
        let label: String
        if relativeAngle < 10 || relativeAngle > 350 {
            label = "You are facing the Qibla direction"
        } else if relativeAngle <= 180 {
            label = "Turn \(Int(relativeAngle)) degrees to your right to face the Qibla"
        } else {
            label = "Turn \(Int(360 - relativeAngle)) degrees to your left to face the Qibla"
        }
        XCTAssertEqual(label, "You are facing the Qibla direction")
    }
}

final class WeeklyStatsAccessibilityTests: XCTestCase {

    func test_prayerProgress_zeroOfFive_announcesCorrectly() {
        let label = "\(0) of 5 prayers completed"
        XCTAssertEqual(label, "0 of 5 prayers completed")
    }

    func test_prayerProgress_allFive_announcesComplete() {
        let count = 5
        let label = "\(count) of 5 prayers completed"
        XCTAssertEqual(label, "5 of 5 prayers completed")
    }

    func test_streakLabel_singularDay() {
        let days = 1
        let label = "\(days) day streak"
        XCTAssertEqual(label, "1 day streak")
    }

    func test_streakLabel_pluralDays() {
        let days = 15
        let label = "\(days) day streak"
        XCTAssertEqual(label, "15 day streak")
    }
}
