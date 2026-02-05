// MARK: - StringExtensionTests.swift
// PURPOSE: Unit tests for String extension utilities
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

final class StringExtensionTests: XCTestCase {

    // MARK: - isBlank Tests

    func test_isBlank_emptyString() {
        XCTAssertTrue("".isBlank)
    }

    func test_isBlank_whitespaceOnly() {
        XCTAssertTrue("   ".isBlank)
    }

    func test_isBlank_newlineOnly() {
        XCTAssertTrue("\n".isBlank)
    }

    func test_isBlank_tabOnly() {
        XCTAssertTrue("\t".isBlank)
    }

    func test_isBlank_mixedWhitespace() {
        XCTAssertTrue("  \n\t  ".isBlank)
    }

    func test_isBlank_withContent() {
        XCTAssertFalse("hello".isBlank)
    }

    func test_isBlank_withContentAndWhitespace() {
        XCTAssertFalse("  hello  ".isBlank)
    }

    // MARK: - isNotBlank Tests

    func test_isNotBlank_emptyString() {
        XCTAssertFalse("".isNotBlank)
    }

    func test_isNotBlank_withContent() {
        XCTAssertTrue("hello".isNotBlank)
    }

    // MARK: - trimmed Tests

    func test_trimmed_removesLeadingWhitespace() {
        XCTAssertEqual("  hello".trimmed, "hello")
    }

    func test_trimmed_removesTrailingWhitespace() {
        XCTAssertEqual("hello  ".trimmed, "hello")
    }

    func test_trimmed_removesBothEnds() {
        XCTAssertEqual("  hello  ".trimmed, "hello")
    }

    func test_trimmed_removesNewlines() {
        XCTAssertEqual("\nhello\n".trimmed, "hello")
    }

    func test_trimmed_preservesMiddleSpaces() {
        XCTAssertEqual("  hello world  ".trimmed, "hello world")
    }

    // MARK: - isArabic Tests

    func test_isArabic_arabicText() {
        XCTAssertTrue("بسم".isArabic)
    }

    func test_isArabic_englishText() {
        XCTAssertFalse("hello".isArabic)
    }

    func test_isArabic_emptyString() {
        XCTAssertFalse("".isArabic)
    }

    func test_isArabic_arabicWithDiacritics() {
        XCTAssertTrue("بِسْمِ".isArabic)
    }

    func test_isArabic_mixedStartsWithEnglish() {
        XCTAssertFalse("hello بسم".isArabic)
    }

    func test_isArabic_mixedStartsWithArabic() {
        XCTAssertTrue("بسم hello".isArabic)
    }

    // MARK: - containsArabic Tests

    func test_containsArabic_pureArabic() {
        XCTAssertTrue("بسم الله".containsArabic)
    }

    func test_containsArabic_pureEnglish() {
        XCTAssertFalse("hello world".containsArabic)
    }

    func test_containsArabic_mixed() {
        XCTAssertTrue("In the name of الله".containsArabic)
    }

    func test_containsArabic_emptyString() {
        XCTAssertFalse("".containsArabic)
    }

    // MARK: - arabicNumerals Tests

    func test_arabicNumerals_singleDigit() {
        XCTAssertEqual("1".arabicNumerals, "١")
    }

    func test_arabicNumerals_multipleDigits() {
        XCTAssertEqual("123".arabicNumerals, "١٢٣")
    }

    func test_arabicNumerals_allDigits() {
        XCTAssertEqual("0123456789".arabicNumerals, "٠١٢٣٤٥٦٧٨٩")
    }

    func test_arabicNumerals_mixedContent() {
        XCTAssertEqual("Surah 1, Ayah 5".arabicNumerals, "Surah ١, Ayah ٥")
    }

    func test_arabicNumerals_noDigits() {
        XCTAssertEqual("hello".arabicNumerals, "hello")
    }

    // MARK: - truncated Tests

    func test_truncated_shorterThanLimit() {
        XCTAssertEqual("hello".truncated(to: 10), "hello")
    }

    func test_truncated_exactlyAtLimit() {
        XCTAssertEqual("hello".truncated(to: 5), "hello")
    }

    func test_truncated_longerThanLimit() {
        XCTAssertEqual("hello world".truncated(to: 5), "hello...")
    }

    func test_truncated_customTrailing() {
        XCTAssertEqual("hello world".truncated(to: 5, trailing: "…"), "hello…")
    }

