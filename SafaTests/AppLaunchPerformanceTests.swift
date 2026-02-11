// MARK: - AppLaunchPerformanceTests.swift
// PURPOSE: Verify app launch and home screen rendering meet performance budgets
// DEPENDENCIES: XCTest, XCUITest, Safa

import XCTest
@testable import Safa

final class AppLaunchPerformanceTests: XCTestCase {

    // MARK: - Home Data Load Performance

    /// Simulates the home screen's critical data-loading path:
    /// prayer time calculation + prayer log fetch + Hijri conversion.
    /// Budget: under 200ms total (the path users wait on before seeing content).
    func test_homeDataLoad_under200ms() async throws {
        let prayerRepo = PrayerRepository(coreData: CoreDataStack.shared)
        let london = Coordinates(latitude: 51.5074, longitude: -0.1278)

        let start = CFAbsoluteTimeGetCurrent()

        // 1. Calculate prayer times (most expensive)
        let prayers = try await prayerRepo.getPrayers(
            for: Date(),
            location: london,
            method: .muslimWorldLeague,
            madhab: .hanafi
        )

        // 2. Get logged prayers
        _ = try await prayerRepo.getPrayerLogs(for: Date())

        // 3. Hijri date conversion
        _ = HijriDateConverter.shared.hijriDateString(from: Date(), style: .full)

        // 4. Ramadan check
        _ = HijriDateConverter.shared.isRamadan()

        let elapsed = CFAbsoluteTimeGetCurrent() - start

        XCTAssertFalse(prayers.isEmpty, "Should return prayer times")
        XCTAssertLessThan(elapsed, 0.2, "Home data load should complete in < 200ms, took \(elapsed * 1000)ms")
    }

    /// Prayer time precomputation (the path used during app launch to cache prayers).
    /// Budget: under 100ms since this runs during splash screen.
    func test_prayerPrecomputation_under100ms() async throws {
        let prayerRepo = PrayerRepository(coreData: CoreDataStack.shared)
        let london = Coordinates(latitude: 51.5074, longitude: -0.1278)

        let start = CFAbsoluteTimeGetCurrent()
        let prayers = try await prayerRepo.getPrayers(
            for: Date(),
            location: london,
            method: .muslimWorldLeague,
            madhab: .hanafi
        )
        let elapsed = CFAbsoluteTimeGetCurrent() - start

        XCTAssertEqual(prayers.count, 6, "Should return 6 prayer times")
        XCTAssertLessThan(elapsed, 0.1, "Prayer precomputation should complete in < 100ms, took \(elapsed * 1000)ms")
    }

    /// Database pre-warm should complete quickly (decompresses SQLite on first run,
    /// then no-ops on subsequent runs).
    func test_databasePreWarm_under500ms() async {
        let start = CFAbsoluteTimeGetCurrent()
        await SQLiteService.shared.preWarmDatabases()
        let elapsed = CFAbsoluteTimeGetCurrent() - start

        // After first run, this should be nearly instant (files already decompressed)
        XCTAssertLessThan(elapsed, 0.5, "Database pre-warm should complete in < 500ms, took \(elapsed * 1000)ms")
    }

    /// Full launch sequence simulation: preferences load + prayer precompute + DB warm.
    /// Budget: under 2s total (the plan's stated launch target).
    func test_fullLaunchSequence_under2s() async throws {
        let coreData = CoreDataStack.shared
        let prayerRepo = PrayerRepository(coreData: coreData)
        let userRepo = UserRepository(coreData: coreData)
        let london = Coordinates(latitude: 51.5074, longitude: -0.1278)

        let start = CFAbsoluteTimeGetCurrent()

        // 1. Load preferences
        _ = await userRepo.getPreferences()

        // 2. Precompute prayer times
        _ = try await prayerRepo.getPrayers(
            for: Date(),
            location: london,
            method: .muslimWorldLeague,
            madhab: .hanafi
        )

        // 3. Pre-warm databases
        await SQLiteService.shared.preWarmDatabases()

        // 4. Prune hasanat tracker
        HasanatTracker.pruneOldEntries()

        let elapsed = CFAbsoluteTimeGetCurrent() - start

        XCTAssertLessThan(elapsed, 2.0, "Full launch sequence should complete in < 2s, took \(elapsed * 1000)ms")
    }
}
