// MARK: - RamadanDuasView.swift
// PURPOSE: Collection of Ramadan-specific duas (Iftar, Suhoor, Taraweeh, Laylatul Qadr)
// DEPENDENCIES: SwiftUI

import SwiftUI

// MARK: - Ramadan Dua Model

struct RamadanDua: Identifiable {
    let id: String
    let title: String
    let titleArabic: String
    let arabic: String
    let transliteration: String
    let translation: String
    let occasion: RamadanDuaOccasion
    let reference: String?

    enum RamadanDuaOccasion: String, CaseIterable {
        case iftar = "Iftar"
        case suhoor = "Suhoor"
        case taraweeh = "Taraweeh"
        case laylatulQadr = "Laylatul Qadr"

        var iconName: String {
            switch self {
            case .iftar: return "sunset.fill"
            case .suhoor: return "sunrise.fill"
            case .taraweeh: return "moon.stars.fill"
            case .laylatulQadr: return "sparkles"
            }
        }

        var color: Color {
            switch self {
            case .iftar: return .orange
            case .suhoor: return .blue
            case .taraweeh: return .purple
            case .laylatulQadr: return .yellow
            }
        }
    }
}

// MARK: - Ramadan Duas View

struct RamadanDuasView: View {
    @State private var selectedOccasion: RamadanDua.RamadanDuaOccasion = .iftar

    private let duas: [RamadanDua] = RamadanDuasView.allDuas

