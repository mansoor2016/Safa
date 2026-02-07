// MARK: - PracticeSessionTests.swift
// PURPOSE: Unit tests for PracticeSession model
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

final class PracticeSessionTests: XCTestCase {

    func test_init_setsCorrectType() {
        let session = PracticeSession(type: .quickDhikr, content: .dhikr(phrase: "SubhanAllah", targetCount: 33))
        XCTAssertEqual(session.type, .quickDhikr)
    }

    func test_init_isNotCompleted() {
        let session = PracticeSession(type: .ayahReflection, content: .ayah(surah: 2, ayah: 255))
        XCTAssertFalse(session.isCompleted)
        XCTAssertNil(session.completedAt)
    }

    func test_completion_setsCompletedAt() {
        var session = PracticeSession(type: .dailyHadith, content: .hadith(text: "Test", narrator: "Bukhari"))
        session.completedAt = Date()
        XCTAssertTrue(session.isCompleted)
    }

    func test_duration_zeroBeforeCompletion() {
        let session = PracticeSession(type: .quickDhikr, content: .dhikr(phrase: "SubhanAllah", targetCount: 33))
        XCTAssertEqual(session.durationSeconds, 0)
    }

    func test_allPracticeTypes_exist() {
        XCTAssertEqual(PracticeType.allCases.count, 3)
    }

    func test_practiceType_displayNames() {
        XCTAssertEqual(PracticeType.ayahReflection.displayName, "Ayah Reflection")
        XCTAssertEqual(PracticeType.quickDhikr.displayName, "Quick Dhikr")
        XCTAssertEqual(PracticeType.dailyHadith.displayName, "Daily Hadith")
    }

    func test_practiceType_icons() {
        for type in PracticeType.allCases {
            XCTAssertFalse(type.icon.isEmpty)
        }
    }

    func test_practiceType_estimatedMinutes() {
        XCTAssertEqual(PracticeType.ayahReflection.estimatedMinutes, 2)
        XCTAssertEqual(PracticeType.quickDhikr.estimatedMinutes, 1)
        XCTAssertEqual(PracticeType.dailyHadith.estimatedMinutes, 1)
    }

    func test_codable_roundTrip() throws {
        let session = PracticeSession(type: .quickDhikr, content: .dhikr(phrase: "SubhanAllah", targetCount: 33))
        let data = try JSONEncoder().encode(session)
        let decoded = try JSONDecoder().decode(PracticeSession.self, from: data)
        XCTAssertEqual(decoded.type, session.type)
        XCTAssertEqual(decoded.id, session.id)
    }
}
