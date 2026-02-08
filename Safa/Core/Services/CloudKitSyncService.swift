// MARK: - CloudKitSyncService.swift
// PURPOSE: CloudKit synchronization with conflict resolution and offline support
// DEPENDENCIES: CloudKit, CoreData, Combine

import Foundation
import CloudKit
import CoreData
import Combine

// MARK: - Sync Status

enum SyncStatus: Equatable {
    case idle
    case syncing
    case synced
    case error(String)
    case offline
}

// MARK: - Sync Error

enum SyncError: LocalizedError {
    case notAuthenticated
    case networkUnavailable
    case quotaExceeded
    case serverError(String)
    case conflictDetected
    case recordNotFound
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return String(localized: "Please sign in to iCloud to sync your data.")
        case .networkUnavailable:
            return String(localized: "No internet connection. Changes will sync when online.")
        case .quotaExceeded:
            return String(localized: "iCloud storage is full. Please free up space.")
        case .serverError(let message):
            return String(localized: "Server error: \(message)")
        case .conflictDetected:
            return String(localized: "A sync conflict was detected and resolved.")
        case .recordNotFound:
            return String(localized: "The requested record was not found.")
        case .permissionDenied:
            return String(localized: "Permission denied to access this data.")
        }
    }
}

// MARK: - Conflict Resolution Strategy

enum ConflictResolutionStrategy {
    case serverWins
    case clientWins
    case merge
    case askUser
}

// MARK: - Syncable Protocol

protocol Syncable {
    var id: UUID { get }
    var modifiedAt: Date { get set }
    var cloudKitRecordID: CKRecord.ID? { get set }
    var needsSync: Bool { get set }

    func toCKRecord() -> CKRecord
    static func fromCKRecord(_ record: CKRecord) -> Self?
}

// MARK: - CloudKit Sync Service

@Observable
final class CloudKitSyncService {
    // MARK: - Properties

    private(set) var status: SyncStatus = .idle
    private(set) var lastSyncDate: Date?
    private(set) var pendingChangesCount: Int = 0

    private let container: CKContainer
    private let database: CKDatabase
    private let coreDataStack: CoreDataStack
    private let zoneID: CKRecordZone.ID

    private var networkMonitor: NetworkMonitor?
    private var subscriptions: Set<AnyCancellable> = []

    // Configuration
    private let syncBatchSize = 100
    private let defaultZoneName = "SafaZone"

    // MARK: - Initialization

    init(
        containerIdentifier: String = "iCloud.com.safa.app",
        coreDataStack: CoreDataStack = .shared
    ) {
        self.container = CKContainer(identifier: containerIdentifier)
        self.database = container.privateCloudDatabase
        self.coreDataStack = coreDataStack
        self.zoneID = CKRecordZone.ID(zoneName: defaultZoneName, ownerName: CKCurrentUserDefaultName)

        setupNetworkMonitoring()
        setupChangeNotifications()
    }

    // MARK: - Public Methods

    /// Check iCloud account status
    func checkAccountStatus() async throws -> CKAccountStatus {
        try await container.accountStatus()
    }

