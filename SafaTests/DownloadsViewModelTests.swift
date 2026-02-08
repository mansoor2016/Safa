// MARK: - DownloadsViewModelTests.swift
// PURPOSE: Unit tests for DownloadsViewModel functionality
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

final class DownloadsViewModelTests: XCTestCase {

    var sut: DownloadsViewModel!

    override func setUp() {
        super.setUp()
        sut = DownloadsViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func test_initialState_loadsDownloads() {
        XCTAssertFalse(sut.downloads.isEmpty)
    }

    func test_initialState_isLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading)
    }

    func test_initialState_wifiOnlyEnabledIsTrue() {
        XCTAssertTrue(sut.wifiOnlyEnabled)
    }

    func test_initialState_autoUpdateEnabledIsFalse() {
        XCTAssertFalse(sut.autoUpdateEnabled)
    }

    func test_initialState_smartCleanupEnabledIsTrue() {
        XCTAssertTrue(sut.smartCleanupEnabled)
    }

    // MARK: - Downloads Data Tests

    func test_downloads_containsQuranAudio() {
        let quranAudio = sut.downloads.filter { $0.category == .quranAudio }
        XCTAssertFalse(quranAudio.isEmpty)
    }

    func test_downloads_containsDhikrAudio() {
        let dhikrAudio = sut.downloads.filter { $0.category == .dhikrAudio }
        XCTAssertFalse(dhikrAudio.isEmpty)
    }

    func test_downloads_containsLearningContent() {
        let learningContent = sut.downloads.filter { $0.category == .learningContent }
        XCTAssertFalse(learningContent.isEmpty)
    }

    func test_downloads_containsAIModel() {
        let aiModel = sut.downloads.filter { $0.category == .aiModel }
        XCTAssertFalse(aiModel.isEmpty)
    }

    func test_downloads_allHaveValidIds() {
        for download in sut.downloads {
            XCTAssertFalse(download.id.isEmpty, "Download should have non-empty id")
        }
    }

    func test_downloads_allHaveValidTitles() {
        for download in sut.downloads {
            XCTAssertFalse(download.title.isEmpty, "Download \(download.id) should have title")
        }
    }

    func test_downloads_allHavePositiveSize() {
        for download in sut.downloads {
            XCTAssertGreaterThan(download.size, 0, "Download \(download.id) should have positive size")
        }
    }

    // MARK: - Total Downloaded Size Tests

    func test_totalDownloadedSize_calculatesCorrectly() {
        let downloadedItems = sut.downloads.filter { $0.status == .downloaded }
        let expectedSize = downloadedItems.reduce(0) { $0 + $1.size }
        XCTAssertEqual(sut.totalDownloadedSize, expectedSize)
    }

    func test_totalDownloadedSize_excludesNotDownloaded() {
        // All items not downloaded should not contribute
        for index in sut.downloads.indices {
            sut.downloads[index].status = .notDownloaded
        }
        XCTAssertEqual(sut.totalDownloadedSize, 0)
    }

    func test_formattedTotalSize_isNotEmpty() {
        XCTAssertFalse(sut.formattedTotalSize.isEmpty)
    }

    // MARK: - Downloads By Category Tests

    func test_downloadsByCategory_groupsCorrectly() {
        let grouped = sut.downloadsByCategory

        for (category, items) in grouped {
            XCTAssertTrue(items.allSatisfy { $0.category == category })
        }
    }

    func test_downloadsByCategory_containsAllItems() {
        let grouped = sut.downloadsByCategory
        let totalGrouped = grouped.values.reduce(0) { $0 + $1.count }
        XCTAssertEqual(totalGrouped, sut.downloads.count)
    }

    // MARK: - Delete Download Tests

    func test_deleteDownload_setsStatusToNotDownloaded() {
        guard let downloadedItem = sut.downloads.first(where: { $0.status == .downloaded }) else {
            XCTFail("Should have at least one downloaded item")
            return
        }

        sut.deleteDownload(downloadedItem)

        let updatedItem = sut.downloads.first { $0.id == downloadedItem.id }
        XCTAssertEqual(updatedItem?.status, .notDownloaded)
    }

    func test_deleteDownload_resetsProgress() {
        guard let downloadedItem = sut.downloads.first(where: { $0.status == .downloaded }) else {
            XCTFail("Should have at least one downloaded item")
            return
        }

        sut.deleteDownload(downloadedItem)

        let updatedItem = sut.downloads.first { $0.id == downloadedItem.id }
        XCTAssertEqual(updatedItem?.progress, 0)
    }

    // MARK: - Delete All Downloads Tests

    func test_deleteAllDownloads_setsAllToNotDownloaded() {
        sut.deleteAllDownloads()

        for download in sut.downloads {
            XCTAssertEqual(download.status, .notDownloaded, "Download \(download.id) should be not downloaded")
        }
    }

    func test_deleteAllDownloads_resetsAllProgress() {
        sut.deleteAllDownloads()

        for download in sut.downloads {
            XCTAssertEqual(download.progress, 0, "Download \(download.id) should have zero progress")
        }
    }

    func test_deleteAllDownloads_totalSizeBecomesZero() {
        sut.deleteAllDownloads()
        XCTAssertEqual(sut.totalDownloadedSize, 0)
    }

    // MARK: - Pause Download Tests

    func test_pauseDownload_setsStatusToNotDownloaded() {
        guard let item = sut.downloads.first else {
            XCTFail("Should have downloads")
            return
        }

        // Start a download first
        sut.startDownload(item)

        // Then pause it
        let downloadingItem = sut.downloads.first { $0.id == item.id }!
        sut.pauseDownload(downloadingItem)

        let pausedItem = sut.downloads.first { $0.id == item.id }
        XCTAssertEqual(pausedItem?.status, .notDownloaded)
    }

    // MARK: - Start Download Tests

    func test_startDownload_setsStatusToDownloading() {
        guard let notDownloadedItem = sut.downloads.first(where: { $0.status == .notDownloaded }) else {
            XCTFail("Should have at least one not downloaded item")
            return
        }

        sut.startDownload(notDownloadedItem)

        let updatedItem = sut.downloads.first { $0.id == notDownloadedItem.id }
        XCTAssertEqual(updatedItem?.status, .downloading)
    }

    func test_startDownload_resetsProgress() {
        guard let notDownloadedItem = sut.downloads.first(where: { $0.status == .notDownloaded }) else {
            XCTFail("Should have at least one not downloaded item")
            return
        }

        sut.startDownload(notDownloadedItem)

        let updatedItem = sut.downloads.first { $0.id == notDownloadedItem.id }
        XCTAssertEqual(updatedItem?.progress, 0)
    }

    // MARK: - DownloadItem Model Tests

    func test_downloadItem_isIdentifiable() {
        let item = DownloadItem(
            id: "test",
            title: "Test",
            subtitle: "Test subtitle",
            category: .quranAudio,
            size: 1000,
            status: .notDownloaded,
            progress: 0
        )
        XCTAssertEqual(item.id, "test")
    }

    func test_downloadItem_storesAllProperties() {
        let item = DownloadItem(
            id: "test",
            title: "Test Title",
            subtitle: "Test Subtitle",
            category: .dhikrAudio,
            size: 50_000_000,
            status: .downloaded,
            progress: 1.0
        )

        XCTAssertEqual(item.id, "test")
        XCTAssertEqual(item.title, "Test Title")
        XCTAssertEqual(item.subtitle, "Test Subtitle")
        XCTAssertEqual(item.category, .dhikrAudio)
        XCTAssertEqual(item.size, 50_000_000)
        XCTAssertEqual(item.status, .downloaded)
        XCTAssertEqual(item.progress, 1.0)
    }

    // MARK: - DownloadCategory Enum Tests

    func test_downloadCategory_allCases() {
        XCTAssertEqual(DownloadCategory.allCases.count, 4)
        XCTAssertTrue(DownloadCategory.allCases.contains(.quranAudio))
        XCTAssertTrue(DownloadCategory.allCases.contains(.dhikrAudio))
        XCTAssertTrue(DownloadCategory.allCases.contains(.learningContent))
        XCTAssertTrue(DownloadCategory.allCases.contains(.aiModel))
    }

    func test_downloadCategory_rawValues() {
        XCTAssertEqual(DownloadCategory.quranAudio.rawValue, "Quran Audio")
        XCTAssertEqual(DownloadCategory.dhikrAudio.rawValue, "Dhikr Audio")
        XCTAssertEqual(DownloadCategory.learningContent.rawValue, "Learning Content")
        XCTAssertEqual(DownloadCategory.aiModel.rawValue, "AI Model")
    }

    func test_downloadCategory_iconNames() {
        XCTAssertEqual(DownloadCategory.quranAudio.iconName, "book.fill")
        XCTAssertEqual(DownloadCategory.dhikrAudio.iconName, "waveform")
        XCTAssertEqual(DownloadCategory.learningContent.iconName, "graduationcap.fill")
        XCTAssertEqual(DownloadCategory.aiModel.iconName, "cpu")
    }

    // MARK: - DownloadStatus Enum Tests

    func test_downloadStatus_displayText() {
        XCTAssertEqual(DownloadStatus.notDownloaded.displayText, "Not Downloaded")
        XCTAssertEqual(DownloadStatus.downloading.displayText, "Downloading...")
        XCTAssertEqual(DownloadStatus.downloaded.displayText, "Downloaded")
        XCTAssertEqual(DownloadStatus.updateAvailable.displayText, "Update Available")
        XCTAssertEqual(DownloadStatus.error("Test error").displayText, "Error: Test error")
    }

    func test_downloadStatus_equatable() {
        XCTAssertEqual(DownloadStatus.notDownloaded, DownloadStatus.notDownloaded)
        XCTAssertEqual(DownloadStatus.downloaded, DownloadStatus.downloaded)
        XCTAssertEqual(DownloadStatus.error("msg"), DownloadStatus.error("msg"))
        XCTAssertNotEqual(DownloadStatus.error("msg1"), DownloadStatus.error("msg2"))
    }

    // MARK: - Settings Tests

    func test_wifiOnlyEnabled_canBeToggled() {
        sut.wifiOnlyEnabled = false
        XCTAssertFalse(sut.wifiOnlyEnabled)

        sut.wifiOnlyEnabled = true
        XCTAssertTrue(sut.wifiOnlyEnabled)
    }

    func test_autoUpdateEnabled_canBeToggled() {
        sut.autoUpdateEnabled = true
        XCTAssertTrue(sut.autoUpdateEnabled)

        sut.autoUpdateEnabled = false
        XCTAssertFalse(sut.autoUpdateEnabled)
    }

    func test_smartCleanupEnabled_canBeToggled() {
        sut.smartCleanupEnabled = false
        XCTAssertFalse(sut.smartCleanupEnabled)

        sut.smartCleanupEnabled = true
        XCTAssertTrue(sut.smartCleanupEnabled)
    }

    // MARK: - Load Downloads Tests

    func test_loadDownloads_populatesArray() {
        sut.downloads = []
        XCTAssertTrue(sut.downloads.isEmpty)

        sut.loadDownloads()
        XCTAssertFalse(sut.downloads.isEmpty)
    }

    func test_loadDownloads_containsMisharyRecitation() {
        let mishary = sut.downloads.first { $0.id == "quran-mishary" }
        XCTAssertNotNil(mishary)
        XCTAssertEqual(mishary?.title, "Mishary Rashid Alafasy")
    }

    func test_loadDownloads_containsAIModel() {
        let aiModel = sut.downloads.first { $0.id == "ai-model" }
        XCTAssertNotNil(aiModel)
        XCTAssertEqual(aiModel?.category, .aiModel)
    }

    // MARK: - Edge Cases

    func test_deleteDownload_nonExistentItem() {
        let fakeItem = DownloadItem(
            id: "non-existent",
            title: "Fake",
            subtitle: "Fake",
            category: .quranAudio,
            size: 1000,
            status: .downloaded,
            progress: 1.0
        )

        // Should not crash
        sut.deleteDownload(fakeItem)
    }

    func test_pauseDownload_nonExistentItem() {
        let fakeItem = DownloadItem(
            id: "non-existent",
            title: "Fake",
            subtitle: "Fake",
            category: .quranAudio,
            size: 1000,
            status: .downloading,
            progress: 0.5
        )

        // Should not crash
        sut.pauseDownload(fakeItem)
    }
}
