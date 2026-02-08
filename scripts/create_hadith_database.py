#!/usr/bin/env python3
"""
Creates hadith.sqlite database with full Kutub al-Sittah hadith data.
Downloads JSON data from AhmedBaset/hadith-json (sourced from sunnah.com).

Collections included (34,000+ hadiths):
- Sahih al-Bukhari (7,277)
- Sahih Muslim (7,459)
- Sunan Abu Dawud (5,276)
- Jami at-Tirmidhi (4,053)
- Sunan an-Nasa'i (5,768)
- Sunan Ibn Majah (4,345)
"""

import sqlite3
import json
import os
import urllib.request

# Output path (relative to scripts/ directory)
DB_PATH = os.path.join(os.path.dirname(__file__), "..", "Safa", "Resources", "Data", "Database", "hadith.sqlite")
CACHE_DIR = os.path.join(os.path.dirname(__file__), "data")

# GitHub raw URL base for hadith-json project
GITHUB_BASE = "https://raw.githubusercontent.com/AhmedBaset/hadith-json/main/db/by_book/the_9_books"

# Collection metadata: (file_name, collection_id, name_english, name_arabic, compiler_name)
COLLECTIONS = [
    ("bukhari", "bukhari", "Sahih al-Bukhari", "صحيح البخاري", "Imam Muhammad al-Bukhari"),
    ("muslim", "muslim", "Sahih Muslim", "صحيح مسلم", "Imam Muslim ibn al-Hajjaj"),
    ("abudawud", "abudawud", "Sunan Abu Dawud", "سنن أبي داود", "Imam Abu Dawud"),
    ("tirmidhi", "tirmidhi", "Jami at-Tirmidhi", "جامع الترمذي", "Imam at-Tirmidhi"),
    ("nasai", "nasai", "Sunan an-Nasa'i", "سنن النسائي", "Imam an-Nasa'i"),
    ("ibnmajah", "ibnmajah", "Sunan Ibn Majah", "سنن ابن ماجه", "Imam Ibn Majah"),
]

# Default grading per collection
# Bukhari and Muslim are universally accepted as Sahih
# Others contain a mix but are predominantly Sahih/Hasan
DEFAULT_GRADING = {
    "bukhari": "Sahih",
    "muslim": "Sahih",
    "abudawud": "Hasan",
    "tirmidhi": "Hasan",
    "nasai": "Hasan",
    "ibnmajah": "Hasan",
}

# Hadith topics for categorization
TOPICS = [
    "Faith", "Prayer", "Purification", "Fasting", "Zakat",
    "Hajj", "Quran", "Knowledge", "Manners", "Family",
    "Business", "Jihad", "Afterlife", "Prophets", "Companions",
]


def download_json(file_name):
    """Download a collection JSON file from GitHub, caching locally."""
    os.makedirs(CACHE_DIR, exist_ok=True)
    cache_path = os.path.join(CACHE_DIR, f"{file_name}.json")

    if os.path.exists(cache_path):
        print(f"  Using cached {file_name}.json")
        with open(cache_path, "r", encoding="utf-8") as f:
            return json.load(f)

    url = f"{GITHUB_BASE}/{file_name}.json"
    print(f"  Downloading {file_name}.json from GitHub...")
    req = urllib.request.Request(url, headers={"User-Agent": "Safa-iOS-App/1.0"})
    with urllib.request.urlopen(req) as response:
        data = response.read()
        # Cache to disk
        with open(cache_path, "wb") as f:
            f.write(data)
        return json.loads(data.decode("utf-8"))


def extract_narrator(english_obj):
    """Extract narrator name from english field. Handles both string and dict formats."""
    if isinstance(english_obj, dict):
        narrator = english_obj.get("narrator", "")
        # Clean up "Narrated X:" format to just "X"
        if narrator.startswith("Narrated "):
            narrator = narrator[len("Narrated "):]
        narrator = narrator.rstrip(":").strip()
        return narrator
    return ""


def extract_english_text(english_obj):
    """Extract English translation text from english field."""
    if isinstance(english_obj, dict):
        return english_obj.get("text", "").strip()
    if isinstance(english_obj, str):
        return english_obj.strip()
    return ""


