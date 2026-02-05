#!/usr/bin/env python3
"""
Creates hadith.sqlite database with major Hadith collections.
Schema matches the requirements from HadithRepository.

Collections included:
- Sahih Bukhari
- Sahih Muslim
- Sunan Abu Dawood
- Jami at-Tirmidhi
- Sunan an-Nasa'i
- Sunan Ibn Majah
"""

import sqlite3
import os

# Output path
DB_PATH = "../Safa/Resources/Data/Database/hadith.sqlite"

# Hadith collections metadata
COLLECTIONS = [
    ("bukhari", "Sahih al-Bukhari", "صحيح البخاري", "Imam Muhammad al-Bukhari", 7563, 97),
    ("muslim", "Sahih Muslim", "صحيح مسلم", "Imam Muslim ibn al-Hajjaj", 7500, 56),
    ("abudawud", "Sunan Abu Dawood", "سنن أبي داود", "Imam Abu Dawood", 5274, 43),
    ("tirmidhi", "Jami at-Tirmidhi", "جامع الترمذي", "Imam at-Tirmidhi", 3956, 49),
    ("nasai", "Sunan an-Nasa'i", "سنن النسائي", "Imam an-Nasa'i", 5761, 51),
    ("ibnmajah", "Sunan Ibn Majah", "سنن ابن ماجه", "Imam Ibn Majah", 4341, 37),
]

# Sample books for each collection
SAMPLE_BOOKS = {
    "bukhari": [
        ("bukhari_1", 1, "Revelation", "بدء الوحي", 7),
        ("bukhari_2", 2, "Belief", "الإيمان", 51),
        ("bukhari_3", 3, "Knowledge", "العلم", 76),
        ("bukhari_4", 4, "Ablutions (Wudu')", "الوضوء", 113),
        ("bukhari_5", 5, "Bathing (Ghusl)", "الغسل", 46),
    ],
    "muslim": [
        ("muslim_1", 1, "Faith", "الإيمان", 95),
        ("muslim_2", 2, "Purification", "الطهارة", 122),
        ("muslim_3", 3, "Menstruation", "الحيض", 32),
        ("muslim_4", 4, "Prayer", "الصلاة", 215),
        ("muslim_5", 5, "Mosques", "المساجد", 89),
    ],
    "abudawud": [
        ("abudawud_1", 1, "Purification", "الطهارة", 144),
        ("abudawud_2", 2, "Prayer", "الصلاة", 365),
        ("abudawud_3", 3, "Zakat", "الزكاة", 46),
        ("abudawud_4", 4, "Fasting", "الصوم", 81),
        ("abudawud_5", 5, "Pilgrimage", "المناسك", 96),
    ],
    "tirmidhi": [
        ("tirmidhi_1", 1, "Purification", "الطهارة", 111),
        ("tirmidhi_2", 2, "Prayer", "الصلاة", 412),
        ("tirmidhi_3", 3, "Friday Prayer", "الجمعة", 80),
        ("tirmidhi_4", 4, "Zakat", "الزكاة", 38),
        ("tirmidhi_5", 5, "Fasting", "الصوم", 82),
    ],
    "nasai": [
        ("nasai_1", 1, "Purification", "الطهارة", 189),
        ("nasai_2", 2, "Water", "المياه", 14),
        ("nasai_3", 3, "Menstruation", "الحيض", 21),
        ("nasai_4", 4, "Ghusl and Tayammum", "الغسل والتيمم", 34),
        ("nasai_5", 5, "Prayer", "الصلاة", 22),
    ],
    "ibnmajah": [
        ("ibnmajah_1", 1, "Purification", "الطهارة", 139),
        ("ibnmajah_2", 2, "Prayer", "الصلاة", 215),
        ("ibnmajah_3", 3, "Call to Prayer", "الأذان", 12),
        ("ibnmajah_4", 4, "Mosques", "المساجد", 19),
        ("ibnmajah_5", 5, "Establishing Prayer", "إقامة الصلاة", 205),
    ],
}

