// MARK: - CoreDataMigration.swift
// PURPOSE: Core Data migration strategy for schema versioning
// DEPENDENCIES: CoreData

import CoreData
import OSLog

// MARK: - Migration Manager

final class CoreDataMigrationManager {

    // MARK: - Properties

    private let modelName: String
    private let bundle: Bundle

    // MARK: - Initialization

    init(modelName: String = "Safa", bundle: Bundle = .main) {
        self.modelName = modelName
        self.bundle = bundle
    }

    // MARK: - Migration Check

    /// Check if migration is needed for the store at the given URL
    func requiresMigration(at storeURL: URL) -> Bool {
        guard FileManager.default.fileExists(atPath: storeURL.path) else {
            return false
        }

        do {
            let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
                ofType: NSSQLiteStoreType,
                at: storeURL,
                options: nil
            )

            guard let currentModel = currentManagedObjectModel() else {
                return false
            }

            return !currentModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
        } catch {
            // If we can't read metadata, assume we need migration
            return true
        }
    }

    /// Get the current managed object model
    func currentManagedObjectModel() -> NSManagedObjectModel? {
        guard let modelURL = bundle.url(forResource: modelName, withExtension: "momd") else {
            return nil
        }
        return NSManagedObjectModel(contentsOf: modelURL)
    }

    // MARK: - Migration

    /// Perform lightweight migration if possible, otherwise attempt staged migration
    func migrateStore(at storeURL: URL) throws {
        guard requiresMigration(at: storeURL) else {
            return
        }

        // Try lightweight migration first
        if canPerformLightweightMigration(at: storeURL) {
            try performLightweightMigration(at: storeURL)
        } else {
            // Fall back to staged migration
            try performStagedMigration(at: storeURL)
        }
    }

    // MARK: - Lightweight Migration

    private func canPerformLightweightMigration(at storeURL: URL) -> Bool {
        guard let currentModel = currentManagedObjectModel() else {
            return false
        }

        do {
            let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
                ofType: NSSQLiteStoreType,
                at: storeURL,
                options: nil
            )

            let sourceModel = NSManagedObjectModel.mergedModel(
                from: [bundle],
                forStoreMetadata: metadata
            )

            guard let source = sourceModel else {
                return false
            }

            // Check if we can infer mapping model
            let mappingModel = try? NSMappingModel.inferredMappingModel(
                forSourceModel: source,
                destinationModel: currentModel
            )

            return mappingModel != nil
        } catch {
            return false
        }
    }

    private func performLightweightMigration(at storeURL: URL) throws {
        guard let currentModel = currentManagedObjectModel() else {
            throw MigrationError.missingModel
        }

        let options: [String: Any] = [
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true
        ]

        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: currentModel)

        try coordinator.addPersistentStore(
            ofType: NSSQLiteStoreType,
            configurationName: nil,
            at: storeURL,
            options: options
        )
    }

    // MARK: - Staged Migration

    private func performStagedMigration(at storeURL: URL) throws {
        let allModelVersions = getAllModelVersions()

        guard allModelVersions.count > 1 else {
            // Only one version, lightweight should work
            try performLightweightMigration(at: storeURL)
            return
        }

        var currentURL = storeURL

        for i in 0..<(allModelVersions.count - 1) {
            let sourceModel = allModelVersions[i]
            let destinationModel = allModelVersions[i + 1]

            // Skip if store is already compatible with destination
            let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
                ofType: NSSQLiteStoreType,
                at: currentURL,
                options: nil
            )

            if destinationModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata) {
                continue
            }

            // Perform migration step
            let tempURL = storeURL
                .deletingLastPathComponent()
                .appendingPathComponent("migration_temp_\(i).sqlite")

            try migrateStep(
                from: currentURL,
                to: tempURL,
                sourceModel: sourceModel,
                destinationModel: destinationModel
            )

            // Swap files
            if currentURL != storeURL {
                try FileManager.default.removeItem(at: currentURL)
            }
            currentURL = tempURL
        }

        // Move final result to original location
        if currentURL != storeURL {
            let backupURL = storeURL
                .deletingLastPathComponent()
                .appendingPathComponent("\(modelName)_backup.sqlite")

            try FileManager.default.moveItem(at: storeURL, to: backupURL)
            try FileManager.default.moveItem(at: currentURL, to: storeURL)
            try? FileManager.default.removeItem(at: backupURL)
        }
    }

    private func migrateStep(
        from sourceURL: URL,
        to destinationURL: URL,
        sourceModel: NSManagedObjectModel,
        destinationModel: NSManagedObjectModel
    ) throws {
        // Try to infer mapping model
        let mappingModel: NSMappingModel

        if let inferred = try? NSMappingModel.inferredMappingModel(
            forSourceModel: sourceModel,
            destinationModel: destinationModel
        ) {
            mappingModel = inferred
        } else if let custom = customMappingModel(from: sourceModel, to: destinationModel) {
            mappingModel = custom
        } else {
            throw MigrationError.mappingModelNotFound
        }

        let migrationManager = NSMigrationManager(
            sourceModel: sourceModel,
            destinationModel: destinationModel
        )

        try migrationManager.migrateStore(
            from: sourceURL,
            type: .sqlite,
            mapping: mappingModel,
            to: destinationURL,
            type: .sqlite
        )
    }

    // MARK: - Model Versions

    private func getAllModelVersions() -> [NSManagedObjectModel] {
        guard let modelURL = bundle.url(forResource: modelName, withExtension: "momd") else {
            return []
        }

        guard let momdURL = Bundle(url: modelURL) else {
            return []
        }

        let modelPaths = momdURL.paths(forResourcesOfType: "mom", inDirectory: nil)

        return modelPaths
            .compactMap { URL(fileURLWithPath: $0) }
            .compactMap { NSManagedObjectModel(contentsOf: $0) }
            .sorted { model1, model2 in
                // Sort by version identifier if available
                let v1 = model1.versionIdentifiers.first as? String ?? ""
                let v2 = model2.versionIdentifiers.first as? String ?? ""
                return v1 < v2
            }
    }

    private func customMappingModel(
        from sourceModel: NSManagedObjectModel,
        to destinationModel: NSManagedObjectModel
    ) -> NSMappingModel? {
        // Look for custom mapping models in the bundle
        return NSMappingModel(
            from: [bundle],
            forSourceModel: sourceModel,
            destinationModel: destinationModel
        )
    }
}

