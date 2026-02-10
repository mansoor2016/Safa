// MARK: - DuaCategoriesView.swift
// PURPOSE: Browse duas by category
// DEPENDENCIES: SwiftUI

import SwiftUI

// MARK: - Dua Categories View

struct DuaCategoriesView: View {
    @State private var searchText = ""

    private var filteredCategories: [DuaCategoryData] {
        if searchText.isEmpty {
            return DuaCategoryData.allCategories
        }
        return DuaCategoryData.allCategories.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.arabicName.contains(searchText)
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                headerView
                quickAccessSection
                searchBar
                categoriesSection
            }
            .padding(.bottom, 100)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Duas")
        .navigationBarTitleDisplayMode(.large)
    }

    private var headerView: some View {
        VStack(spacing: 8) {
            Text("أدعية وأذكار")
                .font(SafaTypography.arabicMedium)
                .environment(\.layoutDirection, .rightToLeft)
                .accessibilityArabic()

            Text("Supplications & Remembrances")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 20)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Supplications and Remembrances")
    }

    private var quickAccessSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Access")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    NavigationLink(destination: DuaListView(category: DuaCategoryData.morning)) {
                        QuickAccessButton(title: "Morning", arabicTitle: "أذكار الصباح", iconName: "sunrise.fill", color: .orange)
                    }
                    .buttonStyle(.plain)

                    NavigationLink(destination: DuaListView(category: DuaCategoryData.prayer)) {
                        QuickAccessButton(title: "After Prayer", arabicTitle: "بعد الصلاة", iconName: "hands.sparkles.fill", color: .teal)
                    }
                    .buttonStyle(.plain)

                    NavigationLink(destination: DuaListView(category: DuaCategoryData.food)) {
                        QuickAccessButton(title: "Food & Drink", arabicTitle: "أذكار الطعام", iconName: "fork.knife", color: .indigo)
                    }
                    .buttonStyle(.plain)

                    NavigationLink(destination: DuaListView(category: DuaCategoryData.sleep)) {
                        QuickAccessButton(title: "Sleep", arabicTitle: "أذكار النوم", iconName: "moon.zzz.fill", color: .purple)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
            }
        }
    }

    private var searchBar: some View {
        SearchBar(
            text: $searchText,
            placeholder: "Search duas..."
        )
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal)

            ForEach(filteredCategories) { category in
                NavigationLink(destination: DuaListView(category: category)) {
                    CategoryRow(category: category)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Category Data (Single Source of Truth)

struct DuaCategoryData: Identifiable, Hashable {
    let id: String
    let name: String
    let arabicName: String
    let iconName: String

    var duaCount: Int {
        DuaData.allDuas.filter { $0.categoryId == id }.count
    }

    static let morning = DuaCategoryData(id: "morning", name: "Morning", arabicName: "أذكار الصباح", iconName: "sunrise")
    static let evening = DuaCategoryData(id: "evening", name: "Evening", arabicName: "أذكار المساء", iconName: "sunset")
    static let prayer = DuaCategoryData(id: "prayer", name: "Prayer", arabicName: "أدعية الصلاة", iconName: "moon.stars")
    static let daily = DuaCategoryData(id: "daily", name: "Daily Activities", arabicName: "أذكار اليومية", iconName: "sun.max")
    static let protection = DuaCategoryData(id: "protection", name: "Protection", arabicName: "أدعية الحفظ", iconName: "shield")
    static let forgiveness = DuaCategoryData(id: "forgiveness", name: "Forgiveness", arabicName: "أدعية الاستغفار", iconName: "heart")
    static let travel = DuaCategoryData(id: "travel", name: "Travel", arabicName: "أذكار السفر", iconName: "airplane")
    static let food = DuaCategoryData(id: "food", name: "Food & Drink", arabicName: "أذكار الطعام", iconName: "fork.knife")
    static let sleep = DuaCategoryData(id: "sleep", name: "Sleep", arabicName: "أذكار النوم", iconName: "moon.zzz")
    static let anxiety = DuaCategoryData(id: "anxiety", name: "Anxiety & Distress", arabicName: "أدعية الهم والحزن", iconName: "heart.circle")
    static let funeral = DuaCategoryData(id: "funeral", name: "Funeral & Bereavement", arabicName: "أدعية الجنازة", iconName: "leaf")
    static let ramadan = DuaCategoryData(id: "ramadan", name: "Ramadan", arabicName: "أدعية رمضان", iconName: "moon.stars")

    static let allCategories: [DuaCategoryData] = [
        morning, evening, prayer, daily, protection, forgiveness, travel, food, sleep, anxiety, funeral, ramadan
    ]
}

// MARK: - Dua Data (Actual Content)

struct DuaData {
    static let allDuas: [Dua] = [
        // MARK: Morning
        Dua(id: "m1", categoryId: "morning", titleEnglish: "Morning Remembrance",
            textArabic: "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ",
            textTransliteration: "Asbahna wa asbahal-mulku lillah, walhamdu lillah, la ilaha illallahu wahdahu la shareeka lah",
            textTranslation: "We have reached the morning and at this very time the whole kingdom belongs to Allah. All praise is due to Allah.",
            source: "Abu Dawud 4:317", occasion: "Said upon waking", repetitions: 1),
        Dua(id: "m2", categoryId: "morning", titleEnglish: "Morning Glorification",
            textArabic: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ",
            textTransliteration: "SubhanAllahi wa bihamdihi",
            textTranslation: "Glory is to Allah and praise is to Him.",
            source: "Muslim 4:2071", occasion: "100 times in morning — sins forgiven even if like foam of the sea", repetitions: 100),
        Dua(id: "m3", categoryId: "morning", titleEnglish: "Seeking Refuge",
            textArabic: "أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ",
            textTransliteration: "A'udhu bikalimatillahit-tammaati min sharri ma khalaq",
            textTranslation: "I seek refuge in the perfect words of Allah from the evil of what He has created.",
            source: "Muslim 4:2080", occasion: "Morning and evening", repetitions: 3),

        // MARK: Evening
        Dua(id: "e1", categoryId: "evening", titleEnglish: "Evening Remembrance",
            textArabic: "أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ",
            textTransliteration: "Amsayna wa amsal-mulku lillah, walhamdu lillah",
            textTranslation: "We have reached the evening and the whole kingdom belongs to Allah.",
            source: "Abu Dawud 4:317", occasion: "Said in the evening", repetitions: 1),
        Dua(id: "e2", categoryId: "evening", titleEnglish: "Evening Glorification",
            textArabic: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ",
            textTransliteration: "SubhanAllahi wa bihamdihi",
            textTranslation: "Glory is to Allah and praise is to Him.",
            source: "Muslim 4:2071", occasion: "100 times in evening — sins forgiven", repetitions: 100),

        // MARK: Prayer
        Dua(id: "p1", categoryId: "prayer", titleEnglish: "After Prayer Glorification",
            textArabic: "سُبْحَانَ اللهِ ، وَالْحَمْدُ لِلَّهِ ، وَاللهُ أَكْبَرُ",
            textTransliteration: "SubhanAllah, Alhamdulillah, Allahu Akbar",
            textTranslation: "Glory be to Allah, All praise is due to Allah, Allah is the Greatest.",
            source: "Muslim", occasion: "After each obligatory prayer", repetitions: 33),
        Dua(id: "p2", categoryId: "prayer", titleEnglish: "Ayatul Kursi",
            textArabic: "اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ",
            textTransliteration: "Allahu la ilaha illa Huwal-Hayyul-Qayyum",
            textTranslation: "Allah - there is no deity except Him, the Ever-Living, the Self-Sustaining.",
            source: "Bukhari", occasion: "After each obligatory prayer — whoever recites it will enter Paradise", repetitions: 1),

        // MARK: Sleep
        Dua(id: "s1", categoryId: "sleep", titleEnglish: "Before Sleeping",
            textArabic: "بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا",
            textTransliteration: "Bismika Allahumma amootu wa ahya",
            textTranslation: "In Your name O Allah, I die and I live.",
            source: "Bukhari", occasion: "Said before going to sleep", repetitions: 1),
        Dua(id: "s2", categoryId: "sleep", titleEnglish: "Surah Al-Mulk",
            textArabic: "تَبَارَكَ الَّذِي بِيَدِهِ الْمُلْكُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ",
            textTransliteration: "Tabarakal-ladhi biyadihil-mulku wa Huwa 'ala kulli shay'in Qadeer",
            textTranslation: "Blessed is He in whose hand is dominion, and He is over all things competent.",
            source: "Tirmidhi", occasion: "Recite Surah Al-Mulk before sleep — it intercedes for its reader", repetitions: 1),

        // MARK: Food & Drink
        Dua(id: "f1", categoryId: "food", titleEnglish: "Before Eating",
            textArabic: "بِسْمِ اللَّهِ",
            textTransliteration: "Bismillah",
            textTranslation: "In the name of Allah.",
            source: "Tirmidhi 1858", occasion: "Said before eating", repetitions: 1),
        Dua(id: "f2", categoryId: "food", titleEnglish: "After Eating",
            textArabic: "الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنِي هَذَا وَرَزَقَنِيهِ مِنْ غَيْرِ حَوْلٍ مِنِّي وَلَا قُوَّةٍ",
            textTransliteration: "Alhamdu lillahil-ladhi at'amani hadha wa razaqaneehi min ghayri hawlin minni wa la quwwah",
            textTranslation: "Praise be to Allah who fed me this and provided it for me without any might or power on my part.",
            source: "Tirmidhi 3458", occasion: "Said after finishing a meal — past sins are forgiven", repetitions: 1),
        Dua(id: "f3", categoryId: "food", titleEnglish: "Forgetting Bismillah",
            textArabic: "بِسْمِ اللَّهِ أَوَّلَهُ وَآخِرَهُ",
            textTransliteration: "Bismillahi awwalahu wa akhirah",
            textTranslation: "In the name of Allah at the beginning and at the end.",
            source: "Abu Dawud 3767", occasion: "If you forgot to say Bismillah before eating", repetitions: 1),
        Dua(id: "f4", categoryId: "food", titleEnglish: "When Breaking Fast",
            textArabic: "ذَهَبَ الظَّمَأُ وَابْتَلَّتِ الْعُرُوقُ وَثَبَتَ الْأَجْرُ إِنْ شَاءَ اللَّهُ",
            textTransliteration: "Dhahaba ath-thama'u wab-tallat al-'urooqu wa thabat al-ajru in sha Allah",
            textTranslation: "The thirst has gone, the veins are moistened and the reward is confirmed, if Allah wills.",
            source: "Abu Dawud 2357", occasion: "When breaking the fast (Iftar)", repetitions: 1),
        Dua(id: "f5", categoryId: "food", titleEnglish: "When Drinking Water",
            textArabic: "الْحَمْدُ لِلَّهِ",
            textTransliteration: "Alhamdulillah",
            textTranslation: "All praise is due to Allah.",
            source: "Ibn Majah", occasion: "After drinking water or any beverage", repetitions: 1),

        // MARK: Protection
        Dua(id: "pr1", categoryId: "protection", titleEnglish: "Seeking Refuge from Evil",
            textArabic: "أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ",
            textTransliteration: "A'udhu bikalimatillahit-tammaati min sharri ma khalaq",
            textTranslation: "I seek refuge in the perfect words of Allah from the evil of what He has created.",
            source: "Muslim 4:2080", repetitions: 3),

        // MARK: Forgiveness
        Dua(id: "fg1", categoryId: "forgiveness", titleEnglish: "Master of Seeking Forgiveness",
            textArabic: "اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَٰهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ",
            textTransliteration: "Allahumma Anta Rabbi la ilaha illa Anta, khalaqtani wa ana 'abduk",
            textTranslation: "O Allah, You are my Lord, there is no god but You. You created me and I am Your servant.",
            source: "Bukhari", occasion: "Sayyidul Istighfar — whoever says this with conviction and dies that day enters Paradise", repetitions: 1),

        // MARK: Anxiety
        Dua(id: "ax1", categoryId: "anxiety", titleEnglish: "Relief from Distress",
            textArabic: "لَا إِلَٰهَ إِلَّا اللَّهُ الْعَظِيمُ الْحَلِيمُ، لَا إِلَٰهَ إِلَّا اللَّهُ رَبُّ الْعَرْشِ الْعَظِيمِ",
            textTransliteration: "La ilaha illallahul-'Adheemul-Haleem, la ilaha illallahu Rabbul-'Arshil-'Adheem",
            textTranslation: "There is no god but Allah, the Mighty, the Forbearing. There is no god but Allah, Lord of the Mighty Throne.",
            source: "Bukhari & Muslim", occasion: "When afflicted with grief or distress", repetitions: 1),

        // MARK: Travel
        Dua(id: "t1", categoryId: "travel", titleEnglish: "Travel Supplication",
            textArabic: "سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَٰذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ",
            textTransliteration: "Subhanal-ladhi sakh-khara lana hadha wa ma kunna lahu muqrineen",
            textTranslation: "Glory to Him who has subjected this to us, for we could never have accomplished this by ourselves.",
            source: "Muslim", occasion: "When starting a journey", repetitions: 1),

        // MARK: Daily
        Dua(id: "d1", categoryId: "daily", titleEnglish: "Entering the Home",
            textArabic: "بِسْمِ اللَّهِ وَلَجْنَا، وَبِسْمِ اللَّهِ خَرَجْنَا، وَعَلَى رَبِّنَا تَوَكَّلْنَا",
            textTransliteration: "Bismillahi walajna, wa bismillahi kharajna, wa 'ala Rabbina tawakkalna",
            textTranslation: "In the name of Allah we enter, in the name of Allah we leave, and upon our Lord we place our trust.",
            source: "Abu Dawud 5096", occasion: "When entering the home", repetitions: 1),
        Dua(id: "d2", categoryId: "daily", titleEnglish: "Leaving the Home",
            textArabic: "بِسْمِ اللَّهِ تَوَكَّلْتُ عَلَى اللَّهِ، لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ",
            textTransliteration: "Bismillahi tawakkaltu 'alAllah, la hawla wa la quwwata illa billah",
            textTranslation: "In the name of Allah, I place my trust in Allah. There is no might or power except with Allah.",
            source: "Abu Dawud 5095", occasion: "When leaving the home", repetitions: 1),

        // MARK: Funeral & Bereavement
        Dua(id: "fn1", categoryId: "funeral", titleEnglish: "Funeral Prayer (Janazah)",
            textArabic: "اللَّهُمَّ اغْفِرْ لَهُ وَارْحَمْهُ، وَعَافِهِ وَاعْفُ عَنْهُ، وَأَكْرِمْ نُزُلَهُ، وَوَسِّعْ مُدْخَلَهُ",
            textTransliteration: "Allahum-maghfir lahu warhamhu, wa 'afihi wa'fu 'anhu, wa akrim nuzulahu, wa wassi' mudkhalahu",
            textTranslation: "O Allah, forgive him and have mercy on him, grant him well-being and pardon him, honour his resting place and widen his entrance.",
            source: "Muslim 963", occasion: "During the funeral prayer", repetitions: 1),
        Dua(id: "fn2", categoryId: "funeral", titleEnglish: "Upon Hearing of a Death",
            textArabic: "إِنَّا لِلَّهِ وَإِنَّا إِلَيْهِ رَاجِعُونَ",
            textTransliteration: "Inna lillahi wa inna ilayhi raji'un",
            textTranslation: "Indeed we belong to Allah, and indeed to Him we will return.",
            source: "Quran 2:156", occasion: "Upon hearing news of someone's passing", repetitions: 1),
        Dua(id: "fn3", categoryId: "funeral", titleEnglish: "Visiting the Grave",
            textArabic: "السَّلَامُ عَلَيْكُمْ أَهْلَ الدِّيَارِ مِنَ الْمُؤْمِنِينَ وَالْمُسْلِمِينَ، وَإِنَّا إِنْ شَاءَ اللَّهُ بِكُمْ لَاحِقُونَ",
            textTransliteration: "As-salamu 'alaykum ahlad-diyari minal-mu'mineena wal-muslimeen, wa inna in sha Allahu bikum lahiqun",
            textTranslation: "Peace be upon you, O inhabitants of the graves, from among the believers and the Muslims. Indeed, if Allah wills, we will join you.",
            source: "Muslim 975", occasion: "When visiting the graveyard", repetitions: 1),
        Dua(id: "fn4", categoryId: "funeral", titleEnglish: "For the Deceased",
            textArabic: "اللَّهُمَّ اغْفِرْ لِحَيِّنَا وَمَيِّتِنَا، وَشَاهِدِنَا وَغَائِبِنَا، وَصَغِيرِنَا وَكَبِيرِنَا، وَذَكَرِنَا وَأُنْثَانَا",
            textTransliteration: "Allahum-maghfir lihayyina wa mayyitina, wa shahidina wa gha'ibina, wa sagheerina wa kabeerina, wa dhakarina wa unthana",
            textTranslation: "O Allah, forgive our living and our dead, those who are present and those who are absent, our young and our old, our males and our females.",
            source: "Tirmidhi 1024", occasion: "During funeral prayer", repetitions: 1),

        // MARK: Ramadan
        Dua(id: "rm1", categoryId: "ramadan", titleEnglish: "Intention for Fasting",
            textArabic: "نَوَيْتُ أَنْ أَصُومَ غَدًا مِنْ شَهْرِ رَمَضَانَ الْمُبَارَكِ فَرْضًا لَكَ يَا اللَّهُ فَتَقَبَّلْ مِنِّي إِنَّكَ أَنْتَ السَّمِيعُ الْعَلِيمُ",
            textTransliteration: "Nawaytu an asuma ghadan min shahri Ramadan al-mubarak, fardhan laka ya Allah, fataqabbal minni innaka antas-Samee'ul-'Aleem",
            textTranslation: "I intend to fast tomorrow in the blessed month of Ramadan, as an obligation for You, O Allah, so accept it from me. Indeed You are the All-Hearing, the All-Knowing.",
            source: "Scholarly tradition", occasion: "Before Fajr, intending to fast", repetitions: 1),
        Dua(id: "rm2", categoryId: "ramadan", titleEnglish: "Breaking the Fast (Iftar)",
            textArabic: "ذَهَبَ الظَّمَأُ وَابْتَلَّتِ الْعُرُوقُ وَثَبَتَ الْأَجْرُ إِنْ شَاءَ اللَّهُ",
            textTransliteration: "Dhahaba ath-thama'u wab-tallat al-'urooqu wa thabat al-ajru in sha Allah",
            textTranslation: "The thirst has gone, the veins are moistened and the reward is confirmed, if Allah wills.",
            source: "Abu Dawud 2357", occasion: "At the time of breaking the fast", repetitions: 1),
        Dua(id: "rm3", categoryId: "ramadan", titleEnglish: "Laylatul Qadr",
            textArabic: "اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي",
            textTransliteration: "Allahumma innaka 'afuwwun tuhibbul-'afwa fa'fu 'anni",
            textTranslation: "O Allah, You are the Most Forgiving, and You love forgiveness, so forgive me.",
            source: "Tirmidhi 3513", occasion: "During the last 10 nights of Ramadan, especially odd nights", repetitions: 3),
        Dua(id: "rm4", categoryId: "ramadan", titleEnglish: "Suhoor Supplication",
            textArabic: "اللَّهُمَّ إِنِّي أَسْأَلُكَ بِرَحْمَتِكَ الَّتِي وَسِعَتْ كُلَّ شَيْءٍ أَنْ تَغْفِرَ لِي",
            textTransliteration: "Allahumma inni as'aluka birahmatik-allatee wasi'at kulla shay'in an taghfira lee",
            textTranslation: "O Allah, I ask You by Your mercy which encompasses all things, to forgive me.",
            source: "Ibn Majah", occasion: "During suhoor (pre-dawn meal)", repetitions: 1),
    ]
}

// MARK: - Quick Access Button

struct QuickAccessButton: View {
    let title: String
    let arabicTitle: String
    let iconName: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(color)
            }

            Text(title)
                .font(.caption)
                .fontWeight(.medium)

            Text(arabicTitle)
                .font(.caption2)
                .foregroundColor(.secondary)
                .environment(\.layoutDirection, .rightToLeft)
                .accessibilityArabic()
        }
        .frame(width: 80)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) duas")
    }
}