    func test_truncated_emptyString() {
        XCTAssertEqual("".truncated(to: 5), "")
    }

    func test_truncated_zeroLimit() {
        XCTAssertEqual("hello".truncated(to: 0), "...")
    }

    // MARK: - wordCount Tests

    func test_wordCount_singleWord() {
        XCTAssertEqual("hello".wordCount, 1)
    }

    func test_wordCount_multipleWords() {
        XCTAssertEqual("hello world foo bar".wordCount, 4)
    }

    func test_wordCount_emptyString() {
        XCTAssertEqual("".wordCount, 0)
    }

    func test_wordCount_whitespaceOnly() {
        XCTAssertEqual("   ".wordCount, 0)
    }

    func test_wordCount_extraWhitespace() {
        XCTAssertEqual("hello   world".wordCount, 2)
    }

    func test_wordCount_newlines() {
        XCTAssertEqual("hello\nworld".wordCount, 2)
    }

    // MARK: - urlEncoded Tests

    func test_urlEncoded_noSpecialChars() {
        XCTAssertEqual("hello".urlEncoded, "hello")
    }

    func test_urlEncoded_withSpaces() {
        XCTAssertEqual("hello world".urlEncoded, "hello%20world")
    }

    func test_urlEncoded_withSpecialChars() {
        XCTAssertNotNil("hello&world=test".urlEncoded)
    }

    // MARK: - Safe Subscript Tests

    func test_safeSubscript_validRange() {
        XCTAssertEqual("hello"[safe: 0..<3], "hel")
    }

    func test_safeSubscript_fullRange() {
        XCTAssertEqual("hello"[safe: 0..<5], "hello")
    }

    func test_safeSubscript_outOfBounds() {
        XCTAssertNil("hello"[safe: 0..<10])
    }

    func test_safeSubscript_negativeStart() {
        XCTAssertNil("hello"[safe: -1..<3])
    }

    func test_safeSubscript_emptyRange() {
        XCTAssertEqual("hello"[safe: 2..<2], "")
    }

    // MARK: - matches Tests

    func test_matches_simplePattern() {
        XCTAssertTrue("hello123".matches("\\d+"))
    }

    func test_matches_emailPattern() {
        XCTAssertTrue("test@example.com".matches("[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"))
    }

    func test_matches_noMatch() {
        XCTAssertFalse("hello".matches("\\d+"))
    }

    func test_matches_emptyString() {
        XCTAssertFalse("".matches("\\d+"))
    }

    // MARK: - capitalizedFirstLetter Tests

    func test_capitalizedFirstLetter_lowercase() {
        XCTAssertEqual("hello".capitalizedFirstLetter, "Hello")
    }

    func test_capitalizedFirstLetter_alreadyCapitalized() {
        XCTAssertEqual("Hello".capitalizedFirstLetter, "Hello")
    }

    func test_capitalizedFirstLetter_allCaps() {
        XCTAssertEqual("HELLO".capitalizedFirstLetter, "HELLO")
    }

    func test_capitalizedFirstLetter_emptyString() {
        XCTAssertEqual("".capitalizedFirstLetter, "")
    }

    func test_capitalizedFirstLetter_singleChar() {
        XCTAssertEqual("h".capitalizedFirstLetter, "H")
    }

    func test_capitalizedFirstLetter_multiWord() {
        XCTAssertEqual("hello world".capitalizedFirstLetter, "Hello world")
    }

    // MARK: - Optional String Tests

    func test_isNilOrEmpty_nilString() {
        let str: String? = nil
        XCTAssertTrue(str.isNilOrEmpty)
    }

    func test_isNilOrEmpty_emptyString() {
        let str: String? = ""
        XCTAssertTrue(str.isNilOrEmpty)
    }

    func test_isNilOrEmpty_nonEmptyString() {
        let str: String? = "hello"
        XCTAssertFalse(str.isNilOrEmpty)
    }

    func test_isNotNilOrEmpty_nilString() {
        let str: String? = nil
        XCTAssertFalse(str.isNotNilOrEmpty)
    }

    func test_isNotNilOrEmpty_emptyString() {
        let str: String? = ""
        XCTAssertFalse(str.isNotNilOrEmpty)
    }

    func test_isNotNilOrEmpty_nonEmptyString() {
        let str: String? = "hello"
        XCTAssertTrue(str.isNotNilOrEmpty)
    }
}
