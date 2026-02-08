// MARK: - QuranTranslationAccuracyTests.swift
// PURPOSE: Spot-check 10 well-known ayahs for translation accuracy
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

final class QuranTranslationAccuracyTests: XCTestCase {

    private var sut: QuranRepository!

    override func setUp() {
        super.setUp()
        sut = QuranRepository(coreData: CoreDataStack.shared)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Spot Check: 10 Well-Known Ayahs

    /// Al-Fatiha 1:1 — Bismillah
    func test_fatiha_1_1_bismillah() async throws {
        let ayah = try await sut.getAyah(surah: 1, ayah: 1)
        XCTAssertNotNil(ayah, "Ayah 1:1 should exist")
        XCTAssertTrue(
            ayah!.textTranslation.contains("name of Allah"),
            "1:1 should contain 'name of Allah'. Got: \(ayah!.textTranslation)"
        )
    }

    /// Al-Fatiha 1:2 — Alhamdulillah
    func test_fatiha_1_2_praise() async throws {
        let ayah = try await sut.getAyah(surah: 1, ayah: 2)
        XCTAssertNotNil(ayah)
        XCTAssertTrue(
            ayah!.textTranslation.contains("praise") || ayah!.textTranslation.contains("Praise"),
            "1:2 should mention praise. Got: \(ayah!.textTranslation)"
        )
    }

    /// Al-Baqarah 2:255 — Ayat al-Kursi
    func test_baqarah_2_255_ayatAlKursi() async throws {
        let ayah = try await sut.getAyah(surah: 2, ayah: 255)
        XCTAssertNotNil(ayah)
        let text = ayah!.textTranslation
        XCTAssertTrue(text.contains("Allah") || text.contains("God"), "2:255 should mention Allah")
        XCTAssertTrue(text.contains("slumber") || text.contains("sleep") || text.contains("drowsiness"),
                      "2:255 Ayat al-Kursi should reference no slumber/sleep. Got: \(text)")
    }

    /// Al-Ikhlas 112:1 — Tawheed
    func test_ikhlas_112_1_tawheed() async throws {
        let ayah = try await sut.getAyah(surah: 112, ayah: 1)
        XCTAssertNotNil(ayah)
        XCTAssertTrue(
            ayah!.textTranslation.lowercased().contains("one"),
            "112:1 should reference 'One'. Got: \(ayah!.textTranslation)"
        )
    }

    /// Al-Ikhlas 112:4 — None comparable
    func test_ikhlas_112_4_noneComparable() async throws {
        let ayah = try await sut.getAyah(surah: 112, ayah: 4)
        XCTAssertNotNil(ayah)
        XCTAssertTrue(
            ayah!.textTranslation.lowercased().contains("equivalent") ||
            ayah!.textTranslation.lowercased().contains("comparable") ||
            ayah!.textTranslation.lowercased().contains("equal"),
            "112:4 should mention equivalent/comparable. Got: \(ayah!.textTranslation)"
        )
    }

    /// An-Nas 114:1 — Seek refuge in Lord of mankind
    func test_nas_114_1_seekRefuge() async throws {
        let ayah = try await sut.getAyah(surah: 114, ayah: 1)
        XCTAssertNotNil(ayah)
        let text = ayah!.textTranslation.lowercased()
        XCTAssertTrue(
            text.contains("refuge") || text.contains("seek"),
            "114:1 should mention refuge/seek. Got: \(ayah!.textTranslation)"
        )
        XCTAssertTrue(
            text.contains("mankind") || text.contains("people") || text.contains("men"),
            "114:1 should mention mankind/people. Got: \(ayah!.textTranslation)"
        )
    }

    /// Yasin 36:1 — Ya-Sin
    func test_yasin_36_1() async throws {
        let ayah = try await sut.getAyah(surah: 36, ayah: 1)
        XCTAssertNotNil(ayah, "Ayah 36:1 should exist")
        // Ya-Sin is a muqatta'at (disconnected letters)
        let arabic = ayah!.textArabic
        XCTAssertFalse(arabic.isEmpty, "36:1 should have Arabic text")
    }

    /// Al-Baqarah 2:286 — Last ayah, burden beyond capacity
    func test_baqarah_2_286_noburdenBeyondCapacity() async throws {
        let ayah = try await sut.getAyah(surah: 2, ayah: 286)
        XCTAssertNotNil(ayah)
        let text = ayah!.textTranslation.lowercased()
        XCTAssertTrue(
            text.contains("burden") || text.contains("capacity") || text.contains("bear"),
            "2:286 should mention burden/capacity. Got: \(ayah!.textTranslation)"
        )
    }

    /// Ar-Rahman 55:13 — Which favors will you deny
    func test_rahman_55_13_whichFavors() async throws {
        let ayah = try await sut.getAyah(surah: 55, ayah: 13)
        XCTAssertNotNil(ayah)
        let text = ayah!.textTranslation.lowercased()
        XCTAssertTrue(
            text.contains("favors") || text.contains("blessings") || text.contains("deny"),
            "55:13 should mention favors/deny. Got: \(ayah!.textTranslation)"
        )
    }

    /// Al-Asr 103:2 — Mankind is in loss
    func test_asr_103_2_mankindInLoss() async throws {
        let ayah = try await sut.getAyah(surah: 103, ayah: 2)
        XCTAssertNotNil(ayah)
        let text = ayah!.textTranslation.lowercased()
        XCTAssertTrue(
            text.contains("loss") || text.contains("man"),
            "103:2 should mention loss/mankind. Got: \(ayah!.textTranslation)"
        )
    }
}