    var body: some View {
        ScrollView {
            VStack(spacing: SafaSpacing.lg) {
                // Occasion picker
                occasionPicker

                // Duas for selected occasion
                ForEach(filteredDuas) { dua in
                    RamadanDuaCard(dua: dua)
                }
            }
            .padding()
        }
        .navigationTitle("Ramadan Duas")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(UIColor.systemGroupedBackground))
    }

    // MARK: - Occasion Picker

    private var occasionPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: SafaSpacing.sm) {
                ForEach(RamadanDua.RamadanDuaOccasion.allCases, id: \.self) { occasion in
                    occasionButton(occasion)
                }
            }
            .padding(.horizontal, SafaSpacing.xs)
        }
    }

    private func occasionButton(_ occasion: RamadanDua.RamadanDuaOccasion) -> some View {
        Button {
            withAnimation {
                selectedOccasion = occasion
            }
        } label: {
            HStack(spacing: SafaSpacing.xs) {
                Image(systemName: occasion.iconName)
                    .font(.subheadline)

                Text(occasion.rawValue)
                    .font(SafaTypography.labelMedium)
            }
            .padding(.horizontal, SafaSpacing.md)
            .padding(.vertical, SafaSpacing.sm)
            .background(
                selectedOccasion == occasion
                    ? occasion.color
                    : Color(UIColor.secondarySystemBackground)
            )
            .foregroundColor(
                selectedOccasion == occasion
                    ? .white
                    : SafaColors.Fallback.text
            )
            .clipShape(Capsule())
        }
    }

    // MARK: - Filtered Duas

    private var filteredDuas: [RamadanDua] {
        duas.filter { $0.occasion == selectedOccasion }
    }

    // MARK: - All Duas Data

    static let allDuas: [RamadanDua] = [
        // Iftar Duas
        RamadanDua(
            id: "iftar_thirst",
            title: "Dua When Breaking Fast",
            titleArabic: "دعاء الإفطار",
            arabic: "ذَهَبَ الظَّمَأُ وَابْتَلَّتِ الْعُرُوقُ وَثَبَتَ الْأَجْرُ إِنْ شَاءَ اللَّهُ",
            transliteration: "Dhahaba ath-thama'u wab-tallat al-'urooqu wa thabat al-ajru in sha Allah",
            translation: "The thirst has gone, the veins are moistened and the reward is confirmed, if Allah wills.",
            occasion: .iftar,
            reference: "Abu Dawud"
        ),
        RamadanDua(
            id: "iftar_bismillah",
            title: "Before Eating",
            titleArabic: "قبل الأكل",
            arabic: "بِسْمِ اللَّهِ",
            transliteration: "Bismillah",
            translation: "In the name of Allah.",
            occasion: .iftar,
            reference: nil
        ),
        RamadanDua(
            id: "iftar_accepted",
            title: "Asking for Acceptance",
            titleArabic: "طلب القبول",
            arabic: "اللَّهُمَّ لَكَ صُمْتُ وَعَلَى رِزْقِكَ أَفْطَرْتُ",
            transliteration: "Allahumma laka sumtu wa 'ala rizqika aftartu",
            translation: "O Allah, for You I have fasted and upon Your provision I have broken my fast.",
            occasion: .iftar,
            reference: "Abu Dawud"
        ),

        // Suhoor Duas
        RamadanDua(
            id: "suhoor_intention",
            title: "Intention for Fasting",
            titleArabic: "نية الصيام",
            arabic: "نَوَيْتُ صَوْمَ غَدٍ مِنْ شَهْرِ رَمَضَانَ",
            transliteration: "Nawaytu sawma ghadin min shahri Ramadan",
            translation: "I intend to fast tomorrow in the month of Ramadan.",
            occasion: .suhoor,
            reference: nil
        ),
        RamadanDua(
            id: "suhoor_blessing",
            title: "Blessing of Suhoor",
            titleArabic: "بركة السحور",
            arabic: "اللَّهُمَّ بَارِكْ لَنَا فِي السُّحُورِ",
            transliteration: "Allahumma barik lana fis-suhoor",
            translation: "O Allah, bless us in the Suhoor.",
            occasion: .suhoor,
            reference: nil
        ),

        // Taraweeh Duas
        RamadanDua(
            id: "taraweeh_opening",
            title: "Opening Supplication",
            titleArabic: "دعاء الاستفتاح",
            arabic: "سُبْحَانَكَ اللَّهُمَّ وَبِحَمْدِكَ وَتَبَارَكَ اسْمُكَ وَتَعَالَى جَدُّكَ وَلَا إِلَهَ غَيْرُكَ",
            transliteration: "Subhanaka Allahumma wa bihamdika wa tabarakasmuka wa ta'ala jadduka wa la ilaha ghayruk",
            translation: "Glory be to You, O Allah, and praise. Blessed is Your name, exalted is Your majesty, and there is no deity worthy of worship except You.",
            occasion: .taraweeh,
            reference: "Abu Dawud, Tirmidhi"
        ),
        RamadanDua(
            id: "taraweeh_witr",
            title: "Dua Qunoot (Witr)",
            titleArabic: "دعاء القنوت",
            arabic: "اللَّهُمَّ اهْدِنِي فِيمَنْ هَدَيْتَ وَعَافِنِي فِيمَنْ عَافَيْتَ وَتَوَلَّنِي فِيمَنْ تَوَلَّيْتَ وَبَارِكْ لِي فِيمَا أَعْطَيْتَ وَقِنِي شَرَّ مَا قَضَيْتَ إِنَّكَ تَقْضِي وَلَا يُقْضَى عَلَيْكَ",
            transliteration: "Allahumma-hdini fiman hadayt, wa 'afini fiman 'afayt, wa tawallani fiman tawallayt, wa barik li fima a'tayt, wa qini sharra ma qadayt, innaka taqdi wa la yuqda 'alayk",
            translation: "O Allah, guide me among those You have guided, pardon me among those You have pardoned, turn to me among those You have turned, bless me in what You have given, and protect me from the evil of what You have decreed. For You decree and none can decree over You.",
            occasion: .taraweeh,
            reference: "Abu Dawud, Tirmidhi"
        ),

        // Laylatul Qadr Duas
        RamadanDua(
            id: "laylatul_qadr_main",
            title: "Dua for Laylatul Qadr",
            titleArabic: "دعاء ليلة القدر",
            arabic: "اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي",
            transliteration: "Allahumma innaka 'afuwwun tuhibbul 'afwa fa'fu 'anni",
            translation: "O Allah, You are forgiving and love forgiveness, so forgive me.",
            occasion: .laylatulQadr,
            reference: "Tirmidhi - Prophet ﷺ taught this to Aisha (RA)"
        ),
        RamadanDua(
            id: "laylatul_qadr_mercy",
            title: "Seeking Mercy",
            titleArabic: "طلب الرحمة",
            arabic: "اللَّهُمَّ إِنِّي أَسْأَلُكَ الْجَنَّةَ وَأَعُوذُ بِكَ مِنَ النَّارِ",
            transliteration: "Allahumma inni as'alukal-jannata wa a'udhu bika minan-nar",
            translation: "O Allah, I ask You for Paradise and seek refuge in You from the Fire.",
            occasion: .laylatulQadr,
            reference: "Abu Dawud"
        ),
        RamadanDua(
            id: "laylatul_qadr_guidance",
            title: "Seeking Guidance",
            titleArabic: "طلب الهداية",
            arabic: "اللَّهُمَّ اهْدِنِي وَسَدِّدْنِي",
            transliteration: "Allahumma-hdini wa saddidni",
            translation: "O Allah, guide me and keep me on the right path.",
            occasion: .laylatulQadr,
            reference: "Muslim"
        ),
        RamadanDua(
            id: "laylatul_qadr_protection",
            title: "Protection from Evil",
            titleArabic: "الحماية من الشر",
            arabic: "رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ",
            transliteration: "Rabbana atina fid-dunya hasanatan wa fil-akhirati hasanatan wa qina 'adhaban-nar",
            translation: "Our Lord, give us good in this world and good in the Hereafter, and protect us from the punishment of the Fire.",
            occasion: .laylatulQadr,
            reference: "Quran 2:201"
        )
    ]
}

