// MARK: - CoreDataStack.swift
// PURPOSE: Core Data stack configuration with CloudKit sync and App Group support
// DEPENDENCIES: CoreData, CloudKit

import CoreData
import CloudKit

final class CoreDataStack {
    // MARK: - Shared Instance
    static let shared = CoreDataStack()

    // MARK: - App Group
    private static let appGroupIdentifier = "group.com.safa.app"
    private static let modelName = "Safa"

    // MARK: - Degraded Mode
    /// True when persistent store failed to load and app is using in-memory fallback
    private(set) var isDegradedMode = false

    // MARK: - Container
    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: Self.modelName)

        // Configure store URL for App Group (shared with widgets)
        if let appGroupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Self.appGroupIdentifier
        ) {
            let storeURL = appGroupURL.appendingPathComponent("\(Self.modelName).sqlite")
            let storeDescription = NSPersistentStoreDescription(url: storeURL)

            // Enable CloudKit sync
            storeDescription.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.com.safa.app"
            )

            // Enable persistent history tracking for CloudKit
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

            container.persistentStoreDescriptions = [storeDescription]
        } else {
            // App Group unavailable — fall back to in-memory store
            let inMemoryDescription = NSPersistentStoreDescription()
            inMemoryDescription.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [inMemoryDescription]
            self.isDegradedMode = true
        }

        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                // Fall back to in-memory store instead of crashing
                let fallbackDescription = NSPersistentStoreDescription()
                fallbackDescription.type = NSInMemoryStoreType
                container.persistentStoreDescriptions = [fallbackDescription]
                container.loadPersistentStores { _, fallbackError in
                    if fallbackError != nil {
                        // Even in-memory failed — nothing more we can do
                    }
                }
                self.isDegradedMode = true
            }
        }

        // Merge policy - remote changes win
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        return container
    }()

    // MARK: - Contexts

    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    // MARK: - Save

    func save() throws {
        let context = viewContext
        guard context.hasChanges else { return }
        try context.save()
    }

    func saveBackground(_ context: NSManagedObjectContext) throws {
        guard context.hasChanges else { return }
        try context.save()
    }

    // MARK: - Private Init
    private init() {}
}

// MARK: - Convenience Extensions

extension NSManagedObjectContext {
    func saveIfNeeded() throws {
        guard hasChanges else { return }
        try save()
    }
}
