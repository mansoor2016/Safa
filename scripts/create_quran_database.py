#!/usr/bin/env python3
"""
Creates quran.sqlite database with complete Quran data (6,236 ayahs).

Data sources:
- Arabic text: Uthmani script (via quran-json, sourced from tanzil.net)
- English translation: Sahih International (via quran-json, sourced from tanzil.net)
- Surah metadata: Standard Islamic sources
- Page numbers: Madinah Mushaf standard

Attribution: Quran text from Tanzil.net (CC BY 3.0)
"""

import sqlite3
import os
import json
import urllib.request

# Output path (relative to scripts/ directory)
DB_PATH = os.path.join(os.path.dirname(__file__), "..", "Safa", "Resources", "Data", "Database", "quran.sqlite")

# Cache directory for downloaded data
CACHE_DIR = os.path.join(os.path.dirname(__file__), "data")

# Data source URL (quran-json project, sourced from tanzil.net)
QURAN_JSON_URL = "https://raw.githubusercontent.com/risan/quran-json/main/dist/quran_en.json"

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

# Juz boundaries (juz_id, start_surah, start_ayah, end_surah, end_ayah)
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

# Madinah Mushaf page boundaries: (surah, ayah) -> page number
# Standard 604-page layout. Each entry is (surah, first_ayah_on_page).
# Generated from the standard Madinah Mushaf page mapping.
# Page 1 = Al-Fatihah, Page 2 = Al-Baqarah:1, etc.
PAGE_BOUNDARIES = [
    (1, 1, 1), (2, 1, 2), (2, 6, 3), (2, 17, 4), (2, 25, 5),
    (2, 30, 6), (2, 36, 7), (2, 42, 8), (2, 49, 9), (2, 58, 10),
    (2, 62, 11), (2, 70, 12), (2, 77, 13), (2, 84, 14), (2, 89, 15),
    (2, 94, 16), (2, 102, 17), (2, 106, 18), (2, 113, 19), (2, 120, 20),
    (2, 127, 21), (2, 135, 22), (2, 142, 23), (2, 146, 24), (2, 154, 25),
    (2, 164, 26), (2, 170, 27), (2, 177, 28), (2, 182, 29), (2, 187, 30),
    (2, 191, 31), (2, 197, 32), (2, 203, 33), (2, 211, 34), (2, 216, 35),
    (2, 220, 36), (2, 225, 37), (2, 231, 38), (2, 234, 39), (2, 238, 40),
    (2, 246, 41), (2, 249, 42), (2, 253, 43), (2, 256, 44), (2, 260, 45),
    (2, 265, 46), (2, 270, 47), (2, 275, 48), (2, 282, 49), (2, 283, 50),
    (3, 1, 51), (3, 10, 52), (3, 16, 53), (3, 23, 54), (3, 30, 55),
    (3, 38, 56), (3, 46, 57), (3, 53, 58), (3, 62, 59), (3, 71, 60),
    (3, 78, 61), (3, 84, 62), (3, 92, 63), (3, 101, 64), (3, 109, 65),
    (3, 116, 66), (3, 122, 67), (3, 133, 68), (3, 141, 69), (3, 149, 70),
    (3, 154, 71), (3, 158, 72), (3, 166, 73), (3, 174, 74), (3, 181, 75),
    (3, 187, 76), (3, 195, 77), (4, 1, 78), (4, 7, 79), (4, 12, 80),
    (4, 15, 81), (4, 20, 82), (4, 24, 83), (4, 27, 84), (4, 34, 85),
    (4, 38, 86), (4, 45, 87), (4, 52, 88), (4, 60, 89), (4, 66, 90),
    (4, 75, 91), (4, 80, 92), (4, 87, 93), (4, 92, 94), (4, 95, 95),
    (4, 102, 96), (4, 106, 97), (4, 114, 98), (4, 122, 99), (4, 128, 100),
    (4, 135, 101), (4, 141, 102), (4, 148, 103), (4, 155, 104), (4, 163, 105),
    (4, 171, 106), (4, 176, 107), (5, 1, 108), (5, 3, 109), (5, 6, 110),
    (5, 10, 111), (5, 14, 112), (5, 18, 113), (5, 24, 114), (5, 32, 115),
    (5, 37, 116), (5, 42, 117), (5, 46, 118), (5, 51, 119), (5, 58, 120),
    (5, 65, 121), (5, 71, 122), (5, 77, 123), (5, 82, 124), (5, 90, 125),
    (5, 96, 126), (5, 104, 127), (5, 109, 128), (5, 114, 129), (6, 1, 130),
    (6, 9, 131), (6, 19, 132), (6, 28, 133), (6, 36, 134), (6, 45, 135),
    (6, 53, 136), (6, 60, 137), (6, 69, 138), (6, 74, 139), (6, 82, 140),
    (6, 91, 141), (6, 95, 142), (6, 101, 143), (6, 111, 144), (6, 119, 145),
    (6, 125, 146), (6, 130, 147), (6, 138, 148), (6, 143, 149), (6, 147, 150),
    (6, 152, 151), (6, 158, 152), (6, 163, 153), (7, 1, 154), (7, 12, 155),
    (7, 23, 156), (7, 31, 157), (7, 38, 158), (7, 44, 159), (7, 52, 160),
    (7, 58, 161), (7, 68, 162), (7, 74, 163), (7, 82, 164), (7, 88, 165),
    (7, 96, 166), (7, 105, 167), (7, 121, 168), (7, 131, 169), (7, 138, 170),
    (7, 144, 171), (7, 150, 172), (7, 156, 173), (7, 160, 174), (7, 170, 175),
    (7, 179, 176), (7, 189, 177), (7, 196, 178), (7, 206, 179), (8, 1, 180),
    (8, 9, 181), (8, 17, 182), (8, 26, 183), (8, 34, 184), (8, 41, 185),
    (8, 46, 186), (8, 53, 187), (8, 62, 188), (8, 70, 189), (9, 1, 190),
    (9, 7, 191), (9, 14, 192), (9, 21, 193), (9, 27, 194), (9, 32, 195),
    (9, 37, 196), (9, 41, 197), (9, 48, 198), (9, 55, 199), (9, 62, 200),
    (9, 69, 201), (9, 73, 202), (9, 80, 203), (9, 87, 204), (9, 94, 205),
    (9, 100, 206), (9, 107, 207), (9, 112, 208), (9, 118, 209), (9, 123, 210),
    (10, 1, 211), (10, 7, 212), (10, 15, 213), (10, 21, 214), (10, 26, 215),
    (10, 34, 216), (10, 43, 217), (10, 54, 218), (10, 62, 219), (10, 71, 220),
    (10, 79, 221), (10, 89, 222), (10, 98, 223), (10, 107, 224), (11, 1, 225),
    (11, 6, 226), (11, 13, 227), (11, 20, 228), (11, 29, 229), (11, 38, 230),
    (11, 46, 231), (11, 54, 232), (11, 64, 233), (11, 72, 234), (11, 82, 235),
    (11, 89, 236), (11, 98, 237), (11, 109, 238), (11, 118, 239), (12, 1, 240),
    (12, 7, 241), (12, 15, 242), (12, 23, 243), (12, 31, 244), (12, 38, 245),
    (12, 44, 246), (12, 53, 247), (12, 64, 248), (12, 70, 249), (12, 79, 250),
    (12, 87, 251), (12, 96, 252), (12, 104, 253), (13, 1, 254), (13, 6, 255),
    (13, 14, 256), (13, 19, 257), (13, 29, 258), (13, 35, 259), (13, 43, 260),
    (14, 6, 261), (14, 11, 262), (14, 19, 263), (14, 25, 264), (14, 34, 265),
    (14, 43, 266), (15, 1, 267), (15, 16, 268), (15, 32, 269), (15, 52, 270),
    (15, 71, 271), (15, 91, 272), (16, 1, 273), (16, 7, 274), (16, 15, 275),
    (16, 27, 276), (16, 35, 277), (16, 43, 278), (16, 51, 279), (16, 60, 280),
    (16, 66, 281), (16, 73, 282), (16, 80, 283), (16, 85, 284), (16, 90, 285),
    (16, 96, 286), (16, 103, 287), (16, 111, 288), (16, 119, 289), (16, 126, 290),
    (17, 1, 291), (17, 8, 292), (17, 18, 293), (17, 28, 294), (17, 39, 295),
    (17, 49, 296), (17, 59, 297), (17, 67, 298), (17, 76, 299), (17, 87, 300),
    (17, 97, 301), (17, 105, 302), (18, 1, 303), (18, 5, 304), (18, 16, 305),
    (18, 21, 306), (18, 28, 307), (18, 35, 308), (18, 46, 309), (18, 54, 310),
    (18, 62, 311), (18, 75, 312), (18, 84, 313), (18, 98, 314), (19, 1, 315),
    (19, 12, 316), (19, 26, 317), (19, 39, 318), (19, 52, 319), (19, 65, 320),
    (19, 77, 321), (19, 96, 322), (20, 13, 323), (20, 38, 324), (20, 52, 325),
    (20, 65, 326), (20, 77, 327), (20, 88, 328), (20, 99, 329), (20, 114, 330),
    (20, 126, 331), (21, 1, 332), (21, 11, 333), (21, 25, 334), (21, 36, 335),
    (21, 45, 336), (21, 58, 337), (21, 73, 338), (21, 82, 339), (21, 91, 340),
    (21, 102, 341), (22, 1, 342), (22, 6, 343), (22, 15, 344), (22, 23, 345),
    (22, 31, 346), (22, 39, 347), (22, 47, 348), (22, 56, 349), (22, 65, 350),
    (22, 73, 351), (23, 1, 352), (23, 18, 353), (23, 27, 354), (23, 36, 355),
    (23, 50, 356), (23, 60, 357), (23, 75, 358), (23, 90, 359), (23, 105, 360),
    (24, 1, 361), (24, 11, 362), (24, 21, 363), (24, 28, 364), (24, 32, 365),
    (24, 37, 366), (24, 44, 367), (24, 54, 368), (24, 59, 369), (24, 62, 370),
    (25, 1, 371), (25, 10, 372), (25, 21, 373), (25, 33, 374), (25, 44, 375),
    (25, 56, 376), (25, 68, 377), (26, 1, 378), (26, 20, 379), (26, 40, 380),
    (26, 61, 381), (26, 84, 382), (26, 112, 383), (26, 137, 384), (26, 160, 385),
    (26, 184, 386), (26, 207, 387), (27, 1, 388), (27, 14, 389), (27, 23, 390),
    (27, 36, 391), (27, 45, 392), (27, 56, 393), (27, 64, 394), (27, 77, 395),
    (27, 89, 396), (28, 1, 397), (28, 12, 398), (28, 22, 399), (28, 29, 400),
    (28, 36, 401), (28, 44, 402), (28, 51, 403), (28, 60, 404), (28, 71, 405),
    (28, 78, 406), (28, 85, 407), (29, 1, 408), (29, 8, 409), (29, 16, 410),
    (29, 26, 411), (29, 36, 412), (29, 46, 413), (29, 53, 414), (29, 64, 415),
    (30, 1, 416), (30, 7, 417), (30, 16, 418), (30, 25, 419), (30, 33, 420),
    (30, 42, 421), (30, 51, 422), (31, 1, 423), (31, 12, 424), (31, 20, 425),
    (31, 29, 426), (32, 1, 427), (32, 12, 428), (32, 21, 429), (33, 1, 430),
    (33, 7, 431), (33, 16, 432), (33, 23, 433), (33, 31, 434), (33, 36, 435),
    (33, 44, 436), (33, 51, 437), (33, 55, 438), (33, 63, 439), (34, 1, 440),
    (34, 8, 441), (34, 15, 442), (34, 23, 443), (34, 32, 444), (34, 40, 445),
    (34, 49, 446), (35, 1, 447), (35, 4, 448), (35, 12, 449), (35, 19, 450),
    (35, 31, 451), (35, 39, 452), (36, 1, 453), (36, 13, 454), (36, 28, 455),
    (36, 41, 456), (36, 55, 457), (36, 71, 458), (37, 1, 459), (37, 22, 460),
    (37, 48, 461), (37, 75, 462), (37, 103, 463), (37, 127, 464), (37, 154, 465),
    (38, 1, 466), (38, 17, 467), (38, 29, 468), (38, 44, 469), (38, 62, 470),
    (38, 84, 471), (39, 1, 472), (39, 7, 473), (39, 10, 474), (39, 15, 475),
    (39, 22, 476), (39, 32, 477), (39, 41, 478), (39, 48, 479), (39, 57, 480),
    (39, 64, 481), (39, 71, 482), (40, 1, 483), (40, 8, 484), (40, 17, 485),
    (40, 26, 486), (40, 34, 487), (40, 41, 488), (40, 50, 489), (40, 59, 490),
    (40, 67, 491), (40, 78, 492), (41, 1, 493), (41, 9, 494), (41, 15, 495),
    (41, 25, 496), (41, 33, 497), (41, 39, 498), (41, 47, 499), (42, 1, 500),
    (42, 10, 501), (42, 16, 502), (42, 23, 503), (42, 32, 504), (42, 45, 505),
    (42, 52, 506), (43, 11, 507), (43, 23, 508), (43, 36, 509), (43, 48, 510),
    (43, 60, 511), (43, 74, 512), (44, 1, 513), (44, 19, 514), (44, 40, 515),
    (45, 1, 516), (45, 12, 517), (45, 23, 518), (45, 33, 519), (46, 6, 520),
    (46, 15, 521), (46, 21, 522), (46, 29, 523), (47, 1, 524), (47, 10, 525),
    (47, 18, 526), (47, 33, 527), (48, 1, 528), (48, 10, 529), (48, 16, 530),
    (48, 24, 531), (49, 1, 532), (49, 11, 533), (50, 1, 534), (50, 16, 535),
    (50, 36, 536), (51, 7, 537), (51, 31, 538), (51, 52, 539), (52, 15, 540),
    (52, 32, 541), (53, 1, 542), (53, 27, 543), (53, 45, 544), (54, 7, 545),
    (54, 28, 546), (54, 50, 547), (55, 17, 548), (55, 41, 549), (55, 68, 550),
    (56, 17, 551), (56, 51, 552), (56, 77, 553), (57, 1, 554), (57, 12, 555),
    (57, 19, 556), (57, 25, 557), (58, 1, 558), (58, 7, 559), (58, 12, 560),
    (58, 22, 561), (59, 4, 562), (59, 11, 563), (59, 18, 564), (60, 4, 565),
    (60, 8, 566), (61, 1, 567), (61, 14, 568), (62, 6, 569), (63, 4, 570),
    (64, 1, 571), (64, 10, 572), (65, 1, 573), (65, 6, 574), (66, 1, 575),
    (66, 8, 576), (67, 1, 577), (67, 13, 578), (67, 30, 579), (68, 16, 580),
    (68, 43, 581), (69, 9, 582), (69, 35, 583), (70, 11, 584), (70, 40, 585),
    (71, 11, 586), (72, 1, 587), (72, 14, 588), (73, 1, 589), (73, 20, 590),
    (74, 18, 591), (74, 48, 592), (75, 20, 593), (76, 6, 594), (76, 26, 595),
    (77, 29, 596), (78, 1, 597), (78, 31, 598), (79, 28, 599), (80, 23, 600),
    (81, 15, 601), (82, 15, 602), (83, 29, 603), (85, 1, 604),
]

