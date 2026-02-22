#!/usr/bin/env python3
"""
Fetches English transliteration from Quran.com API (resource 57) and updates
the text_transliteration column in quran.sqlite.

Usage: python3 scripts/add_transliteration.py
"""

import sqlite3
import os
import json
import urllib.request
import time
import re

DB_PATH = os.path.join(os.path.dirname(__file__), "..", "Safa", "Resources", "Data", "Database", "quran.sqlite")
CACHE_DIR = os.path.join(os.path.dirname(__file__), "data")
CACHE_FILE = os.path.join(CACHE_DIR, "transliteration_en.json")

# Quran.com API v4 — transliteration resource ID 57
API_BASE = "https://api.quran.com/api/v4/quran/translations/57"


def strip_html(text):
    """Remove HTML tags from transliteration text."""
    return re.sub(r"<[^>]+>", "", text)


def fetch_transliterations():
    """Fetch all transliterations, caching locally."""
    os.makedirs(CACHE_DIR, exist_ok=True)

    if os.path.exists(CACHE_FILE):
        print(f"Using cached transliteration data from {CACHE_FILE}")
        with open(CACHE_FILE, "r", encoding="utf-8") as f:
            return json.load(f)

    print("Fetching transliteration data from Quran.com API...")
    all_transliterations = {}

    for chapter in range(1, 115):
        url = f"{API_BASE}?chapter_number={chapter}"
        req = urllib.request.Request(url, headers={"User-Agent": "Safa-iOS-App/2.0"})

        try:
            with urllib.request.urlopen(req) as response:
                data = json.loads(response.read().decode("utf-8"))

            translations = data.get("translations", [])
            for ayah_index, item in enumerate(translations, start=1):
                text = strip_html(item.get("text", ""))
                if text:
                    verse_key = f"{chapter}:{ayah_index}"
                    all_transliterations[verse_key] = text

            print(f"  Chapter {chapter}: {len(translations)} verses")
        except Exception as e:
            print(f"  ERROR on chapter {chapter}: {e}")

        # Rate limit: be polite to the API
        time.sleep(0.3)

    # Cache locally
    with open(CACHE_FILE, "w", encoding="utf-8") as f:
        json.dump(all_transliterations, f, ensure_ascii=False, indent=2)
    print(f"Cached {len(all_transliterations)} transliterations to {CACHE_FILE}")

    return all_transliterations


def update_database(transliterations):
    """Update the quran.sqlite database with transliteration data."""
    db_path = os.path.normpath(DB_PATH)

    if not os.path.exists(db_path):
        print(f"ERROR: Database not found at {db_path}")
        return

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    updated = 0
    missing = 0

    for verse_key, text in transliterations.items():
        parts = verse_key.split(":")
        if len(parts) != 2:
            continue
        surah_num, ayah_num = int(parts[0]), int(parts[1])
        ayah_id = f"{surah_num}:{ayah_num}"

        cursor.execute(
            "UPDATE ayahs SET text_transliteration = ? WHERE id = ?",
            (text, ayah_id)
        )
        if cursor.rowcount > 0:
            updated += 1
        else:
            missing += 1

    conn.commit()

    # Verify
    cursor.execute("SELECT COUNT(*) FROM ayahs WHERE text_transliteration IS NOT NULL")
    total_with_translit = cursor.fetchone()[0]
    cursor.execute("SELECT COUNT(*) FROM ayahs")
    total_ayahs = cursor.fetchone()[0]

    print(f"\nUpdated quran.sqlite:")
    print(f"  - {updated} ayahs updated with transliteration")
    print(f"  - {missing} verse keys not found in DB")
    print(f"  - {total_with_translit}/{total_ayahs} ayahs now have transliteration")
    print(f"  - File size: {os.path.getsize(db_path) / 1024:.1f} KB")

    conn.close()


if __name__ == "__main__":
    transliterations = fetch_transliterations()
    update_database(transliterations)
    print("\nDone! Re-compress with: gzip -k -f Safa/Resources/Data/Database/quran.sqlite")
