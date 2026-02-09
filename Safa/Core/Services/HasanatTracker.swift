// MARK: - HasanatTracker.swift
// PURPOSE: Deduplication layer for hasanat awards — prevents double-awarding
// DEPENDENCIES: Foundation, UserStateManager

import Foundation

/// Lightweight dedup tracker using UserDefaults.
/// Two modes:
///   - `awardOnce(_:key:on:via:)` — date-scoped (prayers, daily verse, fasting)
///   - `awardOnceEver(_:key:via:)` — permanent (lesson completions, invite)
struct HasanatTracker {
    private static let prefix = "com.safa.hasanat.awarded."

    // MARK: - Date-Scoped Awards

    /// Award hasanat once per calendar day. Returns true if awarded, false if already claimed.
    @discardableResult
    static func awardOnce(
        _ award: HasanatAward,
        key: String,
        on date: Date = Date(),
        via userState: UserStateManager
    ) async -> Bool {
        let fullKey = dailyKey(key, on: date)
        guard !hasAwarded(fullKey) else { return false }
        markAwarded(fullKey)
        await userState.awardHasanat(award)
        return true
    }

    // MARK: - Permanent Awards

    /// Award hasanat once ever (across all time). Returns true if awarded, false if already claimed.
    @discardableResult
    static func awardOnceEver(
        _ award: HasanatAward,
        key: String,
        via userState: UserStateManager
    ) async -> Bool {
        let fullKey = permanentKey(key)
        guard !hasAwarded(fullKey) else { return false }
        markAwarded(fullKey)
        await userState.awardHasanat(award)
        return true
    }

    // MARK: - Query

    static func hasAwarded(_ fullKey: String) -> Bool {
        UserDefaults.standard.bool(forKey: fullKey)
    }

    static func markAwarded(_ fullKey: String) {
        UserDefaults.standard.set(true, forKey: fullKey)
    }

    // MARK: - Key Helpers

    static func dailyKey(_ key: String, on date: Date = Date()) -> String {
        let dateString = Self.dateFormatter.string(from: date)
        return "\(prefix)\(key)_\(dateString)"
    }

    static func permanentKey(_ key: String) -> String {
        "\(prefix)\(key)"
    }

    // MARK: - Pruning

    /// Remove tracker entries older than 7 days to prevent UserDefaults bloat.
    /// Call on app launch.
    static func pruneOldEntries() {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        let trackerKeys = allKeys.filter { $0.hasPrefix(prefix) }

        for key in trackerKeys {
            // Only prune date-scoped keys (they end with _YYYY-MM-DD)
            guard let dateString = extractDateSuffix(from: key),
                  let keyDate = dateFormatter.date(from: dateString) else {
                continue // Permanent key — keep it
            }
            if keyDate < cutoff {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }

    // MARK: - Private

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    /// Extract trailing date suffix like "2026-02-09" from a key.
    private static func extractDateSuffix(from key: String) -> String? {
        // Date-scoped keys end with _YYYY-MM-DD (11 chars: underscore + 10 date chars)
        guard key.count >= prefix.count + 12 else { return nil }
        let suffix = String(key.suffix(10))
        // Validate it's a date pattern
        guard suffix.count == 10,
              suffix[suffix.index(suffix.startIndex, offsetBy: 4)] == "-",
              suffix[suffix.index(suffix.startIndex, offsetBy: 7)] == "-" else {
            return nil
        }
        return suffix
    }
}
