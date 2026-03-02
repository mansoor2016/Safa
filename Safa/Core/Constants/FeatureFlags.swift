// MARK: - FeatureFlags.swift
// PURPOSE: Feature toggle management for enabling/disabling features
// DEPENDENCIES: Foundation

import Foundation

// MARK: - Feature Flag

enum Feature: String, CaseIterable {
    // Core Features (Enabled)
    case prayerTimes = "prayer_times"
    case qiblaCompass = "qibla_compass"
    case quranReader = "quran_reader"
    case hadithCollection = "hadith_collection"
    case duaDhikr = "dua_dhikr"
    case tasbeehCounter = "tasbeeh_counter"
    case islamicCalendar = "islamic_calendar"
    case gamification = "gamification"
    case learning = "learning"
    case ramadanMode = "ramadan_mode"
    case forceEidAlFitr = "force_eid_al_fitr"
    case forceEidAlAdha = "force_eid_al_adha"
    case forcePrayerPage = "force_prayer_page"
    case windDown = "wind_down"
    case namesOfAllah = "names_of_allah"

    // Platform Features
    case widgets = "widgets"
    case liveActivities = "live_activities"
    case siriShortcuts = "siri_shortcuts"
    case focusMode = "focus_mode"

    // Advanced Features (Enabled - Implementation complete)
    case spotlightSearch = "spotlight_search"
    case calendarExport = "calendar_export"
    case healthKitSync = "healthkit_sync"
    case predictiveDownload = "predictive_download"
    case smartCleanup = "smart_cleanup"

    // AI (runtime-gated by LLMService.availability)
    case aiCompanion = "ai_companion"

    // Coming Soon Features (Disabled - partially implemented or requires additional work)
    case interactiveWidgets = "interactive_widgets"

    var displayName: String {
        switch self {
        case .prayerTimes: return "Prayer Times"
        case .qiblaCompass: return "Qibla Compass"
        case .quranReader: return "Quran Reader"
        case .hadithCollection: return "Hadith Collection"
        case .duaDhikr: return "Dua & Dhikr"
        case .tasbeehCounter: return "Tasbeeh Counter"
        case .islamicCalendar: return "Islamic Calendar"
        case .gamification: return "Gamification"
        case .learning: return "Learning"
        case .ramadanMode: return "Ramadan Mode"
        case .forceEidAlFitr: return "Force Eid al-Fitr"
        case .forceEidAlAdha: return "Force Eid al-Adha"
        case .forcePrayerPage: return "Force Prayer Page"
        case .windDown: return "Wind Down"
        case .namesOfAllah: return "99 Names of Allah"
        case .widgets: return "Widgets"
        case .liveActivities: return "Live Activities"
        case .siriShortcuts: return "Siri Shortcuts"
        case .focusMode: return "Focus Mode"
        case .aiCompanion: return "AI Companion"
        case .interactiveWidgets: return "Interactive Widgets"
        case .spotlightSearch: return "Spotlight Search"
        case .calendarExport: return "Calendar Export"
        case .healthKitSync: return "Apple Health Sync"
        case .predictiveDownload: return "Predictive Download"
        case .smartCleanup: return "Smart Cleanup"
        }
    }

    var isEnabledByDefault: Bool {
        switch self {
        // Auto-enabled on iOS 26+; disabled on older OS where Foundation Models aren't available
        case .aiCompanion:
            if #available(iOS 26, *) { return true }
            return false
        // Content not yet ready
        case .learning:
            return false
        // Debug overrides — not user-facing features
        case .ramadanMode, .forceEidAlFitr, .forceEidAlAdha, .forcePrayerPage:
            return false
        // Requires Widget extension target setup in Xcode
        case .interactiveWidgets:
            return false
        default:
            return true
        }
    }
}

// MARK: - Feature Flags Manager

final class FeatureFlags {
    static let shared = FeatureFlags()

    private var overrides: [Feature: Bool] = [:]
    private let storageKey = AppConstants.StorageKeys.featureFlags

    private init() {
        loadOverrides()
    }

    // MARK: - Public Methods

    func isEnabled(_ feature: Feature) -> Bool {
        // Check for override first
        if let override = overrides[feature] {
            return override
        }

        return feature.isEnabledByDefault
    }

    func isDisabled(_ feature: Feature) -> Bool {
        !isEnabled(feature)
    }

    func setOverride(_ feature: Feature, enabled: Bool) {
        overrides[feature] = enabled
        saveOverrides()
    }

    func removeOverride(_ feature: Feature) {
        overrides.removeValue(forKey: feature)
        saveOverrides()
    }

    func resetAllOverrides() {
        overrides.removeAll()
        saveOverrides()
    }

    // MARK: - Persistence

    private func loadOverrides() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([String: Bool].self, from: data) else {
            return
        }

        for (key, value) in decoded {
            if let feature = Feature(rawValue: key) {
                overrides[feature] = value
            }
        }
    }

    private func saveOverrides() {
        let encoded: [String: Bool] = overrides.reduce(into: [:]) { result, pair in
            result[pair.key.rawValue] = pair.value
        }

        if let data = try? JSONEncoder().encode(encoded) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
