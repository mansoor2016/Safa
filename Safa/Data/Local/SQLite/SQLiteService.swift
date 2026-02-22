// MARK: - SQLiteService.swift
// PURPOSE: Provides access to bundled SQLite databases (Quran, Hadith)
// DEPENDENCIES: SQLite3, Foundation

import Foundation
import SQLite3

/// Errors that can occur during SQLite operations
enum SQLiteError: LocalizedError {
    case databaseNotFound(String)
    case openFailed(String)
    case queryFailed(String)
    case prepareFailed(String)

    var errorDescription: String? {
        switch self {
        case .databaseNotFound(let name):
            return String(localized: "Database '\(name)' not found in bundle")
        case .openFailed(let reason):
            return String(localized: "Failed to open database: \(reason)")
        case .queryFailed(let reason):
            return String(localized: "Query failed: \(reason)")
        case .prepareFailed(let reason):
            return String(localized: "Failed to prepare statement: \(reason)")
        }
    }
}

/// Service for reading from bundled SQLite databases
final class SQLiteService {
    // MARK: - Singleton
    static let shared = SQLiteService()

    // MARK: - Persistent Connections
    private var persistentConnections: [String: OpaquePointer] = [:]
    private let connectionLock = NSLock()

    private init() {}

    deinit {
        for (_, db) in persistentConnections {
            sqlite3_close(db)
        }
    }

    // MARK: - Pre-Warm (call on app launch, runs off main thread)

    /// Decompress any gzipped databases in the background so they're ready when needed.
    /// Call from SafaApp.task{} — safe to call multiple times (no-ops if already decompressed).
    func preWarmDatabases() async {
        // Run sequentially to avoid crossing actor isolation in task-group closures under Swift 6.
        for name in ["quran", "hadith"] {
            _ = databasePath(for: name)
        }
    }

    // MARK: - Database Paths

    /// Get path to a usable database file, decompressing from .gz if needed
    func databasePath(for name: String) -> URL? {
        // Check if uncompressed file exists in bundle
        if let path = Bundle.main.url(forResource: name, withExtension: "sqlite", subdirectory: "Data/Database") {
            return path
        }
        if let path = Bundle.main.url(forResource: name, withExtension: "sqlite") {
            return path
        }

        // Check for gzipped version — decompress to Application Support on first use
        if let gzPath = Bundle.main.url(forResource: name, withExtension: "sqlite.gz", subdirectory: "Data/Database")
            ?? Bundle.main.url(forResource: name, withExtension: "sqlite.gz") {
            return decompressIfNeeded(gzPath: gzPath, name: name)
        }

        return nil
    }

    /// Decompress a .gz database to Application Support, re-decompressing when the bundled .gz changes.
    /// Thread-safe: uses connectionLock (same lock as openDatabase) to prevent races and deadlocks.
    private func decompressIfNeeded(gzPath: URL, name: String) -> URL? {
        let fileManager = FileManager.default
        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }

        let dbDir = appSupport.appendingPathComponent("Databases")
        let targetPath = dbDir.appendingPathComponent("\(name).sqlite")
        let markerPath = dbDir.appendingPathComponent("\(name).gz.size")

        // Fast path (no lock): cached DB is up-to-date
        let bundledSize = (try? fileManager.attributesOfItem(atPath: gzPath.path)[.size] as? Int) ?? 0
        if fileManager.fileExists(atPath: targetPath.path),
           let markerData = try? Data(contentsOf: markerPath),
           let markerString = String(data: markerData, encoding: .utf8),
           let cachedSize = Int(markerString),
           cachedSize == bundledSize {
            return targetPath
        }

        // Slow path: need to decompress — acquire lock to prevent races
        connectionLock.lock()
        defer { connectionLock.unlock() }

        // Re-check under lock (another thread may have completed decompression while we waited)
        if fileManager.fileExists(atPath: targetPath.path),
           let markerData = try? Data(contentsOf: markerPath),
           let markerString = String(data: markerData, encoding: .utf8),
           let cachedSize = Int(markerString),
           cachedSize == bundledSize {
            return targetPath
        }

        // Close any existing persistent connection before replacing the file
        if let existing = persistentConnections.removeValue(forKey: name) {
            sqlite3_close(existing)
        }

