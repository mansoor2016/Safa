// MARK: - Log.swift
// PURPOSE: Structured logging via os.Logger — one category per feature for Console.app filtering
// DEPENDENCIES: OSLog

import OSLog

enum Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "Mawj.Safa"

    static let quran = Logger(subsystem: subsystem, category: "Quran")
    static let hadith = Logger(subsystem: subsystem, category: "Hadith")
    static let audio = Logger(subsystem: subsystem, category: "Audio")
    static let downloads = Logger(subsystem: subsystem, category: "Downloads")
    static let coreData = Logger(subsystem: subsystem, category: "CoreData")
    static let notifications = Logger(subsystem: subsystem, category: "Notifications")
    static let spotlight = Logger(subsystem: subsystem, category: "Spotlight")
    static let haptics = Logger(subsystem: subsystem, category: "Haptics")
    static let calendar = Logger(subsystem: subsystem, category: "Calendar")
    static let storage = Logger(subsystem: subsystem, category: "Storage")
    static let healthKit = Logger(subsystem: subsystem, category: "HealthKit")
    static let focusMode = Logger(subsystem: subsystem, category: "FocusMode")
}