// MARK: - Category Row

struct CategoryRow: View {
    let category: DuaCategoryData

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 48, height: 48)

                Image(systemName: category.iconName)
                    .font(.title3)
                    .foregroundColor(.accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(category.name)
                    .font(.headline)

                Text(category.arabicName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .environment(\.layoutDirection, .rightToLeft)
                    .accessibilityArabic()
            }

            Spacer()

            Text("\(category.duaCount)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.tertiarySystemGroupedBackground))
                .cornerRadius(8)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(category.name), \(category.duaCount) duas")
    }
}

// MARK: - Dua List View

struct DuaListView: View {
    let category: DuaCategoryData

    private var duas: [Dua] {
        DuaData.allDuas.filter { $0.categoryId == category.id }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(duas) { dua in
                    DuaCard(dua: dua)
                }

                if duas.isEmpty {
                    ContentUnavailableView(
                        "No Duas Yet",
                        systemImage: "text.book.closed",
                        description: Text("Duas for this category are coming soon.")
                    )
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Dua Card

struct DuaCard: View {
    let dua: Dua
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(dua.textArabic)
                .font(.system(size: 24, weight: .regular, design: .serif))
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .lineSpacing(12)
                .environment(\.layoutDirection, .rightToLeft)
                .accessibilityArabic()

            if !dua.textTransliteration.isEmpty {
                Text(dua.textTransliteration)
                    .font(.subheadline)
                    .italic()
                    .foregroundColor(.secondary)
            }

            Text(dua.textTranslation)
                .font(.subheadline)

            HStack {
                if let occasion = dua.occasion, isExpanded {
                    Text(occasion)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if dua.repetitions > 1 {
                    Label("\(dua.repetitions)x", systemImage: "repeat")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }

            HStack {
                Text(dua.source ?? "")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                Button {
                    withAnimation { isExpanded.toggle() }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DuaCategoriesView()
    }
}