        // Decompress gzip to Application Support
        do {
            try fileManager.createDirectory(at: dbDir, withIntermediateDirectories: true)
            let compressedData = try Data(contentsOf: gzPath)
            guard let decompressed = compressedData.gunzip() else { return nil }
            try decompressed.write(to: targetPath)
            try Data("\(bundledSize)".utf8).write(to: markerPath)
            return targetPath
        } catch {
            return nil
        }
    }

    // MARK: - Database Operations

    /// Get or create a persistent read-only connection for a database
    func openDatabase(named name: String) throws -> OpaquePointer {
        // Check for cached connection first (fast path)
        connectionLock.lock()
        if let existing = persistentConnections[name] {
            connectionLock.unlock()
            return existing
        }
        connectionLock.unlock()

        // Resolve path outside the lock (may trigger decompression, which also uses connectionLock)
        guard let dbPath = databasePath(for: name) else {
            throw SQLiteError.databaseNotFound(name)
        }

        // Re-acquire lock to create and cache the connection
        connectionLock.lock()
        defer { connectionLock.unlock() }

        // Re-check: another thread may have opened it while we were resolving the path
        if let existing = persistentConnections[name] {
            return existing
        }

        var db: OpaquePointer?
        let flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX

        if sqlite3_open_v2(dbPath.path, &db, flags, nil) != SQLITE_OK {
            let error = String(cString: sqlite3_errmsg(db))
            throw SQLiteError.openFailed(error)
        }

        guard let database = db else {
            throw SQLiteError.openFailed("Unknown error")
        }

        persistentConnections[name] = database
        return database
    }

    /// Close is a no-op for persistent connections (they close on deinit)
    func closeDatabase(_ db: OpaquePointer) {
        // Managed by service lifecycle — no-op for backward compatibility
    }

    /// Execute a query and return results
    func query<T>(
        database: OpaquePointer,
        sql: String,
        parameters: [Any] = [],
        mapper: (OpaquePointer) -> T?
    ) throws -> [T] {
        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            let error = String(cString: sqlite3_errmsg(database))
            throw SQLiteError.prepareFailed(error)
        }

        defer { sqlite3_finalize(statement) }

        // Bind parameters
        for (index, param) in parameters.enumerated() {
            let bindIndex = Int32(index + 1)
            switch param {
            case let value as Int:
                sqlite3_bind_int64(statement, bindIndex, Int64(value))
            case let value as Int64:
                sqlite3_bind_int64(statement, bindIndex, value)
            case let value as Double:
                sqlite3_bind_double(statement, bindIndex, value)
            case let value as String:
                sqlite3_bind_text(statement, bindIndex, value, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
            case let value as Data:
                _ = value.withUnsafeBytes { ptr in
                    sqlite3_bind_blob(statement, bindIndex, ptr.baseAddress, Int32(value.count), unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                }
            default:
                sqlite3_bind_null(statement, bindIndex)
            }
        }

        var results: [T] = []

        while sqlite3_step(statement) == SQLITE_ROW {
            if let item = mapper(statement!) {
                results.append(item)
            }
        }

        return results
    }

    /// Execute a query that returns a single result
    func queryOne<T>(
        database: OpaquePointer,
        sql: String,
        parameters: [Any] = [],
        mapper: (OpaquePointer) -> T?
    ) throws -> T? {
        let results: [T] = try query(database: database, sql: sql, parameters: parameters, mapper: mapper)
        return results.first
    }

    // MARK: - Helper Methods

    /// Get string from column
    func getString(_ statement: OpaquePointer, column: Int32) -> String {
        guard let cString = sqlite3_column_text(statement, column) else {
            return ""
        }
        return String(cString: cString)
    }

    /// Get optional string from column
    func getOptionalString(_ statement: OpaquePointer, column: Int32) -> String? {
        guard sqlite3_column_type(statement, column) != SQLITE_NULL else {
            return nil
        }
        return getString(statement, column: column)
    }

    /// Get int from column
    func getInt(_ statement: OpaquePointer, column: Int32) -> Int {
        Int(sqlite3_column_int64(statement, column))
    }

    /// Get double from column
    func getDouble(_ statement: OpaquePointer, column: Int32) -> Double {
        sqlite3_column_double(statement, column)
    }
}

