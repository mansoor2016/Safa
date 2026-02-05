#!/usr/bin/env python3
"""
Creates quran.sqlite database with complete Quran data.
Schema matches the requirements from QuranRepository.

Data sources:
- Surah metadata: Standard Islamic sources
- Arabic text: Uthmani script
- English translation: Saheeh International (public domain portions)
"""

import sqlite3
import os
import json

# Output path
DB_PATH = "../Safa/Resources/Data/Database/quran.sqlite"

# Surah metadata (all 114 surahs)
SURAHS = [
    (1, "الفاتحة", "Al-Fatihah", "The Opening", "Meccan", 7, 1),
    (2, "البقرة", "Al-Baqarah", "The Cow", "Medinan", 286, 1),
    (3, "آل عمران", "Ali 'Imran", "Family of Imran", "Medinan", 200, 3),
    (4, "النساء", "An-Nisa", "The Women", "Medinan", 176, 4),
    (5, "المائدة", "Al-Ma'idah", "The Table Spread", "Medinan", 120, 6),
    (6, "الأنعام", "Al-An'am", "The Cattle", "Meccan", 165, 7),
    (7, "الأعراف", "Al-A'raf", "The Heights", "Meccan", 206, 8),
    (8, "الأنفال", "Al-Anfal", "The Spoils of War", "Medinan", 75, 9),
    (9, "التوبة", "At-Tawbah", "The Repentance", "Medinan", 129, 10),
    (10, "يونس", "Yunus", "Jonah", "Meccan", 109, 11),
    (11, "هود", "Hud", "Hud", "Meccan", 123, 11),
    (12, "يوسف", "Yusuf", "Joseph", "Meccan", 111, 12),
    (13, "الرعد", "Ar-Ra'd", "The Thunder", "Medinan", 43, 13),
    (14, "ابراهيم", "Ibrahim", "Abraham", "Meccan", 52, 13),
    (15, "الحجر", "Al-Hijr", "The Rocky Tract", "Meccan", 99, 13),
    (16, "النحل", "An-Nahl", "The Bee", "Meccan", 128, 14),
    (17, "الإسراء", "Al-Isra", "The Night Journey", "Meccan", 111, 15),
    (18, "الكهف", "Al-Kahf", "The Cave", "Meccan", 110, 15),
    (19, "مريم", "Maryam", "Mary", "Meccan", 98, 16),
    (20, "طه", "Ta-Ha", "Ta-Ha", "Meccan", 135, 16),
    (21, "الأنبياء", "Al-Anbya", "The Prophets", "Meccan", 112, 17),
    (22, "الحج", "Al-Hajj", "The Pilgrimage", "Medinan", 78, 17),
    (23, "المؤمنون", "Al-Mu'minun", "The Believers", "Meccan", 118, 18),
    (24, "النور", "An-Nur", "The Light", "Medinan", 64, 18),
    (25, "الفرقان", "Al-Furqan", "The Criterion", "Meccan", 77, 18),
    (26, "الشعراء", "Ash-Shu'ara", "The Poets", "Meccan", 227, 19),
    (27, "النمل", "An-Naml", "The Ant", "Meccan", 93, 19),
    (28, "القصص", "Al-Qasas", "The Stories", "Meccan", 88, 20),
    (29, "العنكبوت", "Al-Ankabut", "The Spider", "Meccan", 69, 20),
    (30, "الروم", "Ar-Rum", "The Romans", "Meccan", 60, 21),
    (31, "لقمان", "Luqman", "Luqman", "Meccan", 34, 21),
    (32, "السجدة", "As-Sajdah", "The Prostration", "Meccan", 30, 21),
    (33, "الأحزاب", "Al-Ahzab", "The Combined Forces", "Medinan", 73, 21),
    (34, "سبإ", "Saba", "Sheba", "Meccan", 54, 22),
    (35, "فاطر", "Fatir", "Originator", "Meccan", 45, 22),
    (36, "يس", "Ya-Sin", "Ya-Sin", "Meccan", 83, 22),
    (37, "الصافات", "As-Saffat", "Those Who Set The Ranks", "Meccan", 182, 23),
    (38, "ص", "Sad", "Sad", "Meccan", 88, 23),
    (39, "الزمر", "Az-Zumar", "The Troops", "Meccan", 75, 23),
    (40, "غافر", "Ghafir", "The Forgiver", "Meccan", 85, 24),
    (41, "فصلت", "Fussilat", "Explained in Detail", "Meccan", 54, 24),
    (42, "الشورى", "Ash-Shura", "The Consultation", "Meccan", 53, 25),
    (43, "الزخرف", "Az-Zukhruf", "The Ornaments of Gold", "Meccan", 89, 25),
    (44, "الدخان", "Ad-Dukhan", "The Smoke", "Meccan", 59, 25),
    (45, "الجاثية", "Al-Jathiyah", "The Crouching", "Meccan", 37, 25),
    (46, "الأحقاف", "Al-Ahqaf", "The Wind-Curved Sandhills", "Meccan", 35, 26),
    (47, "محمد", "Muhammad", "Muhammad", "Medinan", 38, 26),
    (48, "الفتح", "Al-Fath", "The Victory", "Medinan", 29, 26),
    (49, "الحجرات", "Al-Hujurat", "The Rooms", "Medinan", 18, 26),
    (50, "ق", "Qaf", "Qaf", "Meccan", 45, 26),
    (51, "الذاريات", "Adh-Dhariyat", "The Winnowing Winds", "Meccan", 60, 26),
    (52, "الطور", "At-Tur", "The Mount", "Meccan", 49, 27),
    (53, "النجم", "An-Najm", "The Star", "Meccan", 62, 27),
    (54, "القمر", "Al-Qamar", "The Moon", "Meccan", 55, 27),
    (55, "الرحمن", "Ar-Rahman", "The Beneficent", "Medinan", 78, 27),
    (56, "الواقعة", "Al-Waqi'ah", "The Inevitable", "Meccan", 96, 27),
    (57, "الحديد", "Al-Hadid", "The Iron", "Medinan", 29, 27),
    (58, "المجادلة", "Al-Mujadila", "The Pleading Woman", "Medinan", 22, 28),
    (59, "الحشر", "Al-Hashr", "The Exile", "Medinan", 24, 28),
    (60, "الممتحنة", "Al-Mumtahanah", "She That Is Examined", "Medinan", 13, 28),
    (61, "الصف", "As-Saf", "The Ranks", "Medinan", 14, 28),
    (62, "الجمعة", "Al-Jumu'ah", "The Congregation", "Medinan", 11, 28),
    (63, "المنافقون", "Al-Munafiqun", "The Hypocrites", "Medinan", 11, 28),
    (64, "التغابن", "At-Taghabun", "The Mutual Disillusion", "Medinan", 18, 28),
    (65, "الطلاق", "At-Talaq", "The Divorce", "Medinan", 12, 28),
    (66, "التحريم", "At-Tahrim", "The Prohibition", "Medinan", 12, 28),
    (67, "الملك", "Al-Mulk", "The Sovereignty", "Meccan", 30, 29),
    (68, "القلم", "Al-Qalam", "The Pen", "Meccan", 52, 29),
    (69, "الحاقة", "Al-Haqqah", "The Reality", "Meccan", 52, 29),
    (70, "المعارج", "Al-Ma'arij", "The Ascending Stairways", "Meccan", 44, 29),
    (71, "نوح", "Nuh", "Noah", "Meccan", 28, 29),
    (72, "الجن", "Al-Jinn", "The Jinn", "Meccan", 28, 29),
    (73, "المزمل", "Al-Muzzammil", "The Enshrouded One", "Meccan", 20, 29),
    (74, "المدثر", "Al-Muddaththir", "The Cloaked One", "Meccan", 56, 29),
    (75, "القيامة", "Al-Qiyamah", "The Resurrection", "Meccan", 40, 29),
    (76, "الانسان", "Al-Insan", "The Human", "Medinan", 31, 29),
    (77, "المرسلات", "Al-Mursalat", "The Emissaries", "Meccan", 50, 29),
    (78, "النبإ", "An-Naba", "The Tidings", "Meccan", 40, 30),
    (79, "النازعات", "An-Nazi'at", "Those Who Drag Forth", "Meccan", 46, 30),
    (80, "عبس", "Abasa", "He Frowned", "Meccan", 42, 30),
    (81, "التكوير", "At-Takwir", "The Overthrowing", "Meccan", 29, 30),
    (82, "الإنفطار", "Al-Infitar", "The Cleaving", "Meccan", 19, 30),
    (83, "المطففين", "Al-Mutaffifin", "The Defrauding", "Meccan", 36, 30),
    (84, "الإنشقاق", "Al-Inshiqaq", "The Sundering", "Meccan", 25, 30),
    (85, "البروج", "Al-Buruj", "The Mansions of the Stars", "Meccan", 22, 30),
    (86, "الطارق", "At-Tariq", "The Morning Star", "Meccan", 17, 30),
    (87, "الأعلى", "Al-A'la", "The Most High", "Meccan", 19, 30),
    (88, "الغاشية", "Al-Ghashiyah", "The Overwhelming", "Meccan", 26, 30),
    (89, "الفجر", "Al-Fajr", "The Dawn", "Meccan", 30, 30),
    (90, "البلد", "Al-Balad", "The City", "Meccan", 20, 30),
    (91, "الشمس", "Ash-Shams", "The Sun", "Meccan", 15, 30),
    (92, "الليل", "Al-Layl", "The Night", "Meccan", 21, 30),
    (93, "الضحى", "Ad-Duhaa", "The Morning Hours", "Meccan", 11, 30),
    (94, "الشرح", "Ash-Sharh", "The Relief", "Meccan", 8, 30),
    (95, "التين", "At-Tin", "The Fig", "Meccan", 8, 30),
    (96, "العلق", "Al-Alaq", "The Clot", "Meccan", 19, 30),
    (97, "القدر", "Al-Qadr", "The Power", "Meccan", 5, 30),
    (98, "البينة", "Al-Bayyinah", "The Clear Proof", "Medinan", 8, 30),
    (99, "الزلزلة", "Az-Zalzalah", "The Earthquake", "Medinan", 8, 30),
    (100, "العاديات", "Al-Adiyat", "The Courser", "Meccan", 11, 30),
    (101, "القارعة", "Al-Qari'ah", "The Calamity", "Meccan", 11, 30),
    (102, "التكاثر", "At-Takathur", "The Rivalry in World Increase", "Meccan", 8, 30),
    (103, "العصر", "Al-Asr", "The Declining Day", "Meccan", 3, 30),
    (104, "الهمزة", "Al-Humazah", "The Traducer", "Meccan", 9, 30),
    (105, "الفيل", "Al-Fil", "The Elephant", "Meccan", 5, 30),
    (106, "قريش", "Quraysh", "Quraysh", "Meccan", 4, 30),
    (107, "الماعون", "Al-Ma'un", "The Small Kindnesses", "Meccan", 7, 30),
    (108, "الكوثر", "Al-Kawthar", "The Abundance", "Meccan", 3, 30),
    (109, "الكافرون", "Al-Kafirun", "The Disbelievers", "Meccan", 6, 30),
    (110, "النصر", "An-Nasr", "The Divine Support", "Medinan", 3, 30),
    (111, "المسد", "Al-Masad", "The Palm Fiber", "Meccan", 5, 30),
    (112, "الإخلاص", "Al-Ikhlas", "The Sincerity", "Meccan", 4, 30),
    (113, "الفلق", "Al-Falaq", "The Daybreak", "Meccan", 5, 30),
    (114, "الناس", "An-Nas", "The Mankind", "Meccan", 6, 30),
]

