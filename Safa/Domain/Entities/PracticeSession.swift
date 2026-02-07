// MARK: - PracticeSession.swift
// PURPOSE: Model for micro-practice sessions (1-3 minute focused actions)
// DEPENDENCIES: Foundation

import Foundation

// MARK: - Practice Session

struct PracticeSession: Identifiable, Codable {
    let id: UUID
    let type: PracticeType
    let startedAt: Date
    var completedAt: Date?
    var content: PracticeContent

    var isCompleted: Bool { completedAt != nil }

    var durationSeconds: Int {
        guard let completed = completedAt else { return 0 }
        return Int(completed.timeIntervalSince(startedAt))
    }

    init(type: PracticeType, content: PracticeContent) {
        self.id = UUID()
        self.type = type
        self.startedAt = Date()
        self.completedAt = nil
        self.content = content
    }
}

// MARK: - Practice Type

enum PracticeType: String, Codable, CaseIterable, Identifiable {
    case ayahReflection = "ayah_reflection"
    case quickDhikr = "quick_dhikr"
    case dailyHadith = "daily_hadith"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ayahReflection: return "Ayah Reflection"
        case .quickDhikr: return "Quick Dhikr"
        case .dailyHadith: return "Daily Hadith"
        }
    }

    var icon: String {
        switch self {
        case .ayahReflection: return "book.fill"
        case .quickDhikr: return "hands.sparkles.fill"
        case .dailyHadith: return "text.book.closed.fill"
        }
    }

    var estimatedMinutes: Int {
        switch self {
        case .ayahReflection: return 2
        case .quickDhikr: return 1
        case .dailyHadith: return 1
        }
    }
}

// MARK: - Practice Content

enum PracticeContent: Codable {
    case ayah(surah: Int, ayah: Int)
    case dhikr(phrase: String, targetCount: Int)
    case hadith(text: String, narrator: String)
}
