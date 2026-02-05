// MARK: - IslamicConstants.swift
// PURPOSE: Islamic-specific constants and reference data
// DEPENDENCIES: Foundation

import Foundation

enum IslamicConstants {
    // MARK: - Quran Stats
    enum Quran {
        static let totalSurahs = 114
        static let totalAyahs = 6236
        static let totalJuz = 30
        static let totalPages = 604 // Madani Mushaf
        static let totalHizb = 60
    }

    // MARK: - Prayer Names
    enum PrayerNames {
        static let fajr = "Fajr"
        static let sunrise = "Sunrise"
        static let dhuhr = "Dhuhr"
        static let asr = "Asr"
        static let maghrib = "Maghrib"
        static let isha = "Isha"

        // Arabic
        static let fajrArabic = "الفجر"
        static let sunriseArabic = "الشروق"
        static let dhuhrArabic = "الظهر"
        static let asrArabic = "العصر"
        static let maghribArabic = "المغرب"
        static let ishaArabic = "العشاء"
    }

    // MARK: - Tasbeeh Counts
    enum Tasbeeh {
        static let standard = 33
        static let hundred = 100
        static let tahmeed = 33 // Alhamdulillah
        static let tahleel = 100 // La ilaha illallah
        static let takbeer = 34 // Allahu Akbar (after prayer it's 34)
    }

    // MARK: - Fasting
    enum Fasting {
        static let ramadanMinDays = 29
        static let ramadanMaxDays = 30
        static let suhoorEndBuffer: TimeInterval = 15 * 60 // 15 minutes before Fajr
        static let iftarStartBuffer: TimeInterval = 0 // At Maghrib
    }

    // MARK: - Zakat
    enum Zakat {
        static let nisabGoldGrams: Double = 87.48 // Grams of gold
        static let nisabSilverGrams: Double = 612.36 // Grams of silver
        static let zakatRate: Double = 0.025 // 2.5%
    }

    // MARK: - Kaaba Coordinates
    enum Kaaba {
        static let latitude: Double = 21.4225
        static let longitude: Double = 39.8262
    }

    // MARK: - Hijri Months
    static let hijriMonths = [
        "Muharram",
        "Safar",
        "Rabi' al-Awwal",
        "Rabi' al-Thani",
        "Jumada al-Awwal",
        "Jumada al-Thani",
        "Rajab",
        "Sha'ban",
        "Ramadan",
        "Shawwal",
        "Dhu al-Qi'dah",
        "Dhu al-Hijjah"
    ]

    static let hijriMonthsArabic = [
        "محرم",
        "صفر",
        "ربيع الأول",
        "ربيع الثاني",
        "جمادى الأولى",
        "جمادى الآخرة",
        "رجب",
        "شعبان",
        "رمضان",
        "شوال",
        "ذو القعدة",
        "ذو الحجة"
    ]

    // MARK: - Days of Week (Arabic)
    static let daysOfWeekArabic = [
        "الأحد",      // Sunday
        "الإثنين",    // Monday
        "الثلاثاء",   // Tuesday
        "الأربعاء",   // Wednesday
        "الخميس",     // Thursday
        "الجمعة",     // Friday
        "السبت"       // Saturday
    ]

    // MARK: - Common Phrases
    enum Phrases {
        static let bismillah = "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ"
        static let bismillahSimple = "بِسْمِ اللَّهِ"
        static let alhamdulillah = "الْحَمْدُ لِلَّهِ"
        static let subhanAllah = "سُبْحَانَ اللَّهِ"
        static let allahuAkbar = "اللَّهُ أَكْبَرُ"
        static let laIlahaIllallah = "لَا إِلَٰهَ إِلَّا اللَّهُ"
        static let astaghfirullah = "أَسْتَغْفِرُ اللَّهَ"
        static let inshallah = "إِنْ شَاءَ اللَّهُ"
        static let mashallah = "مَا شَاءَ اللَّهُ"
        static let jazakAllah = "جَزَاكَ اللَّهُ خَيْرًا"
        static let sallamAlaikum = "السَّلَامُ عَلَيْكُمْ"
    }

    // MARK: - Quran Special Surahs
    enum SpecialSurahs {
        static let alFatiha = 1
        static let alBaqarah = 2
        static let aliImran = 3
        static let alKahf = 18
        static let yasin = 36
        static let arRahman = 55
        static let alWaqiah = 56
        static let alMulk = 67
        static let alIkhlas = 112
        static let alFalaq = 113
        static let anNas = 114
    }

    // MARK: - Ayat al-Kursi Reference
    static let ayatAlKursi = (surah: 2, ayah: 255)
}