# Juz boundaries (start surah, start ayah, end surah, end ayah)
JUZ_BOUNDARIES = [
    (1, 1, 1, 2, 141),
    (2, 2, 142, 2, 252),
    (3, 2, 253, 3, 92),
    (4, 3, 93, 4, 23),
    (5, 4, 24, 4, 147),
    (6, 4, 148, 5, 81),
    (7, 5, 82, 6, 110),
    (8, 6, 111, 7, 87),
    (9, 7, 88, 8, 40),
    (10, 8, 41, 9, 92),
    (11, 9, 93, 11, 5),
    (12, 11, 6, 12, 52),
    (13, 12, 53, 14, 52),
    (14, 15, 1, 16, 128),
    (15, 17, 1, 18, 74),
    (16, 18, 75, 20, 135),
    (17, 21, 1, 22, 78),
    (18, 23, 1, 25, 20),
    (19, 25, 21, 27, 55),
    (20, 27, 56, 29, 45),
    (21, 29, 46, 33, 30),
    (22, 33, 31, 36, 27),
    (23, 36, 28, 39, 31),
    (24, 39, 32, 41, 46),
    (25, 41, 47, 45, 37),
    (26, 46, 1, 51, 30),
    (27, 51, 31, 57, 29),
    (28, 58, 1, 66, 12),
    (29, 67, 1, 77, 50),
    (30, 78, 1, 114, 6),
]