// MARK: - Quran Database Operations

extension SQLiteService {
    /// Load all surahs from Quran database
    func loadAllSurahs() throws -> [Surah] {
        let db = try openDatabase(named: "quran")
        defer { closeDatabase(db) }

        let sql = """
            SELECT id, name_arabic, name_english, name_transliteration,
                   revelation_type, ayah_count, juz_start
            FROM surahs ORDER BY id
        """

        return try query(database: db, sql: sql) { stmt in
            let revelationType: Surah.RevelationType = getString(stmt, column: 4) == "Meccan" ? .meccan : .medinan

            return Surah(
                id: getInt(stmt, column: 0),
                nameArabic: getString(stmt, column: 1),
                nameEnglish: getString(stmt, column: 2),
                nameTransliteration: getString(stmt, column: 3),
                revelationType: revelationType,
                ayahCount: getInt(stmt, column: 5),
                juzStart: getInt(stmt, column: 6)
            )
        }
    }

    /// Load ayahs for a specific surah
    func loadAyahs(forSurah surahNumber: Int) throws -> [Ayah] {
        let db = try openDatabase(named: "quran")
        defer { closeDatabase(db) }

        let sql = """
            SELECT surah_number, ayah_number, text_arabic, text_translation,
                   text_transliteration, juz_number, page_number
            FROM ayahs WHERE surah_number = ? ORDER BY ayah_number
        """

        return try query(database: db, sql: sql, parameters: [surahNumber]) { stmt in
            Ayah(
                surahNumber: getInt(stmt, column: 0),
                ayahNumber: getInt(stmt, column: 1),
                textArabic: getString(stmt, column: 2),
                textTranslation: getString(stmt, column: 3),
                textTransliteration: getOptionalString(stmt, column: 4),
                juzNumber: getInt(stmt, column: 5),
                pageNumber: getInt(stmt, column: 6)
            )
        }
    }

    /// Search ayahs using full-text search
    func searchAyahs(query: String) throws -> [Ayah] {
        let db = try openDatabase(named: "quran")
        defer { closeDatabase(db) }

        let sql = """
            SELECT a.surah_number, a.ayah_number, a.text_arabic, a.text_translation,
                   a.text_transliteration, a.juz_number, a.page_number
            FROM ayahs a
            JOIN ayahs_fts fts ON a.rowid = fts.rowid
            WHERE ayahs_fts MATCH ?
            LIMIT 100
        """

        return try self.query(database: db, sql: sql, parameters: [query]) { stmt in
            Ayah(
                surahNumber: getInt(stmt, column: 0),
                ayahNumber: getInt(stmt, column: 1),
                textArabic: getString(stmt, column: 2),
                textTranslation: getString(stmt, column: 3),
                textTransliteration: getOptionalString(stmt, column: 4),
                juzNumber: getInt(stmt, column: 5),
                pageNumber: getInt(stmt, column: 6)
            )
        }
    }

    /// Load all juz from database
    func loadAllJuz() throws -> [Juz] {
        let db = try openDatabase(named: "quran")
        defer { closeDatabase(db) }

        let sql = """
            SELECT id, start_surah, start_ayah, end_surah, end_ayah
            FROM juz ORDER BY id
        """

        return try query(database: db, sql: sql) { stmt in
            Juz(
                id: getInt(stmt, column: 0),
                startSurah: getInt(stmt, column: 1),
                startAyah: getInt(stmt, column: 2),
                endSurah: getInt(stmt, column: 3),
                endAyah: getInt(stmt, column: 4)
            )
        }
    }
}

// MARK: - Hadith Database Operations

extension SQLiteService {
    /// Load all hadith collections
    func loadAllCollections() throws -> [HadithCollection] {
        let db = try openDatabase(named: "hadith")
        defer { closeDatabase(db) }

        let sql = """
            SELECT id, name_english, name_arabic, compiler_name, total_hadiths, total_books
            FROM hadith_collections ORDER BY id
        """

        return try query(database: db, sql: sql) { stmt in
            HadithCollection(
                id: getString(stmt, column: 0),
                nameEnglish: getString(stmt, column: 1),
                nameArabic: getString(stmt, column: 2),
                compilerName: getString(stmt, column: 3),
                totalHadiths: getInt(stmt, column: 4),
                totalBooks: getInt(stmt, column: 5)
            )
        }
    }

