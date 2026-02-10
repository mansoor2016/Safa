// MARK: - AutoScrollTests.swift
// PURPOSE: Tests for auto-scroll speed and default state
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

final class AutoScrollSpeedTests: XCTestCase {

    // MARK: - Label Tests

    func test_halfSpeed_label() {
        XCTAssertEqual(AutoScrollSpeed.half.label, "0.5x")
    }

    func test_normalSpeed_label() {
        XCTAssertEqual(AutoScrollSpeed.normal.label, "1x")
    }

    func test_doubleSpeed_label() {
        XCTAssertEqual(AutoScrollSpeed.double.label, "2x")
    }

    func test_tripleSpeed_label() {
        XCTAssertEqual(AutoScrollSpeed.triple.label, "3x")
    }

    // MARK: - Raw Value Tests

    func test_halfSpeed_rawValue() {
        XCTAssertEqual(AutoScrollSpeed.half.rawValue, 0.5)
    }

    func test_normalSpeed_rawValue() {
        XCTAssertEqual(AutoScrollSpeed.normal.rawValue, 1.0)
    }

    func test_doubleSpeed_rawValue() {
        XCTAssertEqual(AutoScrollSpeed.double.rawValue, 2.0)
    }

    func test_tripleSpeed_rawValue() {
        XCTAssertEqual(AutoScrollSpeed.triple.rawValue, 3.0)
    }

    // MARK: - All Cases

    func test_allCases_hasFourSpeeds() {
        XCTAssertEqual(AutoScrollSpeed.allCases.count, 4)
    }

    // MARK: - Timer Interval

    func test_timerInterval_halfSpeed() {
        // 3.0 / 0.5 = 6 seconds per ayah
        let interval = 3.0 / AutoScrollSpeed.half.rawValue
        XCTAssertEqual(interval, 6.0)
    }

    func test_timerInterval_normalSpeed() {
        // 3.0 / 1.0 = 3 seconds per ayah
        let interval = 3.0 / AutoScrollSpeed.normal.rawValue
        XCTAssertEqual(interval, 3.0)
    }

    func test_timerInterval_tripleSpeed() {
        // 3.0 / 3.0 = 1 second per ayah
        let interval = 3.0 / AutoScrollSpeed.triple.rawValue
        XCTAssertEqual(interval, 1.0)
    }
}

// MARK: - ViewModel Auto-Scroll State

@MainActor
final class AutoScrollViewModelTests: XCTestCase {
    var sut: AyahReaderViewModel!
    var mockRepository: TestableQuranRepository!

    override func setUp() {
        super.setUp()
        mockRepository = TestableQuranRepository()
        sut = AyahReaderViewModel(surahNumber: 1, repository: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    func test_defaultAutoScrollState_isNotScrolling() {
        XCTAssertFalse(sut.isAutoScrolling)
    }

    func test_defaultAutoScrollSpeed_isNormal() {
        XCTAssertEqual(sut.autoScrollSpeed, .normal)
    }
}