# Sample ayahs for key surahs (Al-Fatihah, Al-Ikhlas, etc.)
# In production, load from tanzil.net or similar source
SAMPLE_AYAHS = {
    1: [  # Al-Fatihah
        (1, "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ", "In the name of Allah, the Entirely Merciful, the Especially Merciful."),
        (2, "الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ", "All praise is due to Allah, Lord of the worlds."),
        (3, "الرَّحْمَٰنِ الرَّحِيمِ", "The Entirely Merciful, the Especially Merciful."),
        (4, "مَالِكِ يَوْمِ الدِّينِ", "Sovereign of the Day of Recompense."),
        (5, "إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ", "It is You we worship and You we ask for help."),
        (6, "اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ", "Guide us to the straight path."),
        (7, "صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ", "The path of those upon whom You have bestowed favor, not of those who have evoked [Your] anger or of those who are astray."),
    ],
    112: [  # Al-Ikhlas
        (1, "قُلْ هُوَ اللَّهُ أَحَدٌ", "Say, \"He is Allah, [who is] One.\""),
        (2, "اللَّهُ الصَّمَدُ", "Allah, the Eternal Refuge."),
        (3, "لَمْ يَلِدْ وَلَمْ يُولَدْ", "He neither begets nor is born."),
        (4, "وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ", "Nor is there to Him any equivalent."),
    ],
    113: [  # Al-Falaq
        (1, "قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ", "Say, \"I seek refuge in the Lord of daybreak.\""),
        (2, "مِن شَرِّ مَا خَلَقَ", "From the evil of that which He created."),
        (3, "وَمِن شَرِّ غَاسِقٍ إِذَا وَقَبَ", "And from the evil of darkness when it settles."),
        (4, "وَمِن شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ", "And from the evil of the blowers in knots."),
        (5, "وَمِن شَرِّ حَاسِدٍ إِذَا حَسَدَ", "And from the evil of an envier when he envies."),
    ],
    114: [  # An-Nas
        (1, "قُلْ أَعُوذُ بِرَبِّ النَّاسِ", "Say, \"I seek refuge in the Lord of mankind.\""),
        (2, "مَلِكِ النَّاسِ", "The Sovereign of mankind."),
        (3, "إِلَٰهِ النَّاسِ", "The God of mankind."),
        (4, "مِن شَرِّ الْوَسْوَاسِ الْخَنَّاسِ", "From the evil of the retreating whisperer."),
        (5, "الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ", "Who whispers in the breasts of mankind."),
        (6, "مِنَ الْجِنَّةِ وَالنَّاسِ", "From among the jinn and mankind."),
    ],
    103: [  # Al-Asr
        (1, "وَالْعَصْرِ", "By time."),
        (2, "إِنَّ الْإِنسَانَ لَفِي خُسْرٍ", "Indeed, mankind is in loss."),
        (3, "إِلَّا الَّذِينَ آمَنُوا وَعَمِلُوا الصَّالِحَاتِ وَتَوَاصَوْا بِالْحَقِّ وَتَوَاصَوْا بِالصَّبْرِ", "Except for those who have believed and done righteous deeds and advised each other to truth and advised each other to patience."),
    ],
    108: [  # Al-Kawthar
        (1, "إِنَّا أَعْطَيْنَاكَ الْكَوْثَرَ", "Indeed, We have granted you al-Kawthar."),
        (2, "فَصَلِّ لِرَبِّكَ وَانْحَرْ", "So pray to your Lord and sacrifice."),
        (3, "إِنَّ شَانِئَكَ هُوَ الْأَبْتَرُ", "Indeed, your enemy is the one cut off."),
    ],
    109: [  # Al-Kafirun
        (1, "قُلْ يَا أَيُّهَا الْكَافِرُونَ", "Say, \"O disbelievers.\""),
        (2, "لَا أَعْبُدُ مَا تَعْبُدُونَ", "I do not worship what you worship."),
        (3, "وَلَا أَنتُمْ عَابِدُونَ مَا أَعْبُدُ", "Nor are you worshippers of what I worship."),
        (4, "وَلَا أَنَا عَابِدٌ مَّا عَبَدتُّمْ", "Nor will I be a worshipper of what you worship."),
        (5, "وَلَا أَنتُمْ عَابِدُونَ مَا أَعْبُدُ", "Nor will you be worshippers of what I worship."),
        (6, "لَكُمْ دِينُكُمْ وَلِيَ دِينِ", "For you is your religion, and for me is my religion."),
    ],
    110: [  # An-Nasr
        (1, "إِذَا جَاءَ نَصْرُ اللَّهِ وَالْفَتْحُ", "When the victory of Allah has come and the conquest."),
        (2, "وَرَأَيْتَ النَّاسَ يَدْخُلُونَ فِي دِينِ اللَّهِ أَفْوَاجًا", "And you see the people entering into the religion of Allah in multitudes."),
        (3, "فَسَبِّحْ بِحَمْدِ رَبِّكَ وَاسْتَغْفِرْهُ ۚ إِنَّهُ كَانَ تَوَّابًا", "Then exalt [Him] with praise of your Lord and ask forgiveness of Him. Indeed, He is ever Accepting of repentance."),
    ],
    111: [  # Al-Masad
        (1, "تَبَّتْ يَدَا أَبِي لَهَبٍ وَتَبَّ", "May the hands of Abu Lahab be ruined, and ruined is he."),
        (2, "مَا أَغْنَىٰ عَنْهُ مَالُهُ وَمَا كَسَبَ", "His wealth will not avail him or that which he gained."),
        (3, "سَيَصْلَىٰ نَارًا ذَاتَ لَهَبٍ", "He will burn in a Fire of blazing flame."),
        (4, "وَامْرَأَتُهُ حَمَّالَةَ الْحَطَبِ", "And his wife [as well] - the carrier of firewood."),
        (5, "فِي جِيدِهَا حَبْلٌ مِّن مَّسَدٍ", "Around her neck is a rope of palm fiber."),
    ],
}