def create_database():
    """Create the Hadith SQLite database with full data."""

    # Ensure output directory exists
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)

    # Remove existing database
    if os.path.exists(DB_PATH):
        os.remove(DB_PATH)

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    # Enable WAL mode for faster writes
    cursor.execute("PRAGMA journal_mode=WAL")

    # Create tables (same schema as before)
    cursor.executescript("""
        CREATE TABLE hadith_collections (
            id TEXT PRIMARY KEY,
            name_english TEXT NOT NULL,
            name_arabic TEXT NOT NULL,
            compiler_name TEXT NOT NULL,
            total_hadiths INTEGER NOT NULL,
            total_books INTEGER NOT NULL
        );

        CREATE TABLE hadith_books (
            id TEXT PRIMARY KEY,
            collection_id TEXT NOT NULL,
            book_number INTEGER NOT NULL,
            name_english TEXT NOT NULL,
            name_arabic TEXT NOT NULL,
            hadith_count INTEGER NOT NULL,
            FOREIGN KEY(collection_id) REFERENCES hadith_collections(id)
        );

        CREATE TABLE hadiths (
            id TEXT PRIMARY KEY,
            collection_id TEXT NOT NULL,
            book_id TEXT NOT NULL,
            hadith_number INTEGER NOT NULL,
            text_arabic TEXT NOT NULL,
            text_english TEXT NOT NULL,
            narrator_chain TEXT,
            narrator TEXT NOT NULL,
            grading TEXT CHECK(grading IN ('Sahih', 'Hasan', 'Da''if', 'Mawdu''', 'Unknown')),
            reference TEXT NOT NULL,
            FOREIGN KEY(collection_id) REFERENCES hadith_collections(id),
            FOREIGN KEY(book_id) REFERENCES hadith_books(id)
        );

        CREATE TABLE hadith_topics (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            topic TEXT NOT NULL UNIQUE
        );

        CREATE TABLE hadith_topics_junction (
            hadith_id TEXT NOT NULL,
            topic_id INTEGER NOT NULL,
            PRIMARY KEY(hadith_id, topic_id),
            FOREIGN KEY(hadith_id) REFERENCES hadiths(id),
            FOREIGN KEY(topic_id) REFERENCES hadith_topics(id)
        );

        CREATE INDEX idx_hadiths_collection ON hadiths(collection_id);
        CREATE INDEX idx_hadiths_book ON hadiths(book_id);
        CREATE INDEX idx_hadiths_grading ON hadiths(grading);
        CREATE INDEX idx_books_collection ON hadith_books(collection_id);
    """)

    # Insert topics
    cursor.executemany(
        "INSERT INTO hadith_topics (topic) VALUES (?)",
        [(t,) for t in TOPICS]
    )

    total_hadiths = 0
    total_books = 0

    # Process each collection
    for file_name, collection_id, name_en, name_ar, compiler in COLLECTIONS:
        print(f"\nProcessing {name_en}...")
        data = download_json(file_name)

        chapters = data.get("chapters", [])
        hadiths = data.get("hadiths", [])
        grading = DEFAULT_GRADING[collection_id]

        # Build chapter_id -> chapter mapping for book lookups
        chapter_map = {}
        for ch in chapters:
            ch_id = ch["id"]
            chapter_map[ch_id] = ch

        # Insert collection (with actual counts)
        cursor.execute(
            "INSERT INTO hadith_collections (id, name_english, name_arabic, compiler_name, total_hadiths, total_books) VALUES (?, ?, ?, ?, ?, ?)",
            (collection_id, name_en, name_ar, compiler, len(hadiths), len(chapters))
        )

        # Insert books (chapters in the JSON = books in our schema)
        # Count hadiths per chapter
        hadiths_per_chapter = {}
        for h in hadiths:
            ch_id = h.get("chapterId", 0)
            hadiths_per_chapter[ch_id] = hadiths_per_chapter.get(ch_id, 0) + 1

        for ch in chapters:
            ch_id = ch.get("id")
            if ch_id is None:
                continue  # Skip chapters with null IDs
            book_id = f"{collection_id}_{ch_id}"
            book_number = ch_id
            name_english = ch.get("english", f"Book {ch_id}")
            name_arabic = ch.get("arabic", "")
            hadith_count = hadiths_per_chapter.get(ch_id, 0)

            cursor.execute(
                "INSERT OR IGNORE INTO hadith_books (id, collection_id, book_number, name_english, name_arabic, hadith_count) VALUES (?, ?, ?, ?, ?, ?)",
                (book_id, collection_id, book_number, name_english, name_arabic, hadith_count)
            )
            total_books += 1

        # Insert hadiths
        hadith_rows = []
        for h in hadiths:
            hadith_id_num = h.get("id")
            if hadith_id_num is None:
                continue
            ch_id = h.get("chapterId") or 1  # Default to 1 if null
            book_id = f"{collection_id}_{ch_id}"
            hadith_number = hadith_id_num

            arabic = h.get("arabic", "").strip()
            english_obj = h.get("english", {})
            english_text = extract_english_text(english_obj)
            narrator = extract_narrator(english_obj)

            # Skip hadiths with empty text
            if not arabic and not english_text:
                continue

            # Use empty string fallbacks
            if not arabic:
                arabic = ""
            if not english_text:
                english_text = ""
            if not narrator:
                narrator = "Unknown"

            hadith_id = f"{collection_id}_{ch_id}_{hadith_id_num}"
            reference = f"{name_en.split()[-1]} {hadith_id_num}"  # e.g. "Bukhari 1"

            hadith_rows.append((
                hadith_id,
                collection_id,
                book_id,
                hadith_number,
                arabic,
                english_text,
                None,  # narrator_chain (not available in this dataset)
                narrator,
                grading,
                reference,
            ))

        cursor.executemany(
            """INSERT OR IGNORE INTO hadiths
               (id, collection_id, book_id, hadith_number, text_arabic, text_english, narrator_chain, narrator, grading, reference)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            hadith_rows
        )

        inserted = len(hadith_rows)
        total_hadiths += inserted
        print(f"  Inserted {inserted} hadiths across {len(chapters)} books")

    # Build FTS5 index
    print("\nBuilding full-text search index...")
    cursor.execute("""
        CREATE VIRTUAL TABLE IF NOT EXISTS hadiths_fts USING fts5(
            text_arabic,
            text_english,
            narrator,
            content='hadiths',
            content_rowid='rowid'
        )
    """)
    cursor.execute("""
        INSERT INTO hadiths_fts(rowid, text_arabic, text_english, narrator)
        SELECT rowid, text_arabic, text_english, narrator FROM hadiths
    """)

    conn.commit()

    # Verify
    cursor.execute("SELECT COUNT(*) FROM hadith_collections")
    coll_count = cursor.fetchone()[0]
    cursor.execute("SELECT COUNT(*) FROM hadith_books")
    book_count = cursor.fetchone()[0]
    cursor.execute("SELECT COUNT(*) FROM hadiths")
    hadith_count = cursor.fetchone()[0]
    cursor.execute("SELECT COUNT(*) FROM hadiths_fts")
    fts_count = cursor.fetchone()[0]

    # Verify per collection
    print(f"\n{'='*50}")
    print(f"Created hadith.sqlite:")
    print(f"  Collections: {coll_count}")
    print(f"  Books: {book_count}")
    print(f"  Hadiths: {hadith_count}")
    print(f"  FTS entries: {fts_count}")
    print(f"  Topics: {len(TOPICS)}")

    cursor.execute("SELECT id, name_english, total_hadiths, total_books FROM hadith_collections ORDER BY id")
    for row in cursor.fetchall():
        cursor.execute("SELECT COUNT(*) FROM hadiths WHERE collection_id = ?", (row[0],))
        actual = cursor.fetchone()[0]
        print(f"  {row[1]}: {actual} hadiths, {row[3]} books")

    file_size = os.path.getsize(DB_PATH)
    print(f"\nDatabase size: {file_size / 1024:.0f} KB ({file_size / (1024*1024):.1f} MB)")

    # Switch back to default journal mode for the bundled database
    cursor.execute("PRAGMA journal_mode=DELETE")
    conn.close()


if __name__ == "__main__":
    create_database()