# Sample hadiths (famous/important ones)
SAMPLE_HADITHS = [
    # Bukhari
    (
        "bukhari_1_1",
        "bukhari",
        "bukhari_1",
        1,
        "إِنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ، وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى، فَمَنْ كَانَتْ هِجْرَتُهُ إِلَى دُنْيَا يُصِيبُهَا أَوْ إِلَى امْرَأَةٍ يَنْكِحُهَا فَهِجْرَتُهُ إِلَى مَا هَاجَرَ إِلَيْهِ",
        "Actions are judged by intentions, so each man will have what he intended. Thus, he whose migration was to Allah and His Messenger, his migration is to Allah and His Messenger; but he whose migration was for some worldly thing he might gain, or for a wife he might marry, his migration is to that for which he migrated.",
        "Narrated by Umar bin Al-Khattab",
        "Umar bin Al-Khattab",
        "Sahih",
        "Bukhari 1"
    ),
    (
        "bukhari_1_2",
        "bukhari",
        "bukhari_1",
        2,
        "أَخْبَرَنَا الْحُمَيْدِيُّ عَبْدُ اللَّهِ بْنُ الزُّبَيْرِ...",
        "The Prophet (ﷺ) said: 'Gabriel came to me and said, \"O Muhammad! Live as you wish, for you shall eventually die. Love whom you wish, for you shall eventually depart. Do what you wish, for you shall pay for it. And know that the believer's honor is in praying at night and his dignity is in being independent of people.\"'",
        "Narrated by Abu Hurairah",
        "Abu Hurairah",
        "Sahih",
        "Bukhari 2"
    ),
    (
        "bukhari_2_8",
        "bukhari",
        "bukhari_2",
        8,
        "بُنِيَ الْإِسْلَامُ عَلَى خَمْسٍ: شَهَادَةِ أَنْ لَا إِلَهَ إِلَّا اللَّهُ وَأَنَّ مُحَمَّدًا رَسُولُ اللَّهِ، وَإِقَامِ الصَّلَاةِ، وَإِيتَاءِ الزَّكَاةِ، وَالْحَجِّ، وَصَوْمِ رَمَضَانَ",
        "Islam is built upon five pillars: testifying that there is no god but Allah and that Muhammad is the Messenger of Allah, establishing the prayer, paying the zakat, making the pilgrimage to the House, and fasting in Ramadan.",
        "Narrated by Ibn Umar",
        "Ibn Umar",
        "Sahih",
        "Bukhari 8"
    ),
    # Muslim
    (
        "muslim_1_1",
        "muslim",
        "muslim_1",
        1,
        "الْإِيمَانُ أَنْ تُؤْمِنَ بِاللَّهِ وَمَلَائِكَتِهِ وَكُتُبِهِ وَرُسُلِهِ وَالْيَوْمِ الْآخِرِ وَتُؤْمِنَ بِالْقَدَرِ خَيْرِهِ وَشَرِّهِ",
        "Faith is to believe in Allah, His angels, His books, His messengers, the Last Day, and to believe in divine destiny, both the good and the evil thereof.",
        "Narrated by Umar bin Al-Khattab",
        "Umar bin Al-Khattab",
        "Sahih",
        "Muslim 1"
    ),
    (
        "muslim_1_8",
        "muslim",
        "muslim_1",
        8,
        "لَا يُؤْمِنُ أَحَدُكُمْ حَتَّى يُحِبَّ لِأَخِيهِ مَا يُحِبُّ لِنَفْسِهِ",
        "None of you truly believes until he loves for his brother what he loves for himself.",
        "Narrated by Anas bin Malik",
        "Anas bin Malik",
        "Sahih",
        "Muslim 45"
    ),
    # Abu Dawood
    (
        "abudawud_1_61",
        "abudawud",
        "abudawud_1",
        61,
        "الطُّهُورُ شَطْرُ الْإِيمَانِ",
        "Purity is half of faith.",
        "Narrated by Abu Malik al-Ash'ari",
        "Abu Malik al-Ash'ari",
        "Sahih",
        "Abu Dawood 61"
    ),
    # Tirmidhi
    (
        "tirmidhi_1_1",
        "tirmidhi",
        "tirmidhi_1",
        1,
        "مِفْتَاحُ الصَّلَاةِ الطُّهُورُ، وَتَحْرِيمُهَا التَّكْبِيرُ، وَتَحْلِيلُهَا التَّسْلِيمُ",
        "The key to prayer is purification, its beginning is takbir, and its ending is taslim.",
        "Narrated by Ali ibn Abi Talib",
        "Ali ibn Abi Talib",
        "Hasan",
        "Tirmidhi 3"
    ),
    (
        "tirmidhi_3_2682",
        "tirmidhi",
        "tirmidhi_3",
        2682,
        "خَيْرُكُمْ مَنْ تَعَلَّمَ الْقُرْآنَ وَعَلَّمَهُ",
        "The best of you are those who learn the Quran and teach it.",
        "Narrated by Uthman bin Affan",
        "Uthman bin Affan",
        "Sahih",
        "Tirmidhi 2907"
    ),
    # Nasai
    (
        "nasai_1_1",
        "nasai",
        "nasai_1",
        1,
        "إِذَا قَامَ أَحَدُكُمْ إِلَى الصَّلَاةِ فَلْيَتَوَضَّأْ",
        "When any one of you stands for prayer, let him perform wudu.",
        "Narrated by Abu Hurairah",
        "Abu Hurairah",
        "Sahih",
        "Nasai 1"
    ),
    # Ibn Majah
    (
        "ibnmajah_1_224",
        "ibnmajah",
        "ibnmajah_1",
        224,
        "طَلَبُ الْعِلْمِ فَرِيضَةٌ عَلَى كُلِّ مُسْلِمٍ",
        "Seeking knowledge is an obligation upon every Muslim.",
        "Narrated by Anas bin Malik",
        "Anas bin Malik",
        "Hasan",
        "Ibn Majah 224"
    ),
    (
        "ibnmajah_1_4032",
        "ibnmajah",
        "ibnmajah_5",
        4032,
        "الدُّعَاءُ مُخُّ الْعِبَادَةِ",
        "Supplication is the essence of worship.",
        "Narrated by Anas bin Malik",
        "Anas bin Malik",
        "Hasan",
        "Ibn Majah 3828"
    ),
]

