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
    case duaAdhkar = "dua_adhkar"
    case tasbeehCounter = "tasbeeh_counter"
    case islamicCalendar = "islamic_calendar"
    case gamification = "gamification"
    case learning = "learning"
    case familyCircle = "family_circle"
    case ramadanMode = "ramadan_mode"
    case windDown = "wind_down"
    case zakatCalculator = "zakat_calculator"
    case namesOfAllah = "names_of_allah"

    // Platform Features
    case widgets = "widgets"
    case liveActivities = "live_activities"
    case siriShortcuts = "siri_shortcuts"
    case focusMode = "focus_mode"

    // Advanced Features (Enabled - Implementation complete)
    case spotlightSearch = "spotlight_search"
    case calendarExport = "calendar_export"
    case prayerCalendarExport = "prayer_calendar_export"
    case healthKitSync = "healthkit_sync"
    case predictiveDownload = "predictive_download"
    case smartCleanup = "smart_cleanup"

    // Coming Soon Features (Disabled - requires iOS 18.4 or Widget extension)
    case aiCompanion = "ai_companion"
    case interactiveWidgets = "interactive_widgets"
    case standByMode = "standby_mode"

    var displayName: String {
        switch self {
        case .prayerTimes: return "Prayer Times"
        case .qiblaCompass: return "Qibla Compass"
        case .quranReader: return "Quran Reader"
        case .hadithCollection: return "Hadith Collection"
        case .duaAdhkar: return "Dua & Adhkar"
        case .tasbeehCounter: return "Tasbeeh Counter"
        case .islamicCalendar: return "Islamic Calendar"
        case .gamification: return "Gamification"
        case .learning: return "Learning"
        case .familyCircle: return "Family Circle"
        case .ramadanMode: return "Ramadan Mode"
        case .windDown: return "Wind Down"
        case .zakatCalculator: return "Zakat Calculator"
        case .namesOfAllah: return "99 Names of Allah"
        case .widgets: return "Widgets"
        case .liveActivities: return "Live Activities"
        case .siriShortcuts: return "Siri Shortcuts"
        case .focusMode: return "Focus Mode"
        case .aiCompanion: return "AI Companion"
        case .interactiveWidgets: return "Interactive Widgets"
        case .standByMode: return "StandBy Mode"
        case .spotlightSearch: return "Spotlight Search"
        case .calendarExport: return "Calendar Export"
        case .prayerCalendarExport: return "Prayer Time Calendar"
        case .healthKitSync: return "Apple Health Sync"
        case .predictiveDownload: return "Predictive Download"
        case .smartCleanup: return "Smart Cleanup"
        }
    }

    var isEnabledByDefault: Bool {
        switch self {
        // Requires iOS 18.4+ for Apple Foundation Models
        case .aiCompanion:
            return false
        // Content not yet ready
        case .learning:
            return false
        // Debug override — not a user-facing feature
        case .ramadanMode:
            return false
        // Requires Widget extension target setup in Xcode
        case .interactiveWidgets,
             .standByMode:
            return false
        default:
            return true
        }
    }
}

// MARK: - Feature Flags Manager

@Observable
final class FeatureFlags {
    static let shared = FeatureFlags()

    private var overrides: [Feature: Bool] = [:]
    private let storageKey = "com.safa.featureFlags"

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

// MARK: - Convenience Extensions

extension FeatureFlags {
    var aiCompanionAvailable: Bool {
        isEnabled(.aiCompanion)
    }

    var interactiveWidgetsAvailable: Bool {
        isEnabled(.interactiveWidgets)
    }

    var spotlightSearchAvailable: Bool {
        isEnabled(.spotlightSearch)
    }

    var calendarExportAvailable: Bool {
        isEnabled(.calendarExport)
    }

    var healthKitSyncAvailable: Bool {
        isEnabled(.healthKitSync)
    }
}