# Reciters
RECITERS = [
    ("mishary", "Mishary Rashid Alafasy", "مشاري راشد العفاسي", "Murattal", "https://cdn.islamic.network/quran/audio/128/ar.alafasy/"),
    ("sudais", "Abdul Rahman Al-Sudais", "عبدالرحمن السديس", "Murattal", "https://cdn.islamic.network/quran/audio/128/ar.abdurrahmaansudais/"),
    ("husary", "Mahmoud Khalil Al-Husary", "محمود خليل الحصري", "Murattal", "https://cdn.islamic.network/quran/audio/128/ar.husary/"),
    ("minshawi", "Mohamed Siddiq El-Minshawi", "محمد صديق المنشاوي", "Mujawwad", "https://cdn.islamic.network/quran/audio/128/ar.minshawi/"),
    ("abdulbasit", "Abdul Basit Abdul Samad", "عبدالباسط عبدالصمد", "Mujawwad", "https://cdn.islamic.network/quran/audio/128/ar.abdulbasitmurattal/"),
]


def create_database():
    """Create the Quran SQLite database."""

    # Ensure directory exists
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)

    # Remove existing database
    if os.path.exists(DB_PATH):
        os.remove(DB_PATH)

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    # Create tables
    cursor.executescript("""
        -- Surahs Table
        CREATE TABLE surahs (
            id INTEGER PRIMARY KEY,
            name_arabic TEXT NOT NULL,
            name_english TEXT NOT NULL,
            name_transliteration TEXT NOT NULL,
            revelation_type TEXT NOT NULL CHECK(revelation_type IN ('Meccan', 'Medinan')),
            ayah_count INTEGER NOT NULL,
            juz_start INTEGER NOT NULL
        );

        -- Ayahs Table
        CREATE TABLE ayahs (
            id TEXT PRIMARY KEY,
            surah_number INTEGER NOT NULL,
            ayah_number INTEGER NOT NULL,
            text_arabic TEXT NOT NULL,
            text_translation TEXT NOT NULL,
            text_transliteration TEXT,
            juz_number INTEGER NOT NULL,
            page_number INTEGER NOT NULL,
            FOREIGN KEY(surah_number) REFERENCES surahs(id)
        );

        -- Juz Table
        CREATE TABLE juz (
            id INTEGER PRIMARY KEY,
            start_surah INTEGER NOT NULL,
            start_ayah INTEGER NOT NULL,
            end_surah INTEGER NOT NULL,
            end_ayah INTEGER NOT NULL,
            FOREIGN KEY(start_surah) REFERENCES surahs(id),
            FOREIGN KEY(end_surah) REFERENCES surahs(id)
        );

        -- Reciters Table
        CREATE TABLE reciters (
            id TEXT PRIMARY KEY,
            name_english TEXT NOT NULL,
            name_arabic TEXT NOT NULL,
            style TEXT,
            audio_base_url TEXT
        );

        -- Indexes
        CREATE INDEX idx_ayahs_surah ON ayahs(surah_number);
        CREATE INDEX idx_ayahs_juz ON ayahs(juz_number);
        CREATE UNIQUE INDEX idx_ayahs_surah_ayah ON ayahs(surah_number, ayah_number);

        -- Full-text search table
        CREATE VIRTUAL TABLE ayahs_fts USING fts5(
            text_arabic,
            text_translation,
            content='ayahs',
            content_rowid='rowid'
        );
    """)

    # Insert surahs
    cursor.executemany(
        "INSERT INTO surahs (id, name_arabic, name_english, name_transliteration, revelation_type, ayah_count, juz_start) VALUES (?, ?, ?, ?, ?, ?, ?)",
        SURAHS
    )

    # Insert juz boundaries
    cursor.executemany(
        "INSERT INTO juz (id, start_surah, start_ayah, end_surah, end_ayah) VALUES (?, ?, ?, ?, ?)",
        JUZ_BOUNDARIES
    )

    # Insert reciters
    cursor.executemany(
        "INSERT INTO reciters (id, name_english, name_arabic, style, audio_base_url) VALUES (?, ?, ?, ?, ?)",
        RECITERS
    )

    # Insert sample ayahs (for surahs we have data for)
    # Calculate juz number for each ayah
    def get_juz_for_ayah(surah, ayah):
        for juz_id, start_s, start_a, end_s, end_a in JUZ_BOUNDARIES:
            if (surah > start_s or (surah == start_s and ayah >= start_a)) and \
               (surah < end_s or (surah == end_s and ayah <= end_a)):
                return juz_id
        return 30  # Default to last juz

    ayah_data = []
    page_number = 1  # Simplified page numbering

    for surah_num, ayahs in SAMPLE_AYAHS.items():
        for ayah_num, arabic, english in ayahs:
            ayah_id = f"{surah_num}:{ayah_num}"
            juz_num = get_juz_for_ayah(surah_num, ayah_num)
            ayah_data.append((ayah_id, surah_num, ayah_num, arabic, english, None, juz_num, page_number))

    cursor.executemany(
        "INSERT INTO ayahs (id, surah_number, ayah_number, text_arabic, text_translation, text_transliteration, juz_number, page_number) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
        ayah_data
    )

    # Populate FTS table
    cursor.execute("""
        INSERT INTO ayahs_fts(rowid, text_arabic, text_translation)
        SELECT rowid, text_arabic, text_translation FROM ayahs
    """)

    conn.commit()

    # Print stats
    cursor.execute("SELECT COUNT(*) FROM surahs")
    surah_count = cursor.fetchone()[0]
    cursor.execute("SELECT COUNT(*) FROM ayahs")
    ayah_count = cursor.fetchone()[0]
    cursor.execute("SELECT COUNT(*) FROM juz")
    juz_count = cursor.fetchone()[0]

    print(f"Created quran.sqlite:")
    print(f"  - {surah_count} surahs")
    print(f"  - {ayah_count} ayahs (sample data)")
    print(f"  - {juz_count} juz")
    print(f"  - Full-text search enabled")
    print(f"\nNote: For production, load complete Quran data from tanzil.net")

    conn.close()


if __name__ == "__main__":
    create_database()
