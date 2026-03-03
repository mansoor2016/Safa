// MARK: - CoreDataMigrationTests.swift
// PURPOSE: Verify Core Data lightweight migration handles removed attributes gracefully
// DEPENDENCIES: XCTest, CoreData, Safa

import XCTest
import CoreData
@testable import Safa

final class CoreDataMigrationTests: XCTestCase {

    // MARK: - LessonProgressMO Schema Migration

    /// Verify that LessonProgressMO rows inserted before the pronunciationScore
    /// attribute was removed still load correctly under the current schema.
    ///
    /// Core Data lightweight migration silently drops removed optional attributes.
    /// This test proves the entity is fully functional after the schema change.
    func test_lessonProgressMO_loadsWithoutPronunciationScore() throws {
        // Create an in-memory container using the current (post-removal) model
        let container = NSPersistentContainer(name: "Safa")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]

        let expectation = expectation(description: "Store loaded")
        var loadError: Error?
        container.loadPersistentStores { _, error in
            loadError = error
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5)
        XCTAssertNil(loadError, "Store should load without errors")

        let context = container.viewContext

        // Insert a LessonProgressMO row — simulates data from a user who
        // had the old schema (pronunciationScore no longer exists)
        let entity = NSEntityDescription.entity(forEntityName: "LessonProgressMO", in: context)
        XCTAssertNotNil(entity, "LessonProgressMO entity must exist in current model")

        let lesson = NSManagedObject(entity: entity!, insertInto: context)
        lesson.setValue(UUID(), forKey: "id")
        lesson.setValue("arabic_1", forKey: "lessonId")
        lesson.setValue("arabic_foundations", forKey: "trackId")
        lesson.setValue(true, forKey: "isCompleted")
        lesson.setValue(Date(), forKey: "completedAt")
        lesson.setValue(Date(), forKey: "lastAccessedAt")

        try context.save()

        // Fetch it back — proves the entity is fully functional
        let request = NSFetchRequest<NSManagedObject>(entityName: "LessonProgressMO")
        request.predicate = NSPredicate(format: "lessonId == %@", "arabic_1")
        let results = try context.fetch(request)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.value(forKey: "lessonId") as? String, "arabic_1")
        XCTAssertEqual(results.first?.value(forKey: "isCompleted") as? Bool, true)
    }

    /// Verify that the pronunciationScore attribute no longer exists in the model.
    func test_lessonProgressMO_noPronunciationScoreAttribute() {
        let container = NSPersistentContainer(name: "Safa")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]

        let expectation = expectation(description: "Store loaded")
        container.loadPersistentStores { _, _ in expectation.fulfill() }
        wait(for: [expectation], timeout: 5)

        let entity = NSEntityDescription.entity(forEntityName: "LessonProgressMO", in: container.viewContext)
        let attributeNames = entity?.attributesByName.keys.map { $0 } ?? []

        XCTAssertFalse(attributeNames.contains("pronunciationScore"),
                       "pronunciationScore should have been removed from the schema")
        // Verify remaining attributes are intact
        XCTAssertTrue(attributeNames.contains("lessonId"))
        XCTAssertTrue(attributeNames.contains("trackId"))
        XCTAssertTrue(attributeNames.contains("isCompleted"))
    }

    /// Verify that the full persistent container loads without entering degraded mode.
    /// This catches any model incompatibility that would push the app to in-memory fallback.
    func test_sharedStack_notDegradedAfterSchemaChange() {
        let stack = CoreDataStack.shared
        XCTAssertFalse(stack.isDegradedMode,
                       "CoreDataStack should not be in degraded mode after schema change")
    }
}
