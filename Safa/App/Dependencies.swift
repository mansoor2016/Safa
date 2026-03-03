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
    let ramadanService: RamadanService

    // MARK: - AI Pipeline
    let inputSafety: InputSafetyServiceProtocol
    let outputSafety: OutputSafetyServiceProtocol
    let citationValidation: CitationValidationServiceProtocol
    let chatOrchestrator: ChatOrchestratorProtocol

    // MARK: - Subscription
    let subscriptionService = SubscriptionService.shared

    // MARK: - Global State
    let userState: UserStateManager

    // MARK: - Launch Cache (precomputed at app startup for instant home rendering)
    var cachedTodayPrayers: [PrayerTime]?

    /// Persisted Maghrib time for today, validated to be same-day.
    /// Used for Maghrib-aware Islamic day boundary calculations.
    var todayMaghribTime: Date? {
        guard let time = UserDefaults.standard.object(forKey: AppConstants.StorageKeys.todayMaghribTime) as? Date,
              Calendar.current.isDate(time, inSameDayAs: Date()) else {
            return nil
        }
        return time
    }

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
        self.ramadanService = RamadanService()

        // Initialize RAG service (depends on repositories)
        self.ragService = RAGService(
            quranRepository: quranRepository,
            hadithRepository: hadithRepository,
            duaRepository: duaRepository
        )

        // Initialize AI pipeline services
        self.inputSafety = InputSafetyService()
        self.outputSafety = OutputSafetyService()
        self.citationValidation = CitationValidationService()
        self.chatOrchestrator = ChatOrchestrator(
            llmService: llmService,
            ragService: ragService,
            inputSafety: inputSafety,
            outputSafety: outputSafety,
            citationValidation: citationValidation
        )

        // Initialize chat repository (persist-only; generation moved to ChatOrchestrator)
        self.chatRepository = ChatRepository(coreData: coreDataStack)

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
