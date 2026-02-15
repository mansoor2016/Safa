// MARK: - SilentModeTipService.swift
// PURPOSE: One-time tip helper for silent mode awareness when adhan is enabled
// DEPENDENCIES: Foundation, AppConstants

import Foundation

struct SilentModeTipService {
    static func shouldShowTip(
        defaults: UserDefaults = .standard
    ) -> Bool {
        let key = AppConstants.StorageKeys.adhanSilentModeTipShown
        return !defaults.bool(forKey: key)
    }

    static func markTipShown(
        defaults: UserDefaults = .standard
    ) {
        let key = AppConstants.StorageKeys.adhanSilentModeTipShown
        defaults.set(true, forKey: key)
    }
}