// MARK: - Migration Error

enum MigrationError: LocalizedError {
    case missingModel
    case mappingModelNotFound
    case migrationFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingModel:
            return String(localized: "The data model could not be found.")
        case .mappingModelNotFound:
            return String(localized: "No mapping model found for migration.")
        case .migrationFailed(let reason):
            return String(localized: "Migration failed: \(reason)")
        }
    }
}

// MARK: - CoreDataStack Migration Extension

extension CoreDataStack {

    /// Migrate store if needed before loading
    func migrateIfNeeded() {
        guard let appGroupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.safa.app"
        ) else {
            return
        }

        let storeURL = appGroupURL.appendingPathComponent("Safa.sqlite")
        let migrationManager = CoreDataMigrationManager()

        do {
            try migrationManager.migrateStore(at: storeURL)
        } catch {
            // Log error but continue - Core Data may still recover
            Log.coreData.error("Migration error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Version Tracking

/// Tracks which model version the app is using
struct ModelVersionTracker {
    private static let currentVersionKey = AppConstants.StorageKeys.coreDataModelVersion

    /// Current model version
    static var currentVersion: String {
        get {
            UserDefaults.standard.string(forKey: currentVersionKey) ?? "1.0"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: currentVersionKey)
        }
    }

    /// Update version after successful migration
    static func updateVersion(to version: String) {
        currentVersion = version
    }

    /// Check if this is a fresh install (no previous version)
    static var isFreshInstall: Bool {
        UserDefaults.standard.string(forKey: currentVersionKey) == nil
    }
}
