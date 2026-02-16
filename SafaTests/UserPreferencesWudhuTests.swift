import XCTest
@testable import Safa

final class UserPreferencesWudhuTests: XCTestCase {

    // MARK: - Helpers

    private func roundTrip(_ prefs: UserPreferences) throws -> UserPreferences {
        let data = try JSONEncoder().encode(prefs)
        return try JSONDecoder().decode(UserPreferences.self, from: data)
    }

    /// Encode prefs, strip wudhu keys from JSON, then decode — simulates old data.
    private func decodeWithoutWudhuKeys(_ prefs: UserPreferences) throws -> UserPreferences {
        let data = try JSONEncoder().encode(prefs)
        var json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        json.removeValue(forKey: "wudhuReminderEnabled")
        json.removeValue(forKey: "wudhuReminderMinutesBefore")
        let strippedData = try JSONSerialization.data(withJSONObject: json)
        return try JSONDecoder().decode(UserPreferences.self, from: strippedData)
    }

    /// Encode prefs, override a specific key, then decode.
    private func decodeWithOverride(_ prefs: UserPreferences, key: String, value: Any) throws -> UserPreferences {
        let data = try JSONEncoder().encode(prefs)
        var json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        json[key] = value
        let modifiedData = try JSONSerialization.data(withJSONObject: json)
        return try JSONDecoder().decode(UserPreferences.self, from: modifiedData)
    }

    // MARK: - Clamped Decode

    func test_wudhuReminderMinutes_clampedOnDecode() throws {
        let prefs = UserPreferences()
        let decoded = try decodeWithOverride(prefs, key: "wudhuReminderMinutesBefore", value: 99)
        XCTAssertEqual(decoded.wudhuReminderMinutesBefore, 15, "Invalid value 99 should clamp to default 15")
    }

    func test_wudhuReminderMinutes_clampsNegativeValue() throws {
        let prefs = UserPreferences()
        let decoded = try decodeWithOverride(prefs, key: "wudhuReminderMinutesBefore", value: -1)
        XCTAssertEqual(decoded.wudhuReminderMinutesBefore, 15, "Negative value should clamp to default 15")
    }

    func test_wudhuReminderMinutes_clampsZero() throws {
        let prefs = UserPreferences()
        let decoded = try decodeWithOverride(prefs, key: "wudhuReminderMinutesBefore", value: 0)
        XCTAssertEqual(decoded.wudhuReminderMinutesBefore, 15, "Zero should clamp to default 15")
    }

    // MARK: - Valid Values Preserved

    func test_wudhuReminderMinutes_validValuesPreserved() throws {
        for minutes in [5, 10, 15, 20] {
            var prefs = UserPreferences()
            prefs.wudhuReminderMinutesBefore = minutes
            let decoded = try roundTrip(prefs)
            XCTAssertEqual(decoded.wudhuReminderMinutesBefore, minutes,
                           "\(minutes) should survive round-trip")
        }
    }

    func test_wudhuReminderEnabled_roundTrips() throws {
        var prefs = UserPreferences()
        prefs.wudhuReminderEnabled = true
        let decoded = try roundTrip(prefs)
        XCTAssertTrue(decoded.wudhuReminderEnabled)
    }

    // MARK: - Backward Compatibility

    func test_wudhuReminder_backwardCompatibleDecode() throws {
        let prefs = UserPreferences()
        let decoded = try decodeWithoutWudhuKeys(prefs)

        XCTAssertFalse(decoded.wudhuReminderEnabled,
                       "Missing key should default to false")
        XCTAssertEqual(decoded.wudhuReminderMinutesBefore, 15,
                       "Missing key should default to 15")
    }
}
