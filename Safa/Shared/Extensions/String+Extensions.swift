// MARK: - String+Extensions.swift
// PURPOSE: String utilities and formatting extensions
// DEPENDENCIES: Foundation

import Foundation

extension String {
    // MARK: - Validation

    var isBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isNotBlank: Bool {
        !isBlank
    }

    // MARK: - Trimming

    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Arabic Text

    var isArabic: Bool {
        guard let firstChar = first else { return false }
        return firstChar.unicodeScalars.first.map { scalar in
            // Arabic Unicode range: 0x0600 to 0x06FF
            (0x0600...0x06FF).contains(scalar.value)
        } ?? false
    }

    var containsArabic: Bool {
        unicodeScalars.contains { (0x0600...0x06FF).contains($0.value) }
    }

    var arabicNumerals: String {
        let arabicNumerals = ["٠", "١", "٢", "٣", "٤", "٥", "٦", "٧", "٨", "٩"]
        var result = self
        for (index, numeral) in arabicNumerals.enumerated() {
            result = result.replacingOccurrences(of: String(index), with: numeral)
        }
        return result
    }

    // MARK: - Truncation

    func truncated(to length: Int, trailing: String = "...") -> String {
        if count > length {
            return String(prefix(length)) + trailing
        }
        return self
    }

    // MARK: - Word Count

    var wordCount: Int {
        let words = components(separatedBy: .whitespacesAndNewlines)
        return words.filter { !$0.isEmpty }.count
    }

    // MARK: - Localization

    var localized: String {
        NSLocalizedString(self, comment: "")
    }

    func localized(with arguments: CVarArg...) -> String {
        String(format: NSLocalizedString(self, comment: ""), arguments: arguments)
    }

    // MARK: - URL Encoding

    var urlEncoded: String? {
        addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }

    // MARK: - Safe Subscript

    subscript(safe range: Range<Int>) -> String? {
        guard range.lowerBound >= 0,
              range.upperBound <= count else {
            return nil
        }
        let startIndex = index(self.startIndex, offsetBy: range.lowerBound)
        let endIndex = index(self.startIndex, offsetBy: range.upperBound)
        return String(self[startIndex..<endIndex])
    }

    // MARK: - Regex

    func matches(_ regex: String) -> Bool {
        range(of: regex, options: .regularExpression) != nil
    }

    // MARK: - Capitalization

    var capitalizedFirstLetter: String {
        guard let first = first else { return self }
        return first.uppercased() + dropFirst()
    }
}

// MARK: - Optional String Extension

extension Optional where Wrapped == String {
    var isNilOrEmpty: Bool {
        self?.isEmpty ?? true
    }

    var isNotNilOrEmpty: Bool {
        !isNilOrEmpty
    }
}