    /// Initialize the custom zone for sync
    func initializeZone() async throws {
        let zone = CKRecordZone(zoneID: zoneID)
        let operation = CKModifyRecordZonesOperation(
            recordZonesToSave: [zone],
            recordZoneIDsToDelete: nil
        )

        operation.qualityOfService = .userInitiated

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            operation.modifyRecordZonesResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            database.add(operation)
        }
    }

    /// Perform full sync
    func performSync() async {
        guard status != .syncing else { return }

        await MainActor.run { status = .syncing }

        do {
            // Check account status
            let accountStatus = try await checkAccountStatus()
            guard accountStatus == .available else {
                throw SyncError.notAuthenticated
            }

            // Fetch remote changes
            try await fetchRemoteChanges()

            // Push local changes
            try await pushLocalChanges()

            await MainActor.run {
                status = .synced
                lastSyncDate = Date()
                pendingChangesCount = 0
            }
        } catch {
            await MainActor.run {
                if isNetworkError(error) {
                    status = .offline
                } else if isQuotaExceeded(error) {
                    status = .error("iCloud storage full. Sync paused.")
                } else {
                    status = .error(error.localizedDescription)
                }
            }
        }
    }

    /// Fetch changes from CloudKit
    func fetchRemoteChanges() async throws {
        let serverChangeToken = getServerChangeToken()

        let configuration = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
        configuration.previousServerChangeToken = serverChangeToken

        let operation = CKFetchRecordZoneChangesOperation(
            recordZoneIDs: [zoneID],
            configurationsByRecordZoneID: [zoneID: configuration]
        )

        var changedRecords: [CKRecord] = []
        var deletedRecordIDs: [CKRecord.ID] = []

        operation.recordWasChangedBlock = { _, result in
            if case .success(let record) = result {
                changedRecords.append(record)
            }
        }

        operation.recordWithIDWasDeletedBlock = { recordID, _ in
            deletedRecordIDs.append(recordID)
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            operation.fetchRecordZoneChangesResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            database.add(operation)
        }

        // Apply changes to local store
        try await applyRemoteChanges(changedRecords, deletedIDs: deletedRecordIDs)
    }

    /// Push local changes to CloudKit
    func pushLocalChanges() async throws {
        let context = coreDataStack.newBackgroundContext()

        // Get all records needing sync
        let recordsToSave = try await getRecordsNeedingSync(context: context)

        guard !recordsToSave.isEmpty else { return }

        let operation = CKModifyRecordsOperation(
            recordsToSave: recordsToSave,
            recordIDsToDelete: nil
        )

        operation.savePolicy = .changedKeys
        operation.qualityOfService = .userInitiated

        // Handle conflicts
        operation.perRecordSaveBlock = { [weak self] recordID, result in
            if case .failure(let error) = result,
               let ckError = error as? CKError,
               ckError.code == .serverRecordChanged {
                // Handle conflict
                Task {
                    try await self?.resolveConflict(
                        localRecord: recordsToSave.first { $0.recordID == recordID },
                        serverRecord: ckError.serverRecord,
                        strategy: .merge
                    )
                }
            }
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            database.add(operation)
        }
    }

    // MARK: - Conflict Resolution

    /// Resolve a sync conflict between local and server records
    func resolveConflict(
        localRecord: CKRecord?,
        serverRecord: CKRecord?,
        strategy: ConflictResolutionStrategy
    ) async throws {
        guard let local = localRecord, let server = serverRecord else { return }

        let resolvedRecord: CKRecord

        switch strategy {
        case .serverWins:
            resolvedRecord = server
            // Update local store with server data
            try await applyRemoteChanges([server], deletedIDs: [])

        case .clientWins:
            // Force push client changes
            resolvedRecord = local
            // recordChangeTag is read-only, server version will be used during save
            try await forcePushRecord(resolvedRecord)

        case .merge:
            // Merge based on modification timestamps
            resolvedRecord = mergeRecords(local: local, server: server)
            try await forcePushRecord(resolvedRecord)

        case .askUser:
            // Store conflict for user resolution
            // In a real app, this would present UI
            resolvedRecord = server
            try await applyRemoteChanges([server], deletedIDs: [])
        }
    }

    /// Merge two records preferring newer values for each field
    private func mergeRecords(local: CKRecord, server: CKRecord) -> CKRecord {
        let merged = server.copy() as! CKRecord

        // Get modification dates
        let localModDate = local["modifiedAt"] as? Date ?? .distantPast
        let serverModDate = server["modifiedAt"] as? Date ?? .distantPast

        // System field keys to skip when merging
        let systemKeys: Set<String> = [
            "recordID", "recordChangeTag", "creatorUserRecordID",
            "creationDate", "lastModifiedUserRecordID", "modificationDate",
            "share", "parent"
        ]

        // For each field, use the newer value
        for key in local.allKeys() {
            if !systemKeys.contains(key) {
                // Compare field modification times if available
                // Otherwise use record-level modification date
                if localModDate > serverModDate {
                    merged[key] = local[key]
                }
            }
        }

        return merged
    }

    // MARK: - Offline Support

    /// Queue a change for later sync when offline
    func queueOfflineChange(_ record: CKRecord) {
        let context = coreDataStack.newBackgroundContext()

        context.perform {
            // Store the pending change
            // Using UserDefaults for simplicity, but could use Core Data
            var pendingChanges = UserDefaults.standard.array(forKey: "pendingCloudKitChanges") as? [[String: Any]] ?? []

            let changeData: [String: Any] = [
                "recordType": record.recordType,
                "recordID": record.recordID.recordName,
                "timestamp": Date()
            ]

            pendingChanges.append(changeData)
            UserDefaults.standard.set(pendingChanges, forKey: "pendingCloudKitChanges")

            DispatchQueue.main.async {
                self.pendingChangesCount = pendingChanges.count
            }
        }
    }

    /// Process queued offline changes
    func processOfflineQueue() async throws {
        let pendingChanges = UserDefaults.standard.array(forKey: "pendingCloudKitChanges") as? [[String: Any]] ?? []

        guard !pendingChanges.isEmpty else { return }

        // Process and push changes
        try await pushLocalChanges()

        // Clear queue on success
        UserDefaults.standard.removeObject(forKey: "pendingCloudKitChanges")
        await MainActor.run {
            pendingChangesCount = 0
        }
    }

    // MARK: - Subscriptions

    /// Set up push notification for changes
    func subscribeToChanges() async throws {
        let subscription = CKRecordZoneSubscription(zoneID: zoneID)

        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true

        subscription.notificationInfo = notificationInfo

        try await database.save(subscription)
    }

    // MARK: - Private Helpers

    private func setupNetworkMonitoring() {
        networkMonitor = NetworkMonitor()
        // NetworkMonitor uses @Observable, so we poll or use withObservationTracking
        // For simplicity, we'll check connectivity before sync operations
    }

    private func setupChangeNotifications() {
        NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task {
                    await self?.performSync()
                }
            }
            .store(in: &subscriptions)
    }

    private func getServerChangeToken() -> CKServerChangeToken? {
        guard let data = UserDefaults.standard.data(forKey: "cloudKitServerChangeToken") else {
            return nil
        }
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: data)
    }

    private func saveServerChangeToken(_ token: CKServerChangeToken) {
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true) {
            UserDefaults.standard.set(data, forKey: "cloudKitServerChangeToken")
        }
    }

    private func getRecordsNeedingSync(context: NSManagedObjectContext) async throws -> [CKRecord] {
        // This would query Core Data for entities with needsSync = true
        // Simplified implementation
        return []
    }

    private func applyRemoteChanges(_ records: [CKRecord], deletedIDs: [CKRecord.ID]) async throws {
        let context = coreDataStack.newBackgroundContext()

        try await context.perform {
            // Apply changed records
            for record in records {
                // Find or create local entity based on record type
                // Update local entity with server values
            }

            // Handle deletions
            for recordID in deletedIDs {
                // Delete local entity matching recordID
            }

            try context.saveIfNeeded()
        }
    }

    private func forcePushRecord(_ record: CKRecord) async throws {
        let operation = CKModifyRecordsOperation(
            recordsToSave: [record],
            recordIDsToDelete: nil
        )
        operation.savePolicy = .allKeys

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            database.add(operation)
        }
    }

    private func isNetworkError(_ error: Error) -> Bool {
        if let ckError = error as? CKError {
            return ckError.code == .networkUnavailable ||
                   ckError.code == .networkFailure
        }
        return false
    }

    private func isQuotaExceeded(_ error: Error) -> Bool {
        if let ckError = error as? CKError {
            return ckError.code == .quotaExceeded
        }
        return false
    }
}

// MARK: - Network Monitor

import Network

@Observable
final class NetworkMonitor {
    static let shared = NetworkMonitor()

    private(set) var isConnected = true
    private(set) var connectionType: NWInterface.InterfaceType?

    var isOnWiFi: Bool {
        isConnected && connectionType == .wifi
    }

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = path.availableInterfaces.first?.type
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}

// MARK: - CKRecord System Field Keys
// Note: CKRecord system fields are accessed via properties, not subscripts