// MARK: - Ramadan Dua Card

struct RamadanDuaCard: View {
    let dua: RamadanDua
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: SafaSpacing.md) {
            // Header
            HStack {
                Image(systemName: dua.occasion.iconName)
                    .foregroundColor(dua.occasion.color)

                VStack(alignment: .leading, spacing: 2) {
                    Text(dua.title)
                        .font(SafaTypography.titleSmall)
                        .foregroundColor(SafaColors.Fallback.text)

                    Text(dua.titleArabic)
                        .font(SafaTypography.arabicSmall)
                        .foregroundColor(SafaColors.Fallback.secondaryText)
                }

                Spacer()

                Button {
                    withAnimation {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(SafaColors.Fallback.tertiaryText)
                }
            }

            // Arabic text
            Text(dua.arabic)
                .font(SafaTypography.arabicMedium)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .foregroundColor(SafaColors.Fallback.text)

            if isExpanded {
                Divider()

                // Transliteration
                VStack(alignment: .leading, spacing: SafaSpacing.xs) {
                    Text("Transliteration")
                        .font(SafaTypography.labelSmall)
                        .foregroundColor(SafaColors.Fallback.tertiaryText)

                    Text(dua.transliteration)
                        .font(SafaTypography.bodyMedium)
                        .italic()
                        .foregroundColor(SafaColors.Fallback.secondaryText)
                }

                // Translation
                VStack(alignment: .leading, spacing: SafaSpacing.xs) {
                    Text("Translation")
                        .font(SafaTypography.labelSmall)
                        .foregroundColor(SafaColors.Fallback.tertiaryText)

                    Text(dua.translation)
                        .font(SafaTypography.bodyMedium)
                        .foregroundColor(SafaColors.Fallback.text)
                }

                // Reference
                if let reference = dua.reference {
                    Text("Source: \(reference)")
                        .font(SafaTypography.labelSmall)
                        .foregroundColor(SafaColors.Fallback.tertiaryText)
                }
            }
        }
        .padding(SafaSpacing.md)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RamadanDuasView()
    }
}