# Hadith topics for categorization
TOPICS = [
    "Faith",
    "Prayer",
    "Purification",
    "Fasting",
    "Zakat",
    "Hajj",
    "Quran",
    "Knowledge",
    "Manners",
    "Family",
    "Business",
    "Jihad",
    "Afterlife",
    "Prophets",
    "Companions",
]


def create_database():
    """Create the Hadith SQLite database."""

    # Ensure directory exists
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)

    # Remove existing database
    if os.path.exists(DB_PATH):
        os.remove(DB_PATH)

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    # Create tables
    cursor.executescript("""
        -- Hadith Collections Table
        CREATE TABLE hadith_collections (
            id TEXT PRIMARY KEY,
            name_english TEXT NOT NULL,
            name_arabic TEXT NOT NULL,
            compiler_name TEXT NOT NULL,
            total_hadiths INTEGER NOT NULL,
            total_books INTEGER NOT NULL
        );

        -- Hadith Books Table
        CREATE TABLE hadith_books (
            id TEXT PRIMARY KEY,
            collection_id TEXT NOT NULL,
            book_number INTEGER NOT NULL,
            name_english TEXT NOT NULL,
            name_arabic TEXT NOT NULL,
            hadith_count INTEGER NOT NULL,
            FOREIGN KEY(collection_id) REFERENCES hadith_collections(id)
        );

        -- Hadiths Table
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

        -- Hadith Topics Table
        CREATE TABLE hadith_topics (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            topic TEXT NOT NULL UNIQUE
        );

        -- Hadith-Topic Junction Table
        CREATE TABLE hadith_topics_junction (
            hadith_id TEXT NOT NULL,
            topic_id INTEGER NOT NULL,
            PRIMARY KEY(hadith_id, topic_id),
            FOREIGN KEY(hadith_id) REFERENCES hadiths(id),
            FOREIGN KEY(topic_id) REFERENCES hadith_topics(id)
        );

        -- Indexes
        CREATE INDEX idx_hadiths_collection ON hadiths(collection_id);
        CREATE INDEX idx_hadiths_book ON hadiths(book_id);
        CREATE INDEX idx_hadiths_grading ON hadiths(grading);
        CREATE INDEX idx_books_collection ON hadith_books(collection_id);

        -- Full-text search table
        CREATE VIRTUAL TABLE hadiths_fts USING fts5(
            text_arabic,
            text_english,
            narrator,
            content='hadiths',
            content_rowid='rowid'
        );
    """)

    # Insert collections
    cursor.executemany(
        "INSERT INTO hadith_collections (id, name_english, name_arabic, compiler_name, total_hadiths, total_books) VALUES (?, ?, ?, ?, ?, ?)",
        COLLECTIONS
    )

    # Insert books
    for collection_id, books in SAMPLE_BOOKS.items():
        for book_id, book_num, name_en, name_ar, hadith_count in books:
            cursor.execute(
                "INSERT INTO hadith_books (id, collection_id, book_number, name_english, name_arabic, hadith_count) VALUES (?, ?, ?, ?, ?, ?)",
                (book_id, collection_id, book_num, name_en, name_ar, hadith_count)
            )

    # Insert hadiths
    cursor.executemany(
        """INSERT INTO hadiths (id, collection_id, book_id, hadith_number, text_arabic, text_english, narrator_chain, narrator, grading, reference)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
        SAMPLE_HADITHS
    )

    # Insert topics
    cursor.executemany(
        "INSERT INTO hadith_topics (topic) VALUES (?)",
        [(t,) for t in TOPICS]
    )

    # Populate FTS table
    cursor.execute("""
        INSERT INTO hadiths_fts(rowid, text_arabic, text_english, narrator)
        SELECT rowid, text_arabic, text_english, narrator FROM hadiths
    """)

    conn.commit()

    # Print stats
    cursor.execute("SELECT COUNT(*) FROM hadith_collections")
    collection_count = cursor.fetchone()[0]
    cursor.execute("SELECT COUNT(*) FROM hadith_books")
    book_count = cursor.fetchone()[0]
    cursor.execute("SELECT COUNT(*) FROM hadiths")
    hadith_count = cursor.fetchone()[0]

    print(f"Created hadith.sqlite:")
    print(f"  - {collection_count} collections")
    print(f"  - {book_count} books (sample)")
    print(f"  - {hadith_count} hadiths (sample)")
    print(f"  - {len(TOPICS)} topics")
    print(f"  - Full-text search enabled")
    print(f"\nNote: For production, load complete hadith data from sunnah.com API")

    conn.close()


if __name__ == "__main__":
    create_database()
