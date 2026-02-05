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

    // MARK: - Container
    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: Self.modelName)

        // Configure store URL for App Group (shared with widgets)
        guard let appGroupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Self.appGroupIdentifier
        ) else {
            fatalError("App Group container not found")
        }

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

        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                // In production, handle this gracefully
                fatalError("Core Data store failed to load: \(error), \(error.userInfo)")
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