# Reciters
RECITERS = [
    ("mishary", "Mishary Rashid Alafasy", "مشاري راشد العفاسي", "Murattal", "https://cdn.islamic.network/quran/audio/128/ar.alafasy/"),
    ("sudais", "Abdul Rahman Al-Sudais", "عبدالرحمن السديس", "Murattal", "https://cdn.islamic.network/quran/audio/128/ar.abdurrahmaansudais/"),
    ("husary", "Mahmoud Khalil Al-Husary", "محمود خليل الحصري", "Murattal", "https://cdn.islamic.network/quran/audio/128/ar.husary/"),
    ("minshawi", "Mohamed Siddiq El-Minshawi", "محمد صديق المنشاوي", "Mujawwad", "https://cdn.islamic.network/quran/audio/128/ar.minshawi/"),
    ("abdulbasit", "Abdul Basit Abdul Samad", "عبدالباسط عبدالصمد", "Mujawwad", "https://cdn.islamic.network/quran/audio/128/ar.abdulbasitmurattal/"),
]


def download_quran_data():
    """Download complete Quran data from quran-json (sourced from tanzil.net)."""
    os.makedirs(CACHE_DIR, exist_ok=True)
    cache_file = os.path.join(CACHE_DIR, "quran_en.json")

    if os.path.exists(cache_file):
        print(f"Using cached data from {cache_file}")
        with open(cache_file, "r", encoding="utf-8") as f:
            return json.load(f)

    print(f"Downloading Quran data from {QURAN_JSON_URL}...")
    req = urllib.request.Request(QURAN_JSON_URL, headers={"User-Agent": "Safa-iOS-App/1.1"})
    with urllib.request.urlopen(req) as response:
        data = json.loads(response.read().decode("utf-8"))

    # Cache locally
    with open(cache_file, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False)
    print(f"Cached data to {cache_file}")

    return data


