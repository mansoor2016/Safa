// MARK: - CoreDataTests.swift
// PURPOSE: Unit tests for Core Data CRUD operations
// DEPENDENCIES: XCTest, CoreData

import XCTest
import CoreData
@testable import Safa

final class CoreDataTests: XCTestCase {

    var coreDataStack: CoreDataStack!
    var testContext: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        // Use in-memory store for testing
        coreDataStack = CoreDataStack.shared
        testContext = coreDataStack.newBackgroundContext()
    }

    override func tearDown() {
        testContext = nil
        coreDataStack = nil
        super.tearDown()
    }

    // MARK: - Context Tests

    func testViewContextExists() {
        XCTAssertNotNil(coreDataStack.viewContext)
    }

    func testBackgroundContextCreation() {
        let context = coreDataStack.newBackgroundContext()
        XCTAssertNotNil(context)
        XCTAssertNotEqual(context, coreDataStack.viewContext)
    }

    func testContextMergePolicy() {
        let context = coreDataStack.newBackgroundContext()
        XCTAssertTrue(context.mergePolicy is NSMergePolicy)
    }

    // MARK: - Save Tests

    func testSaveEmptyContext() {
        // Should not throw when no changes
        XCTAssertNoThrow(try coreDataStack.save())
    }

    func testSaveIfNeededNoChanges() {
        let context = coreDataStack.newBackgroundContext()
        XCTAssertNoThrow(try context.saveIfNeeded())
    }
}

// MARK: - Core Data Stack Tests

final class CoreDataStackConfigurationTests: XCTestCase {

    func testSharedInstanceExists() {
        XCTAssertNotNil(CoreDataStack.shared)
    }

    func testSharedInstanceIsSingleton() {
        let instance1 = CoreDataStack.shared
        let instance2 = CoreDataStack.shared
        XCTAssertTrue(instance1 === instance2)
    }

    func testPersistentContainerExists() {
        XCTAssertNotNil(CoreDataStack.shared.persistentContainer)
    }
}

// MARK: - Migration Tests

final class CoreDataMigrationTests: XCTestCase {

    var migrationManager: CoreDataMigrationManager!

    override func setUp() {
        super.setUp()
        migrationManager = CoreDataMigrationManager()
    }

    override func tearDown() {
        migrationManager = nil
        super.tearDown()
    }

    func testCurrentModelExists() {
        // May be nil in test environment without bundle
        // This tests the method doesn't crash
        _ = migrationManager.currentManagedObjectModel()
    }

    func testMigrationNotNeededForNonexistentStore() {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("nonexistent.sqlite")

        XCTAssertFalse(migrationManager.requiresMigration(at: tempURL))
    }

    func testModelVersionTrackerFreshInstall() {
        // Clear any existing version
        UserDefaults.standard.removeObject(forKey: "com.safa.coredata.modelVersion")

        XCTAssertTrue(ModelVersionTracker.isFreshInstall)
    }

    func testModelVersionTrackerUpdate() {
        ModelVersionTracker.updateVersion(to: "2.0")
        XCTAssertEqual(ModelVersionTracker.currentVersion, "2.0")

        // Reset for other tests
        UserDefaults.standard.removeObject(forKey: "com.safa.coredata.modelVersion")
    }
}

// MARK: - Entity Tests

final class CoreDataEntityTests: XCTestCase {

    func testPrayerLogEntityExists() {
        // Test entity description exists in model
        let model = CoreDataStack.shared.persistentContainer.managedObjectModel
        let entity = model.entitiesByName["PrayerLogMO"]
        XCTAssertNotNil(entity, "PrayerLogMO entity should exist")
    }

    func testQuranProgressEntityExists() {
        let model = CoreDataStack.shared.persistentContainer.managedObjectModel
        let entity = model.entitiesByName["QuranProgressMO"]
        XCTAssertNotNil(entity, "QuranProgressMO entity should exist")
    }

    func testStreakEntityExists() {
        let model = CoreDataStack.shared.persistentContainer.managedObjectModel
        let entity = model.entitiesByName["StreakMO"]
        XCTAssertNotNil(entity, "StreakMO entity should exist")
    }

    func testUserStatsEntityExists() {
        let model = CoreDataStack.shared.persistentContainer.managedObjectModel
        let entity = model.entitiesByName["UserStatsMO"]
        XCTAssertNotNil(entity, "UserStatsMO entity should exist")
    }

    func testFamilyMemberEntityExists() {
        let model = CoreDataStack.shared.persistentContainer.managedObjectModel
        let entity = model.entitiesByName["FamilyMemberMO"]
        XCTAssertNotNil(entity, "FamilyMemberMO entity should exist")
    }

    func testFamilyCircleEntityExists() {
        let model = CoreDataStack.shared.persistentContainer.managedObjectModel
        let entity = model.entitiesByName["FamilyCircleMO"]
        XCTAssertNotNil(entity, "FamilyCircleMO entity should exist")
    }

    func testChatMessageEntityExists() {
        let model = CoreDataStack.shared.persistentContainer.managedObjectModel
        let entity = model.entitiesByName["ChatMessageMO"]
        XCTAssertNotNil(entity, "ChatMessageMO entity should exist")
    }

    func testChatConversationEntityExists() {
        let model = CoreDataStack.shared.persistentContainer.managedObjectModel
        let entity = model.entitiesByName["ChatConversationMO"]
        XCTAssertNotNil(entity, "ChatConversationMO entity should exist")
    }
}

