// MARK: - Dependencies.swift
// PURPOSE: Dependency injection container providing all app services and repositories
// DEPENDENCIES: Foundation, Domain protocols

import Foundation

@Observable
final class Dependencies {
    // MARK: - Shared Instance (for use outside SwiftUI Environment)
    static let shared = Dependencies()

    // MARK: - Core Data Stack
    let coreDataStack: CoreDataStack

    // MARK: - Repositories
    let prayerRepository: PrayerRepositoryProtocol
    let quranRepository: QuranRepositoryProtocol
    let hadithRepository: HadithRepositoryProtocol
    let duaRepository: DuaRepositoryProtocol
    let userRepository: UserRepositoryProtocol
    let learningRepository: LearningRepositoryProtocol
    let chatRepository: ChatRepositoryProtocol

    // MARK: - Services
    let locationService: LocationService
    let audioPlayerService: AudioPlayerService
    let llmService: LLMService
    let ragService: RAGService
    let pronunciationService: PronunciationService
    let ramadanService: RamadanService

    // MARK: - Global State
    let userState: UserStateManager

    // MARK: - Launch Cache (precomputed at app startup for instant home rendering)
    var cachedTodayPrayers: [PrayerTime]?

    // MARK: - Init
    init() {
        // Initialize Core Data stack
        self.coreDataStack = CoreDataStack.shared

        // Initialize repositories
        self.prayerRepository = PrayerRepository(coreData: coreDataStack)
        self.quranRepository = QuranRepository(coreData: coreDataStack)
        self.hadithRepository = HadithRepository(coreData: coreDataStack)
        self.duaRepository = DuaRepository(coreData: coreDataStack)
        self.userRepository = UserRepository(coreData: coreDataStack)
        self.learningRepository = LearningRepository(coreData: coreDataStack)

        // Initialize services
        self.locationService = LocationService()
        self.audioPlayerService = AudioPlayerService()
        self.llmService = LLMService()
        self.pronunciationService = PronunciationService()
        self.ramadanService = RamadanService()

        // Initialize RAG service (depends on repositories)
        self.ragService = RAGService(
            quranRepository: quranRepository,
            hadithRepository: hadithRepository
        )

        // Configure LLM with RAG service
        self.llmService.configure(ragService: ragService)

        // Initialize chat repository (depends on LLM service)
        self.chatRepository = ChatRepository(llmService: llmService)

        // Initialize global state (depends on user repository)
        self.userState = UserStateManager(userRepository: userRepository)

        // Configure preferences manager (must happen after userRepository init)
        PreferencesManager.shared.configure(userRepository: userRepository)

        // Configure Live Activity manager (needs prayer repo + location for ensureActivityIfNeeded)
        PrayerLiveActivityManager.shared.configure(
            prayerRepository: prayerRepository,
            locationService: locationService
        )
    }
}