    /// Load books for a collection
    func loadBooks(forCollection collectionId: String) throws -> [HadithBook] {
        let db = try openDatabase(named: "hadith")
        defer { closeDatabase(db) }

        let sql = """
            SELECT id, collection_id, book_number, name_english, name_arabic, hadith_count
            FROM hadith_books WHERE collection_id = ? ORDER BY book_number
        """

        return try query(database: db, sql: sql, parameters: [collectionId]) { stmt in
            HadithBook(
                id: getString(stmt, column: 0),
                collectionId: getString(stmt, column: 1),
                bookNumber: getInt(stmt, column: 2),
                nameEnglish: getString(stmt, column: 3),
                nameArabic: getString(stmt, column: 4),
                hadithCount: getInt(stmt, column: 5)
            )
        }
    }

    /// Load hadiths for a book
    func loadHadiths(forBook bookId: String) throws -> [Hadith] {
        let db = try openDatabase(named: "hadith")
        defer { closeDatabase(db) }

        let sql = """
            SELECT id, collection_id, book_id, hadith_number, text_arabic, text_english,
                   narrator_chain, narrator, grading, reference
            FROM hadiths WHERE book_id = ? ORDER BY hadith_number
        """

        return try query(database: db, sql: sql, parameters: [bookId]) { stmt in
            parseHadith(stmt)
        }
    }

    /// Search hadiths using full-text search
    func searchHadiths(query: String) throws -> [Hadith] {
        let db = try openDatabase(named: "hadith")
        defer { closeDatabase(db) }

        let sql = """
            SELECT h.id, h.collection_id, h.book_id, h.hadith_number, h.text_arabic, h.text_english,
                   h.narrator_chain, h.narrator, h.grading, h.reference
            FROM hadiths h
            JOIN hadiths_fts fts ON h.rowid = fts.rowid
            WHERE hadiths_fts MATCH ?
            LIMIT 100
        """

        return try self.query(database: db, sql: sql, parameters: [query]) { stmt in
            parseHadith(stmt)
        }
    }

    /// Get random hadith for daily hadith feature
    func getRandomHadith(seed: Int) throws -> Hadith? {
        let db = try openDatabase(named: "hadith")
        defer { closeDatabase(db) }

        // Get total count
        let countSql = "SELECT COUNT(*) FROM hadiths"
        let count: Int = try queryOne(database: db, sql: countSql) { stmt in
            getInt(stmt, column: 0)
        } ?? 0

        guard count > 0 else { return nil }

        // Use seed to pick consistent hadith for the day
        let offset = seed % count

        let sql = """
            SELECT id, collection_id, book_id, hadith_number, text_arabic, text_english,
                   narrator_chain, narrator, grading, reference
            FROM hadiths LIMIT 1 OFFSET ?
        """

        return try queryOne(database: db, sql: sql, parameters: [offset]) { stmt in
            parseHadith(stmt)
        }
    }

    private func parseHadith(_ stmt: OpaquePointer) -> Hadith {
        let gradingStr = getOptionalString(stmt, column: 8) ?? "Unknown"
        let grading: HadithGrading
        switch gradingStr {
        case "Sahih": grading = .sahih
        case "Hasan": grading = .hasan
        case "Da'if": grading = .daif
        case "Mawdu'": grading = .mawdu
        default: grading = .unknown
        }

        return Hadith(
            id: getString(stmt, column: 0),
            collectionId: getString(stmt, column: 1),
            bookId: getString(stmt, column: 2),
            hadithNumber: getInt(stmt, column: 3),
            textArabic: getString(stmt, column: 4),
            textEnglish: getString(stmt, column: 5),
            narratorChain: getOptionalString(stmt, column: 6),
            narrator: getString(stmt, column: 7),
            grading: grading,
            reference: getString(stmt, column: 9)
        )
    }
}
