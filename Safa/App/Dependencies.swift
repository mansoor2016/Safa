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
    let familyRepository: FamilyRepositoryProtocol

    // MARK: - Services
    let locationService: LocationService
    let notificationService: NotificationService
    let audioPlayerService: AudioPlayerService
    let llmService: LLMService
    let pronunciationService: PronunciationService

    // MARK: - Global State
    let userState: UserStateManager

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
        self.familyRepository = FamilyRepository(coreData: coreDataStack)

        // Initialize services
        self.locationService = LocationService()
        self.notificationService = NotificationService()
        self.audioPlayerService = AudioPlayerService()
        self.llmService = LLMService()
        self.pronunciationService = PronunciationService()

        // Initialize chat repository (depends on LLM service)
        self.chatRepository = ChatRepository(llmService: llmService)

        // Initialize global state (depends on user repository)
        self.userState = UserStateManager(userRepository: userRepository)
    }
}
