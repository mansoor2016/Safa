// MARK: - NamesOfAllahView.swift
// PURPOSE: Display the 99 Names of Allah with meanings
// DEPENDENCIES: SwiftUI

import SwiftUI

// MARK: - Name of Allah Model

struct NameOfAllah: Identifiable, Codable, Hashable {
    let id: Int
    let arabic: String
    let transliteration: String
    let meaning: String
    let explanation: String
}

// MARK: - Names of Allah View Model

@Observable
final class NamesOfAllahViewModel {
    var names: [NameOfAllah] = []
    var searchText = ""
    var selectedName: NameOfAllah?

    var filteredNames: [NameOfAllah] {
        if searchText.isEmpty {
            return names
        }
        return names.filter {
            $0.transliteration.localizedCaseInsensitiveContains(searchText) ||
            $0.meaning.localizedCaseInsensitiveContains(searchText) ||
            $0.arabic.contains(searchText)
        }
    }

    init() {
        loadNames()
    }

    private func loadNames() {
        names = NameOfAllah.allNames
    }
}

// MARK: - Names of Allah View

struct NamesOfAllahView: View {
    @State private var viewModel = NamesOfAllahViewModel()
    @State private var showingDetail = false

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Header
                headerView

                // Search
                searchBar

                // Names Grid
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(viewModel.filteredNames) { name in
                        NameCard(name: name)
                            .onTapGesture {
                                viewModel.selectedName = name
                                showingDetail = true
                            }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 100)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("99 Names of Allah")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingDetail) {
            if let name = viewModel.selectedName {
                NameDetailView(name: name)
                    .compactSheet()
            }
        }
    }

    private var headerView: some View {
        VStack(spacing: 12) {
            Text("أسماء الله الحسنى")
                .font(.system(size: 32, weight: .bold, design: .serif))

            Text("The Most Beautiful Names")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Allah has ninety-nine Names, one-hundred less one; and he who memorizes them all by heart will enter Paradise.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.vertical, 24)
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search names...", text: $viewModel.searchText)
                .textFieldStyle(.plain)

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Name Card

struct NameCard: View {
    let name: NameOfAllah

    var body: some View {
        VStack(spacing: 8) {
            Text(name.arabic)
                .font(.system(size: 28, weight: .bold, design: .serif))

            Text(name.transliteration)
                .font(.subheadline)
                .fontWeight(.medium)

            Text(name.meaning)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

// MARK: - Name Detail View

struct NameDetailView: View {
    let name: NameOfAllah
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Arabic name large
                    Text(name.arabic)
                        .font(.system(size: 72, weight: .bold, design: .serif))
                        .padding(.top, 32)

                    // Transliteration
                    Text(name.transliteration)
                        .font(.title2)
                        .fontWeight(.semibold)

                    // Meaning
                    VStack(spacing: 8) {
                        Text("Meaning")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        Text(name.meaning)
                            .font(.title3)
                            .fontWeight(.medium)
                    }

                    Divider()
                        .padding(.horizontal, 32)

                    // Explanation
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Explanation")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        Text(name.explanation)
                            .font(.body)
                            .lineSpacing(6)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                    // Number badge
                    HStack {
                        Text("#\(name.id)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .cornerRadius(8)
                    }
                    .padding(.top, 16)
                }
                .padding(.bottom, 32)
            }
            .navigationTitle("Name Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Static Names Data

extension NameOfAllah {
    static let allNames: [NameOfAllah] = [
        NameOfAllah(id: 1, arabic: "الرَّحْمَنُ", transliteration: "Ar-Rahman", meaning: "The Most Gracious", explanation: "The One who has plenty of mercy for the believers and the disbelievers in this world and especially for the believers in the hereafter."),
        NameOfAllah(id: 2, arabic: "الرَّحِيمُ", transliteration: "Ar-Raheem", meaning: "The Most Merciful", explanation: "The One who has plenty of mercy for the believers. This mercy is specific to the believers in the hereafter."),
        NameOfAllah(id: 3, arabic: "الْمَلِكُ", transliteration: "Al-Malik", meaning: "The King", explanation: "The One with complete dominion, the One whose dominion is clear from imperfection."),
        NameOfAllah(id: 4, arabic: "الْقُدُّوسُ", transliteration: "Al-Quddus", meaning: "The Most Sacred", explanation: "The One who is pure from any imperfection and clear from children and adversaries."),
        NameOfAllah(id: 5, arabic: "السَّلاَمُ", transliteration: "As-Salam", meaning: "The Source of Peace", explanation: "The One who is free from every imperfection and the source of peace and safety."),
        NameOfAllah(id: 6, arabic: "الْمُؤْمِنُ", transliteration: "Al-Mu'min", meaning: "The Inspirer of Faith", explanation: "The One who gives security and faith to His servants."),
        NameOfAllah(id: 7, arabic: "الْمُهَيْمِنُ", transliteration: "Al-Muhaymin", meaning: "The Guardian", explanation: "The One who watches over and protects all things."),
        NameOfAllah(id: 8, arabic: "الْعَزِيزُ", transliteration: "Al-Aziz", meaning: "The Almighty", explanation: "The One who is Mighty and Powerful, whom nothing can weaken."),
        NameOfAllah(id: 9, arabic: "الْجَبَّارُ", transliteration: "Al-Jabbar", meaning: "The Compeller", explanation: "The One who repairs all broken things and completes that which is incomplete."),
        NameOfAllah(id: 10, arabic: "الْمُتَكَبِّرُ", transliteration: "Al-Mutakabbir", meaning: "The Greatest", explanation: "The One who is clear from the attributes of the creatures and from resembling them."),
        NameOfAllah(id: 11, arabic: "الْخَالِقُ", transliteration: "Al-Khaliq", meaning: "The Creator", explanation: "The One who brings everything from non-existence to existence."),
        NameOfAllah(id: 12, arabic: "الْبَارِئُ", transliteration: "Al-Bari'", meaning: "The Maker", explanation: "The One who creates forms without any example beforehand."),
        NameOfAllah(id: 13, arabic: "الْمُصَوِّرُ", transliteration: "Al-Musawwir", meaning: "The Fashioner", explanation: "The One who forms His creatures in different pictures and shapes."),
        NameOfAllah(id: 14, arabic: "الْغَفَّارُ", transliteration: "Al-Ghaffar", meaning: "The Forgiver", explanation: "The One who forgives the sins of His servants time and time again."),
        NameOfAllah(id: 15, arabic: "الْقَهَّارُ", transliteration: "Al-Qahhar", meaning: "The Subduer", explanation: "The One who has the perfect Power and is not unable over anything."),
        NameOfAllah(id: 16, arabic: "الْوَهَّابُ", transliteration: "Al-Wahhab", meaning: "The Bestower", explanation: "The One who is generous in giving plenty without any return."),
        NameOfAllah(id: 17, arabic: "الرَّزَّاقُ", transliteration: "Ar-Razzaq", meaning: "The Provider", explanation: "The One who creates all means of nourishment and sustenance."),
        NameOfAllah(id: 18, arabic: "الْفَتَّاحُ", transliteration: "Al-Fattah", meaning: "The Opener", explanation: "The One who opens for His servants the closed worldly and religious matters."),
        NameOfAllah(id: 19, arabic: "اَلْعَلِيْمُ", transliteration: "Al-'Alim", meaning: "The All-Knowing", explanation: "The One who knows everything, past, present, and future."),
        NameOfAllah(id: 20, arabic: "الْقَابِضُ", transliteration: "Al-Qabid", meaning: "The Constrictor", explanation: "The One who constricts the sustenance by His wisdom."),
        NameOfAllah(id: 21, arabic: "الْبَاسِطُ", transliteration: "Al-Basit", meaning: "The Reliever", explanation: "The One who extends His generosity and mercy to whom He wills."),
        NameOfAllah(id: 22, arabic: "الْخَافِضُ", transliteration: "Al-Khafid", meaning: "The Abaser", explanation: "The One who lowers whoever He wills by His destruction."),
        NameOfAllah(id: 23, arabic: "الرَّافِعُ", transliteration: "Ar-Rafi'", meaning: "The Exalter", explanation: "The One who raises whoever He wills by His honoring."),
        NameOfAllah(id: 24, arabic: "الْمُعِزُّ", transliteration: "Al-Mu'izz", meaning: "The Bestower of Honors", explanation: "The One who gives esteem to whoever He wills."),
        NameOfAllah(id: 25, arabic: "المُذِلُّ", transliteration: "Al-Mudhill", meaning: "The Humiliator", explanation: "The One who humiliates and disgraces whoever He wills."),
        NameOfAllah(id: 26, arabic: "السَّمِيعُ", transliteration: "As-Sami'", meaning: "The All-Hearing", explanation: "The One who hears all things that are heard by His eternal hearing."),
        NameOfAllah(id: 27, arabic: "الْبَصِيرُ", transliteration: "Al-Basir", meaning: "The All-Seeing", explanation: "The One who sees all things that are seen by His eternal seeing."),
        NameOfAllah(id: 28, arabic: "الْحَكَمُ", transliteration: "Al-Hakam", meaning: "The Judge", explanation: "The One who judges between His servants with truth and justice."),
        NameOfAllah(id: 29, arabic: "الْعَدْلُ", transliteration: "Al-'Adl", meaning: "The Just", explanation: "The One who is entitled to do what He does in the way He does it."),
        NameOfAllah(id: 30, arabic: "اللَّطِيفُ", transliteration: "Al-Latif", meaning: "The Subtle One", explanation: "The One who is kind to His servants and bestows upon them."),
        NameOfAllah(id: 31, arabic: "الْخَبِيرُ", transliteration: "Al-Khabir", meaning: "The All-Aware", explanation: "The One who knows the inner truths and hidden secrets of all things."),
        NameOfAllah(id: 32, arabic: "الْحَلِيمُ", transliteration: "Al-Halim", meaning: "The Forbearing", explanation: "The One who delays punishment for those who deserve it."),
        NameOfAllah(id: 33, arabic: "الْعَظِيمُ", transliteration: "Al-'Azim", meaning: "The Magnificent", explanation: "The One deserving the attributes of greatness and glory."),
        NameOfAllah(id: 34, arabic: "الْغَفُورُ", transliteration: "Al-Ghafur", meaning: "The All-Forgiving", explanation: "The One who forgives a lot, covering sins of His servants."),
        NameOfAllah(id: 35, arabic: "الشَّكُورُ", transliteration: "Ash-Shakur", meaning: "The Most Appreciative", explanation: "The One who gives great rewards for small deeds."),
        NameOfAllah(id: 36, arabic: "الْعَلِيُّ", transliteration: "Al-'Ali", meaning: "The Most High", explanation: "The One who is high above all of His creation."),
        NameOfAllah(id: 37, arabic: "الْكَبِيرُ", transliteration: "Al-Kabir", meaning: "The Greatest", explanation: "The One who is greater than everything in status."),
        NameOfAllah(id: 38, arabic: "الْحَفِيظُ", transliteration: "Al-Hafiz", meaning: "The Preserver", explanation: "The One who protects whatever and whoever He wills."),
        NameOfAllah(id: 39, arabic: "المُقيِت", transliteration: "Al-Muqit", meaning: "The Nourisher", explanation: "The One who has the power over all things."),
        NameOfAllah(id: 40, arabic: "الْحسِيبُ", transliteration: "Al-Hasib", meaning: "The Reckoner", explanation: "The One who gives satisfaction and is sufficient for His servants."),
        NameOfAllah(id: 41, arabic: "الْجَلِيلُ", transliteration: "Al-Jalil", meaning: "The Majestic", explanation: "The One who is attributed with greatness of power and glory."),
        NameOfAllah(id: 42, arabic: "الْكَرِيمُ", transliteration: "Al-Karim", meaning: "The Most Generous", explanation: "The One who is generous and gives without being asked."),
        NameOfAllah(id: 43, arabic: "الرَّقِيبُ", transliteration: "Ar-Raqib", meaning: "The Watchful", explanation: "The One who watches all things and from whom nothing is absent."),
        NameOfAllah(id: 44, arabic: "الْمُجِيبُ", transliteration: "Al-Mujib", meaning: "The Responsive", explanation: "The One who answers the one in need when called upon."),
        NameOfAllah(id: 45, arabic: "الْوَاسِعُ", transliteration: "Al-Wasi'", meaning: "The All-Encompassing", explanation: "The One whose knowledge and mercy encompass all things."),
        NameOfAllah(id: 46, arabic: "الْحَكِيمُ", transliteration: "Al-Hakim", meaning: "The All-Wise", explanation: "The One who is correct in His doings and sayings."),
        NameOfAllah(id: 47, arabic: "الْوَدُودُ", transliteration: "Al-Wadud", meaning: "The Most Loving", explanation: "The One who loves His believing servants and they love Him."),
        NameOfAllah(id: 48, arabic: "الْمَجِيدُ", transliteration: "Al-Majid", meaning: "The Most Glorious", explanation: "The One who is with perfect power, high status, and generosity."),
        NameOfAllah(id: 49, arabic: "الْبَاعِثُ", transliteration: "Al-Ba'ith", meaning: "The Resurrector", explanation: "The One who resurrects His servants after death for reward."),
        NameOfAllah(id: 50, arabic: "الشَّهِيدُ", transliteration: "Ash-Shahid", meaning: "The Witness", explanation: "The One who nothing is absent from Him."),
        // Continuing with remaining names...
        NameOfAllah(id: 51, arabic: "الْحَقُّ", transliteration: "Al-Haqq", meaning: "The Truth", explanation: "The One whose existence is the only true existence."),
        NameOfAllah(id: 52, arabic: "الْوَكِيلُ", transliteration: "Al-Wakil", meaning: "The Trustee", explanation: "The One who gives the satisfaction and is relied upon."),
        NameOfAllah(id: 53, arabic: "الْقَوِيُّ", transliteration: "Al-Qawiyy", meaning: "The Possessor of All Strength", explanation: "The One with complete power, whose strength has no weakness."),
        NameOfAllah(id: 54, arabic: "الْمَتِينُ", transliteration: "Al-Matin", meaning: "The Firm", explanation: "The One with extreme power which is not diminished."),
        NameOfAllah(id: 55, arabic: "الْوَلِيُّ", transliteration: "Al-Wali", meaning: "The Protecting Friend", explanation: "The One who supports His righteous servants."),
        NameOfAllah(id: 56, arabic: "الْحَمِيدُ", transliteration: "Al-Hamid", meaning: "The Praiseworthy", explanation: "The One who is praised and thanked for His goodness."),
        NameOfAllah(id: 57, arabic: "الْمُحْصِي", transliteration: "Al-Muhsi", meaning: "The Appraiser", explanation: "The One who knows the count of everything."),
        NameOfAllah(id: 58, arabic: "الْمُبْدِئُ", transliteration: "Al-Mubdi'", meaning: "The Originator", explanation: "The One who started the human being by creating them first."),
        NameOfAllah(id: 59, arabic: "الْمُعِيدُ", transliteration: "Al-Mu'id", meaning: "The Restorer", explanation: "The One who brings back creatures after death."),
        NameOfAllah(id: 60, arabic: "الْمُحْيِي", transliteration: "Al-Muhyi", meaning: "The Giver of Life", explanation: "The One who gave life to all living things."),
        NameOfAllah(id: 61, arabic: "اَلْمُمِيتُ", transliteration: "Al-Mumit", meaning: "The Taker of Life", explanation: "The One who renders the living dead."),
        NameOfAllah(id: 62, arabic: "الْحَيُّ", transliteration: "Al-Hayy", meaning: "The Ever Living", explanation: "The One attributed with a life that has no death."),
        NameOfAllah(id: 63, arabic: "الْقَيُّومُ", transliteration: "Al-Qayyum", meaning: "The Self-Existing", explanation: "The One who remains and does not end."),
        NameOfAllah(id: 64, arabic: "الْوَاجِدُ", transliteration: "Al-Wajid", meaning: "The Finder", explanation: "The One who is not lacking anything."),
        NameOfAllah(id: 65, arabic: "الْمَاجِدُ", transliteration: "Al-Majid", meaning: "The Glorious", explanation: "The One with perfect power, high status, and bountiful."),
        NameOfAllah(id: 66, arabic: "الْواحِدُ", transliteration: "Al-Wahid", meaning: "The One", explanation: "The One without a partner."),
        NameOfAllah(id: 67, arabic: "اَلاَحَدُ", transliteration: "Al-Ahad", meaning: "The Unique", explanation: "The One who is singular and has no equal."),
        NameOfAllah(id: 68, arabic: "الصَّمَدُ", transliteration: "As-Samad", meaning: "The Eternal", explanation: "The One to whom all creation turns for their needs."),
        NameOfAllah(id: 69, arabic: "الْقَادِرُ", transliteration: "Al-Qadir", meaning: "The Capable", explanation: "The One who is able to do whatever He wills."),
        NameOfAllah(id: 70, arabic: "الْمُقْتَدِرُ", transliteration: "Al-Muqtadir", meaning: "The Powerful", explanation: "The One with perfect power that nothing is withheld from Him."),
        NameOfAllah(id: 71, arabic: "الْمُقَدِّمُ", transliteration: "Al-Muqaddim", meaning: "The Expediter", explanation: "The One who puts things in their right places."),
        NameOfAllah(id: 72, arabic: "الْمُؤَخِّرُ", transliteration: "Al-Mu'akhkhir", meaning: "The Delayer", explanation: "The One who delays what He wills."),
        NameOfAllah(id: 73, arabic: "الأوَّلُ", transliteration: "Al-Awwal", meaning: "The First", explanation: "The One whose existence is without a beginning."),
        NameOfAllah(id: 74, arabic: "الآخِرُ", transliteration: "Al-Akhir", meaning: "The Last", explanation: "The One whose existence is without an end."),
        NameOfAllah(id: 75, arabic: "الظَّاهِرُ", transliteration: "Az-Zahir", meaning: "The Manifest", explanation: "The One whose existence is clear by proofs."),
        NameOfAllah(id: 76, arabic: "الْبَاطِنُ", transliteration: "Al-Batin", meaning: "The Hidden", explanation: "The One who is hidden from the creation's perception."),
        NameOfAllah(id: 77, arabic: "الْوَالِي", transliteration: "Al-Wali", meaning: "The Governor", explanation: "The One who owns everything and has power over it."),
        NameOfAllah(id: 78, arabic: "الْمُتَعَالِي", transliteration: "Al-Muta'ali", meaning: "The Most Exalted", explanation: "The One who is clear from the attributes of the creation."),
        NameOfAllah(id: 79, arabic: "الْبَرُّ", transliteration: "Al-Barr", meaning: "The Source of Goodness", explanation: "The One who is kind to His creatures."),
        NameOfAllah(id: 80, arabic: "التَّوَّابُ", transliteration: "At-Tawwab", meaning: "The Acceptor of Repentance", explanation: "The One who grants repentance and accepts it."),
        NameOfAllah(id: 81, arabic: "الْمُنْتَقِمُ", transliteration: "Al-Muntaqim", meaning: "The Avenger", explanation: "The One who victoriously prevails over His enemies."),
        NameOfAllah(id: 82, arabic: "العَفُوُّ", transliteration: "Al-'Afuww", meaning: "The Pardoner", explanation: "The One with wide forgiveness who erases sins."),
        NameOfAllah(id: 83, arabic: "الرَّؤُوفُ", transliteration: "Ar-Ra'uf", meaning: "The Most Kind", explanation: "The One with extreme mercy."),
        NameOfAllah(id: 84, arabic: "مَالِكُ الْمُلْكِ", transliteration: "Malik-ul-Mulk", meaning: "Owner of Sovereignty", explanation: "The One who controls the dominion and gives it to whoever He wills."),
        NameOfAllah(id: 85, arabic: "ذُوالْجَلاَلِ وَالإكْرَامِ", transliteration: "Dhul-Jalali Wal-Ikram", meaning: "Lord of Majesty and Bounty", explanation: "The One who deserves to be exalted and not denied."),
        NameOfAllah(id: 86, arabic: "الْمُقْسِطُ", transliteration: "Al-Muqsit", meaning: "The Equitable", explanation: "The One who is just in His judgment."),
        NameOfAllah(id: 87, arabic: "الْجَامِعُ", transliteration: "Al-Jami'", meaning: "The Gatherer", explanation: "The One who gathers creatures on a day there is no doubt about."),
        NameOfAllah(id: 88, arabic: "الْغَنِيُّ", transliteration: "Al-Ghaniyy", meaning: "The Self-Sufficient", explanation: "The One who does not need any of His creatures."),
        NameOfAllah(id: 89, arabic: "الْمُغْنِي", transliteration: "Al-Mughni", meaning: "The Enricher", explanation: "The One who satisfies the necessities of creatures."),
        NameOfAllah(id: 90, arabic: "اَلْمَانِعُ", transliteration: "Al-Mani'", meaning: "The Preventer", explanation: "The One who prevents whatever He wills from whomever He wills."),
        NameOfAllah(id: 91, arabic: "الضَّارَّ", transliteration: "Ad-Darr", meaning: "The Creator of Harm", explanation: "The One who makes harm reach whoever He wills."),
        NameOfAllah(id: 92, arabic: "النَّافِعُ", transliteration: "An-Nafi'", meaning: "The Creator of Good", explanation: "The One who makes benefit reach whoever He wills."),
        NameOfAllah(id: 93, arabic: "النُّورُ", transliteration: "An-Nur", meaning: "The Light", explanation: "The One who guides and gives light to all creation."),
        NameOfAllah(id: 94, arabic: "الْهَادِي", transliteration: "Al-Hadi", meaning: "The Guide", explanation: "The One who guides His servants to His obedience."),
        NameOfAllah(id: 95, arabic: "الْبَدِيعُ", transliteration: "Al-Badi'", meaning: "The Originator", explanation: "The One who created the creation with no preceding example."),
        NameOfAllah(id: 96, arabic: "اَلْبَاقِي", transliteration: "Al-Baqi", meaning: "The Everlasting", explanation: "The One whose existence has no end."),
        NameOfAllah(id: 97, arabic: "الْوَارِثُ", transliteration: "Al-Warith", meaning: "The Inheritor", explanation: "The One whose existence remains when all else perishes."),
        NameOfAllah(id: 98, arabic: "الرَّشِيدُ", transliteration: "Ar-Rashid", meaning: "The Guide to the Right Path", explanation: "The One who guides creation to that which benefits them."),
        NameOfAllah(id: 99, arabic: "الصَّبُورُ", transliteration: "As-Sabur", meaning: "The Patient", explanation: "The One who does not punish sinners immediately.")
    ]
}

#Preview {
    NavigationStack {
        NamesOfAllahView()
    }
}