def get_juz_for_ayah(surah, ayah):
    """Determine which juz an ayah belongs to."""
    for juz_id, start_s, start_a, end_s, end_a in JUZ_BOUNDARIES:
        if (surah > start_s or (surah == start_s and ayah >= start_a)) and \
           (surah < end_s or (surah == end_s and ayah <= end_a)):
            return juz_id
    return 30


def get_page_for_ayah(surah, ayah):
    """Determine which Madinah Mushaf page an ayah is on."""
    page = 1
    for s, a, p in PAGE_BOUNDARIES:
        if (surah > s) or (surah == s and ayah >= a):
            page = p
        else:
            break
    return page


def create_database():
    """Create the Quran SQLite database with complete data."""

    # Download data
    quran_data = download_quran_data()

    # Ensure output directory exists
    db_path = os.path.normpath(DB_PATH)
    os.makedirs(os.path.dirname(db_path), exist_ok=True)

    # Remove existing database
    if os.path.exists(db_path):
        os.remove(db_path)

    conn = sqlite3.connect(db_path)
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

    # Insert all ayahs from downloaded data
    ayah_data = []
    total_ayahs = 0

    for surah_entry in quran_data:
        surah_num = surah_entry["id"]
        verses = surah_entry["verses"]

        for verse in verses:
            ayah_num = verse["id"]
            arabic = verse["text"]
            translation = verse["translation"]
            ayah_id = f"{surah_num}:{ayah_num}"
            juz_num = get_juz_for_ayah(surah_num, ayah_num)
            page_num = get_page_for_ayah(surah_num, ayah_num)

            ayah_data.append((ayah_id, surah_num, ayah_num, arabic, translation, None, juz_num, page_num))
            total_ayahs += 1

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

    # Verification
    cursor.execute("SELECT COUNT(*) FROM surahs")
    surah_count = cursor.fetchone()[0]
    cursor.execute("SELECT COUNT(*) FROM ayahs")
    ayah_count = cursor.fetchone()[0]
    cursor.execute("SELECT COUNT(*) FROM juz")
    juz_count = cursor.fetchone()[0]

    # Verify ayah counts match surah metadata
    mismatches = []
    for surah_id, _, name_en, _, _, expected_count, _ in SURAHS:
        cursor.execute("SELECT COUNT(*) FROM ayahs WHERE surah_number = ?", (surah_id,))
        actual = cursor.fetchone()[0]
        if actual != expected_count:
            mismatches.append(f"  Surah {surah_id} ({name_en}): expected {expected_count}, got {actual}")

    print(f"\nCreated quran.sqlite at {db_path}:")
    print(f"  - {surah_count} surahs")
    print(f"  - {ayah_count} ayahs")
    print(f"  - {juz_count} juz")
    print(f"  - Full-text search enabled")
    print(f"  - File size: {os.path.getsize(db_path) / 1024:.1f} KB")

    if mismatches:
        print(f"\nWARNING: Ayah count mismatches:")
        for m in mismatches:
            print(m)
    else:
        print(f"\n  All surah ayah counts match expected values.")

    # Quick FTS test
    cursor.execute("SELECT COUNT(*) FROM ayahs_fts WHERE text_translation MATCH 'mercy'")
    fts_count = cursor.fetchone()[0]
    print(f"  - FTS test: 'mercy' returns {fts_count} results")

    conn.close()
    print("\nDone!")


if __name__ == "__main__":
    create_database()
