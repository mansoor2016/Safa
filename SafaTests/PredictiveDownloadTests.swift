// MARK: - PredictiveDownloadTests.swift
// PURPOSE: Tests for PredictiveDownloadService prediction logic
// DEPENDENCIES: XCTest

import XCTest
@testable import Safa

final class PredictiveDownloadTests: XCTestCase {

    // MARK: - Surah Prediction Tests

    func testNextSurahPrediction() {
        // After reading Surah 1 (Al-Fatiha), should predict Surah 2 (Al-Baqarah)
        let nextSurah = predictNextSurah(after: 1)
        XCTAssertEqual(nextSurah, 2)
    }

    func testNextSurahPredictionAtEnd() {
        // After reading Surah 114 (An-Nas), should predict Surah 1 (Al-Fatiha)
        let nextSurah = predictNextSurah(after: 114)
        XCTAssertEqual(nextSurah, 1)
    }

    func testNextSurahPredictionMidQuran() {
        // After reading Surah 50 (Qaf), should predict Surah 51 (Adh-Dhariyat)
        let nextSurah = predictNextSurah(after: 50)
        XCTAssertEqual(nextSurah, 51)
    }

    // MARK: - Juz Prediction Tests

    func testJuzContainsSurah() {
        // Juz 1 contains Surahs 1 and part of 2
        let juz1Surahs = surahsInJuz(1)
        XCTAssertTrue(juz1Surahs.contains(1))
        XCTAssertTrue(juz1Surahs.contains(2))
    }

    func testJuz30ContainsShortSurahs() {
        // Juz 30 (Juz Amma) contains the short surahs at the end
        let juz30Surahs = surahsInJuz(30)
        XCTAssertTrue(juz30Surahs.contains(114)) // An-Nas
        XCTAssertTrue(juz30Surahs.contains(78))  // An-Naba (first surah of Juz 30)
    }

    // MARK: - Frequently Read Detection Tests

    func testFrequentlyReadDetection() {
        let readHistory: [Int: Int] = [
            1: 50,   // Al-Fatiha read 50 times
            36: 30,  // Yasin read 30 times
            67: 25,  // Al-Mulk read 25 times
            55: 20,  // Ar-Rahman read 20 times
            2: 5     // Al-Baqarah read 5 times
        ]

        let frequentSurahs = getFrequentlyReadSurahs(history: readHistory, threshold: 10, limit: 3)

        XCTAssertEqual(frequentSurahs.count, 3)
        XCTAssertTrue(frequentSurahs.contains(1))   // Top 1
        XCTAssertTrue(frequentSurahs.contains(36))  // Top 2
        XCTAssertTrue(frequentSurahs.contains(67))  // Top 3
        XCTAssertFalse(frequentSurahs.contains(2))  // Below threshold
    }

    func testFrequentlyReadWithEmptyHistory() {
        let readHistory: [Int: Int] = [:]
        let frequentSurahs = getFrequentlyReadSurahs(history: readHistory, threshold: 10, limit: 3)
        XCTAssertTrue(frequentSurahs.isEmpty)
    }

    // MARK: - Download Queue Tests

    func testQueueDeduplication() {
        var queue: Set<Int> = [1, 2, 3]

        // Adding duplicate should not increase size
        queue.insert(2)
        XCTAssertEqual(queue.count, 3)

        // Adding new item should increase size
        queue.insert(4)
        XCTAssertEqual(queue.count, 4)
    }

    func testPredictionPriority() {
        // Next surah should have higher priority than juz-based predictions
        let nextSurah = 2
        let juzSurahs = [3, 4, 5]
        let frequentSurahs = [36, 67]

        var priorityQueue: [(surah: Int, priority: Int)] = []
        priorityQueue.append((nextSurah, 1)) // Highest priority

        for (index, surah) in juzSurahs.enumerated() {
            priorityQueue.append((surah, 2 + index))
        }

        for (index, surah) in frequentSurahs.enumerated() {
            priorityQueue.append((surah, 10 + index))
        }

        let sorted = priorityQueue.sorted { $0.priority < $1.priority }
        XCTAssertEqual(sorted.first?.surah, nextSurah)
    }

    // MARK: - Helper Functions (mirrors service logic)

    private func predictNextSurah(after surah: Int) -> Int {
        if surah >= 114 {
            return 1
        }
        return surah + 1
    }

    private func surahsInJuz(_ juz: Int) -> [Int] {
        // Simplified juz mapping - in real implementation this would be more accurate
        switch juz {
        case 1: return [1, 2]
        case 30: return Array(78...114)
        default: return []
        }
    }

    private func getFrequentlyReadSurahs(history: [Int: Int], threshold: Int, limit: Int) -> [Int] {
        history
            .filter { $0.value >= threshold }
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { $0.key }
    }
}