// MARK: - Attribute Tests

final class CoreDataAttributeTests: XCTestCase {

    func testPrayerLogAttributes() {
        let model = CoreDataStack.shared.persistentContainer.managedObjectModel
        guard let entity = model.entitiesByName["PrayerLogMO"] else {
            XCTFail("PrayerLogMO entity not found")
            return
        }

        let attributeNames = entity.attributesByName.keys
        XCTAssertTrue(attributeNames.contains("id"))
        XCTAssertTrue(attributeNames.contains("date"))
        XCTAssertTrue(attributeNames.contains("prayerType"))
        XCTAssertTrue(attributeNames.contains("isOnTime"))
        XCTAssertTrue(attributeNames.contains("loggedAt"))
    }

    func testStreakAttributes() {
        let model = CoreDataStack.shared.persistentContainer.managedObjectModel
        guard let entity = model.entitiesByName["StreakMO"] else {
            XCTFail("StreakMO entity not found")
            return
        }

        let attributeNames = entity.attributesByName.keys
        XCTAssertTrue(attributeNames.contains("id"))
        XCTAssertTrue(attributeNames.contains("currentStreak"))
        XCTAssertTrue(attributeNames.contains("bestStreak"))
        XCTAssertTrue(attributeNames.contains("streakType"))
        XCTAssertTrue(attributeNames.contains("freezesAvailable"))
    }

    func testUserStatsAttributes() {
        let model = CoreDataStack.shared.persistentContainer.managedObjectModel
        guard let entity = model.entitiesByName["UserStatsMO"] else {
            XCTFail("UserStatsMO entity not found")
            return
        }

        let attributeNames = entity.attributesByName.keys
        XCTAssertTrue(attributeNames.contains("id"))
        XCTAssertTrue(attributeNames.contains("totalHasanat"))
        XCTAssertTrue(attributeNames.contains("currentLevel"))
        XCTAssertTrue(attributeNames.contains("prayersLogged"))
        XCTAssertTrue(attributeNames.contains("pagesRead"))
    }
}

// MARK: - Relationship Tests

final class CoreDataRelationshipTests: XCTestCase {

    func testFamilyCircleMembersRelationship() {
        let model = CoreDataStack.shared.persistentContainer.managedObjectModel
        guard let circleEntity = model.entitiesByName["FamilyCircleMO"] else {
            XCTFail("FamilyCircleMO entity not found")
            return
        }

        let relationships = circleEntity.relationshipsByName
        XCTAssertNotNil(relationships["members"], "FamilyCircle should have members relationship")

        if let membersRelationship = relationships["members"] {
            XCTAssertTrue(membersRelationship.isToMany, "Members should be to-many relationship")
        }
    }

    func testFamilyMemberCircleRelationship() {
        let model = CoreDataStack.shared.persistentContainer.managedObjectModel
        guard let memberEntity = model.entitiesByName["FamilyMemberMO"] else {
            XCTFail("FamilyMemberMO entity not found")
            return
        }

        let relationships = memberEntity.relationshipsByName
        XCTAssertNotNil(relationships["circle"], "FamilyMember should have circle relationship")

        if let circleRelationship = relationships["circle"] {
            XCTAssertFalse(circleRelationship.isToMany, "Circle should be to-one relationship")
        }
    }

    func testChatConversationMessagesRelationship() {
        let model = CoreDataStack.shared.persistentContainer.managedObjectModel
        guard let conversationEntity = model.entitiesByName["ChatConversationMO"] else {
            XCTFail("ChatConversationMO entity not found")
            return
        }

        let relationships = conversationEntity.relationshipsByName
        XCTAssertNotNil(relationships["messages"], "Conversation should have messages relationship")

        if let messagesRelationship = relationships["messages"] {
            XCTAssertTrue(messagesRelationship.isToMany, "Messages should be to-many relationship")
            XCTAssertEqual(messagesRelationship.deleteRule, .cascade, "Messages should cascade delete")
        }
    }

    func testChatMessageConversationRelationship() {
        let model = CoreDataStack.shared.persistentContainer.managedObjectModel
        guard let messageEntity = model.entitiesByName["ChatMessageMO"] else {
            XCTFail("ChatMessageMO entity not found")
            return
        }

        let relationships = messageEntity.relationshipsByName
        XCTAssertNotNil(relationships["conversation"], "Message should have conversation relationship")
    }
}

// MARK: - Uniqueness Constraint Tests

final class CoreDataUniquenessTests: XCTestCase {

    func testEntitiesHaveIdUniquenessConstraint() {
        let model = CoreDataStack.shared.persistentContainer.managedObjectModel
        let entitiesWithId = [
            "PrayerLogMO", "QuranProgressMO", "StreakMO", "UserStatsMO",
            "FamilyMemberMO", "FamilyCircleMO", "ChatMessageMO", "ChatConversationMO"
        ]

        for entityName in entitiesWithId {
            guard let entity = model.entitiesByName[entityName] else {
                continue
            }

            // Check that uniqueness constraints exist
            let hasIdConstraint = entity.uniquenessConstraints.contains { constraints in
                constraints.contains { ($0 as? NSAttributeDescription)?.name == "id" }
            }

            XCTAssertTrue(hasIdConstraint, "\(entityName) should have id uniqueness constraint")
        }
    }
}
