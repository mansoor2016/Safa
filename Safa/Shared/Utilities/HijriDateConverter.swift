// MARK: - HijriDateConverter.swift
// PURPOSE: Convert between Gregorian and Islamic (Hijri) calendar dates
// DEPENDENCIES: Foundation

import Foundation

final class HijriDateConverter {
    // MARK: - Singleton
    static let shared = HijriDateConverter()

    // MARK: - Properties
    private let islamicCalendar: Calendar
    private let gregorianCalendar: Calendar

    // MARK: - Init
    private init() {
        var islamic = Calendar(identifier: .islamicUmmAlQura)
        islamic.locale = Locale(identifier: "ar")
        islamicCalendar = islamic

        gregorianCalendar = Calendar(identifier: .gregorian)
    }

    // MARK: - Conversion Methods

    func hijriDate(from gregorianDate: Date) -> DateComponents {
        islamicCalendar.dateComponents([.year, .month, .day], from: gregorianDate)
    }

    /// Returns hijri date components as a tuple (year, month, day)
    func hijriComponents(from gregorianDate: Date) -> (year: Int, month: Int, day: Int) {
        let components = hijriDate(from: gregorianDate)
        return (components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }

    func gregorianDate(from hijriComponents: DateComponents) -> Date? {
        islamicCalendar.date(from: hijriComponents)
    }

    // MARK: - Formatting

    func hijriDateString(from date: Date, style: HijriDateStyle = .full) -> String {
        let components = hijriDate(from: date)

        guard let day = components.day,
              let month = components.month,
              let year = components.year else {
            return ""
        }

        switch style {
        case .full:
            let monthName = hijriMonthName(month)
            return "\(day) \(monthName) \(year) AH"
        case .dayMonth:
            let monthName = hijriMonthName(month)
            return "\(day) \(monthName)"
        case .short:
            return "\(day)/\(month)/\(year)"
        case .arabic:
            let monthName = hijriMonthNameArabic(month)
            return "\(day.arabicNumerals) \(monthName) \(year.arabicNumerals) هـ"
        case .monthYear:
            let monthName = hijriMonthName(month)
            return "\(monthName) \(year) AH"
        }
    }

    enum HijriDateStyle {
        case full       // "15 Ramadan 1445 AH"
        case dayMonth   // "15 Ramadan"
        case short      // "15/9/1445"
        case arabic     // "١٥ رمضان ١٤٤٥ هـ"
        case monthYear  // "Ramadan 1445 AH"
    }

    // MARK: - Month Names

    func hijriMonthName(_ month: Int) -> String {
        switch month {
        case 1: return "Muharram"
        case 2: return "Safar"
        case 3: return "Rabi' al-Awwal"
        case 4: return "Rabi' al-Thani"
        case 5: return "Jumada al-Awwal"
        case 6: return "Jumada al-Thani"
        case 7: return "Rajab"
        case 8: return "Sha'ban"
        case 9: return "Ramadan"
        case 10: return "Shawwal"
        case 11: return "Dhu al-Qi'dah"
        case 12: return "Dhu al-Hijjah"
        default: return ""
        }
    }

    func hijriMonthNameArabic(_ month: Int) -> String {
        switch month {
        case 1: return "محرم"
        case 2: return "صفر"
        case 3: return "ربيع الأول"
        case 4: return "ربيع الثاني"
        case 5: return "جمادى الأولى"
        case 6: return "جمادى الآخرة"
        case 7: return "رجب"
        case 8: return "شعبان"
        case 9: return "رمضان"
        case 10: return "شوال"
        case 11: return "ذو القعدة"
        case 12: return "ذو الحجة"
        default: return ""
        }
    }

    // MARK: - Islamic Dates

    func isRamadan(on date: Date = Date()) -> Bool {
        let components = hijriDate(from: date)
        return components.month == 9
    }

    func isEid(on date: Date = Date()) -> Bool {
        currentEidType(on: date) != nil
    }

    /// Check if the date falls within Eid al-Fitr (Shawwal 1-3)
    func isEidAlFitr(on date: Date = Date()) -> Bool {
        let components = hijriDate(from: date)
        guard let month = components.month, let day = components.day else { return false }
        return month == 10 && (1...3).contains(day)
    }

    /// Check if the date falls within Eid al-Adha (Dhu al-Hijjah 10-13)
    func isEidAlAdha(on date: Date = Date()) -> Bool {
        let components = hijriDate(from: date)
        guard let month = components.month, let day = components.day else { return false }
        return month == 12 && (10...13).contains(day)
    }

    /// Returns the current Eid type if the date is during an Eid period, nil otherwise
    func currentEidType(on date: Date = Date()) -> EidType? {
        if isEidAlFitr(on: date) { return .fitr }
        if isEidAlAdha(on: date) { return .adha }
        return nil
    }

    /// Returns 1-based day number within the Eid period (e.g. Day 2 of Eid al-Fitr)
    func eidDayNumber(on date: Date = Date()) -> Int? {
        let components = hijriDate(from: date)
        guard let month = components.month, let day = components.day else { return nil }

        if month == 10 && (1...3).contains(day) {
            return day  // Fitr: Shawwal 1=Day1, 2=Day2, 3=Day3
        }
        if month == 12 && (10...13).contains(day) {
            return day - 9  // Adha: Dhul Hijjah 10=Day1, 11=Day2, 12=Day3, 13=Day4
        }
        return nil
    }

    /// Days until Eid al-Fitr (Shawwal 1) from the given date
    func daysUntilEidAlFitr(from date: Date = Date()) -> Int? {
        daysUntilHijriDate(month: 10, day: 1, from: date)
    }

    /// Days until Eid al-Adha (Dhu al-Hijjah 10) from the given date
    func daysUntilEidAlAdha(from date: Date = Date()) -> Int? {
        daysUntilHijriDate(month: 12, day: 10, from: date)
    }

    /// Returns the nearest upcoming Eid with days until it (nil if currently during an Eid)
    func nearestUpcomingEid(from date: Date = Date()) -> (type: EidType, daysUntil: Int)? {
        // If currently during Eid, no "upcoming" Eid
        if currentEidType(on: date) != nil { return nil }

        let fitrDays = daysUntilEidAlFitr(from: date)
        let adhaDays = daysUntilEidAlAdha(from: date)

        switch (fitrDays, adhaDays) {
        case let (f?, a?) where f <= 0 && a <= 0:
            return nil
        case let (f?, a?):
            let validF = f > 0 ? f : Int.max
            let validA = a > 0 ? a : Int.max
            return validF <= validA ? (type: .fitr, daysUntil: validF) : (type: .adha, daysUntil: validA)
        case let (f?, nil) where f > 0:
            return (type: .fitr, daysUntil: f)
        case let (nil, a?) where a > 0:
            return (type: .adha, daysUntil: a)
        default:
            return nil
        }
    }

    /// Private helper: days from `date` to the next occurrence of a given Hijri month/day
    private func daysUntilHijriDate(month targetMonth: Int, day targetDay: Int, from date: Date) -> Int? {
        let current = hijriDate(from: date)
        guard let currentYear = current.year else { return nil }

        // Try this Hijri year first, then next year
        for yearOffset in 0...1 {
            var target = DateComponents()
            target.year = currentYear + yearOffset
            target.month = targetMonth
            target.day = targetDay

            if let targetDate = gregorianDate(from: target) {
                let days = gregorianCalendar.dateComponents([.day], from: date, to: targetDate).day ?? 0
                if days > 0 { return days }
            }
        }
        return nil
    }

    func isBlessedNight(on date: Date = Date()) -> Bool {
        let components = hijriDate(from: date)
        guard let month = components.month, let day = components.day else { return false }

        // Laylat al-Qadr (likely nights in last 10 days of Ramadan)
        if month == 9 && day >= 21 && day % 2 == 1 {
            return true
        }

        // 15th of Sha'ban
        if month == 8 && day == 15 {
            return true
        }

        return false
    }

    func daysUntilRamadan(from date: Date = Date()) -> Int? {
        let currentComponents = hijriDate(from: date)
        guard let currentMonth = currentComponents.month,
              let currentYear = currentComponents.year else {
            return nil
        }

        // If already in Ramadan
        if currentMonth == 9 {
            return 0
        }

        // Calculate target Ramadan
        var targetYear = currentYear
        if currentMonth > 9 {
            targetYear += 1
        }

        var targetComponents = DateComponents()
        targetComponents.year = targetYear
        targetComponents.month = 9
        targetComponents.day = 1

        guard let ramadanStart = gregorianDate(from: targetComponents) else {
            return nil
        }

        return gregorianCalendar.dateComponents([.day], from: date, to: ramadanStart).day
    }

    // MARK: - Important Dates

    /// Single-entry cache: stores the last computed year to avoid redundant calendar math.
    private var cachedYear: Int?
    private var cachedDates: [IslamicDate] = []

    func importantIslamicDates(for gregorianYear: Int) -> [IslamicDate] {
        if gregorianYear == cachedYear {
            return cachedDates
        }

        let result = computeImportantIslamicDates(for: gregorianYear)
        cachedYear = gregorianYear
        cachedDates = result
        return result
    }

    private func computeImportantIslamicDates(for gregorianYear: Int) -> [IslamicDate] {
        var dates: [IslamicDate] = []

        let importantDates: [(month: Int, day: Int, name: String, arabic: String)] = [
            (1, 1, "Islamic New Year", "رأس السنة الهجرية"),
            (1, 10, "Ashura", "عاشوراء"),
            (3, 12, "Mawlid an-Nabi", "المولد النبوي"),
            (7, 27, "Isra and Mi'raj", "الإسراء والمعراج"),
            (8, 15, "Mid-Sha'ban", "ليلة النصف من شعبان"),
            (9, 1, "First of Ramadan", "أول رمضان"),
            (10, 1, "Eid al-Fitr", "عيد الفطر"),
            (12, 9, "Day of Arafah", "يوم عرفة"),
            (12, 10, "Eid al-Adha", "عيد الأضحى"),
        ]

        // A Gregorian year spans parts of 2-3 Hijri years (Islamic year is ~354 days).
        // Find the Hijri year at Jan 1 and Dec 31 of the target Gregorian year to cover all.
        let hijriYears = hijriYearsOverlapping(gregorianYear: gregorianYear)

        for hijriYear in hijriYears {
            for (month, day, name, arabic) in importantDates {
                var components = DateComponents()
                components.year = hijriYear
                components.month = month
                components.day = day

                if let gregorianDate = self.gregorianDate(from: components),
                   gregorianCalendar.component(.year, from: gregorianDate) == gregorianYear {
                    dates.append(IslamicDate(
                        name: name,
                        nameArabic: arabic,
                        hijriMonth: month,
                        hijriDay: day,
                        gregorianDate: gregorianDate
                    ))
                }
            }
        }

        return dates.sorted { $0.gregorianDate < $1.gregorianDate }
    }

    /// Returns the set of Hijri years that overlap with the given Gregorian year.
    private func hijriYearsOverlapping(gregorianYear: Int) -> Set<Int> {
        var gregComponents = DateComponents()
        gregComponents.year = gregorianYear

        gregComponents.month = 1
        gregComponents.day = 1
        let jan1 = gregorianCalendar.date(from: gregComponents) ?? Date()

        gregComponents.month = 12
        gregComponents.day = 31
        let dec31 = gregorianCalendar.date(from: gregComponents) ?? Date()

        let startYear = islamicCalendar.component(.year, from: jan1)
        let endYear = islamicCalendar.component(.year, from: dec31)

        var years: Set<Int> = []
        for year in startYear...endYear {
            years.insert(year)
        }
        return years
    }
}

// MARK: - Islamic Date Model

struct IslamicDate: Identifiable {
    let id = UUID()
    let name: String
    let nameArabic: String
    let hijriMonth: Int
    let hijriDay: Int
    let gregorianDate: Date

    var monthName: String {
        HijriDateConverter.shared.hijriMonthName(hijriMonth)
    }
}

// MARK: - Int Extension for Arabic Numerals

private extension Int {
    var arabicNumerals: String {
        String(self).arabicNumerals
    }
}
