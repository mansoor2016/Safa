// MARK: - ZakatCalculatorView.swift
// PURPOSE: Calculate Zakat based on various asset types
// DEPENDENCIES: SwiftUI

import SwiftUI

// MARK: - Zakat Calculator View Model

@Observable
final class ZakatCalculatorViewModel {
    // Asset values
    var cashInHand: Double = 0
    var cashInBank: Double = 0
    var goldValue: Double = 0
    var silverValue: Double = 0
    var stocksValue: Double = 0
    var businessInventory: Double = 0
    var investmentProperties: Double = 0
    var receivables: Double = 0
    var otherAssets: Double = 0

    // Liabilities
    var debtsOwed: Double = 0
    var otherLiabilities: Double = 0

    // Settings
    var nisabType: NisabType = .gold
    var currency: String = "USD"

    // Nisab thresholds
    static let goldNisabGrams: Double = 85 // 85 grams of gold
    static let silverNisabGrams: Double = 595 // 595 grams of silver

    // Adjustable price per gram (defaults are approximate USD)
    var goldPricePerGram: Double = 65
    var silverPricePerGram: Double = 0.80

    var goldNisab: Double {
        Self.goldNisabGrams * goldPricePerGram
    }

    var silverNisab: Double {
        Self.silverNisabGrams * silverPricePerGram
    }

    var currentNisab: Double {
        nisabType == .gold ? goldNisab : silverNisab
    }

    var totalAssets: Double {
        cashInHand + cashInBank + goldValue + silverValue +
        stocksValue + businessInventory + investmentProperties +
        receivables + otherAssets
    }

    var totalLiabilities: Double {
        debtsOwed + otherLiabilities
    }

    var netZakatableAssets: Double {
        max(0, totalAssets - totalLiabilities)
    }

    var isAboveNisab: Bool {
        netZakatableAssets >= currentNisab
    }

    var zakatAmount: Double {
        guard isAboveNisab else { return 0 }
        return netZakatableAssets * 0.025 // 2.5%
    }

    func reset() {
        cashInHand = 0
        cashInBank = 0
        goldValue = 0
        silverValue = 0
        stocksValue = 0
        businessInventory = 0
        investmentProperties = 0
        receivables = 0
        otherAssets = 0
        debtsOwed = 0
        otherLiabilities = 0
        goldPricePerGram = 65
        silverPricePerGram = 0.80
    }
}

enum NisabType: String, CaseIterable {
    case gold = "Gold"
    case silver = "Silver"
}

// MARK: - Zakat Calculator View

struct ZakatCalculatorView: View {
    @State private var viewModel = ZakatCalculatorViewModel()
    @State private var showingInfo = false
    @State private var selectedSection: ZakatSection = .assets

    enum ZakatSection: String, CaseIterable {
        case assets = "Assets"
        case liabilities = "Liabilities"
        case result = "Result"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                headerView

                // Nisab Selector
                nisabSelector

                // Section Picker
                Picker("Section", selection: $selectedSection) {
                    ForEach(ZakatSection.allCases, id: \.self) { section in
                        Text(section.rawValue).tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Content based on section
                switch selectedSection {
                case .assets:
                    assetsSection
                case .liabilities:
                    liabilitiesSection
                case .result:
                    resultSection
                }
            }
            .padding(.bottom, 100)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Zakat Calculator")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingInfo = true
                } label: {
                    Image(systemName: "info.circle")
                }
            }
        }
        .sheet(isPresented: $showingInfo) {
            ZakatInfoSheet()
                .compactSheet()
        }
    }

    private var headerView: some View {
        VStack(spacing: 8) {
            Image(systemName: "banknote")
                .font(.system(size: 40))
                .foregroundColor(.green)

            Text("Calculate Your Zakat")
                .font(.title2)
                .fontWeight(.bold)

            Text("Enter your assets and liabilities to calculate the Zakat due")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical)
    }

    private var nisabSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Nisab Threshold")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            HStack {
                ForEach(NisabType.allCases, id: \.self) { type in
                    Button {
                        viewModel.nisabType = type
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: type == .gold ? "bitcoinsign.circle" : "circle.circle")
                                .font(.title2)
                            Text(type.rawValue)
                                .font(.caption)
                            Text(formatCurrency(type == .gold ? viewModel.goldNisab : viewModel.silverNisab))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.nisabType == type ? Color.accentColor.opacity(0.1) : Color(.secondarySystemGroupedBackground))
                        .foregroundColor(viewModel.nisabType == type ? .accentColor : .primary)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Editable price per gram for selected nisab type
            HStack {
                Text(viewModel.nisabType == .gold ? "Gold price per gram" : "Silver price per gram")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                TextField(
                    "0",
                    value: viewModel.nisabType == .gold
                        ? $viewModel.goldPricePerGram
                        : $viewModel.silverPricePerGram,
                    format: .currency(code: viewModel.currency)
                )
                .textFieldStyle(.plain)
                .multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad)
                .frame(width: 120)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(8)
        }
        .padding(.horizontal)
    }

    private var assetsSection: some View {
        VStack(spacing: 16) {
            AssetInputGroup(title: "Cash") {
                CurrencyInputRow(label: "Cash in Hand", value: $viewModel.cashInHand)
                CurrencyInputRow(label: "Cash in Bank", value: $viewModel.cashInBank)
            }

            AssetInputGroup(title: "Precious Metals") {
                CurrencyInputRow(label: "Gold Value", value: $viewModel.goldValue)
                CurrencyInputRow(label: "Silver Value", value: $viewModel.silverValue)
            }

            AssetInputGroup(title: "Investments") {
                CurrencyInputRow(label: "Stocks & Shares", value: $viewModel.stocksValue)
                CurrencyInputRow(label: "Investment Properties", value: $viewModel.investmentProperties)
            }

            AssetInputGroup(title: "Business") {
                CurrencyInputRow(label: "Business Inventory", value: $viewModel.businessInventory)
                CurrencyInputRow(label: "Receivables", value: $viewModel.receivables)
            }

            AssetInputGroup(title: "Other") {
                CurrencyInputRow(label: "Other Zakatable Assets", value: $viewModel.otherAssets)
            }
        }
        .padding(.horizontal)
    }

    private var liabilitiesSection: some View {
        VStack(spacing: 16) {
            AssetInputGroup(title: "Debts") {
                CurrencyInputRow(label: "Debts Owed", value: $viewModel.debtsOwed)
                CurrencyInputRow(label: "Other Liabilities", value: $viewModel.otherLiabilities)
            }

            // Info card
            VStack(alignment: .leading, spacing: 8) {
                Label("Deductible Liabilities", systemImage: "info.circle")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("You can deduct immediate debts and expenses that are due within the year from your total assets.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }

    private var resultSection: some View {
        VStack(spacing: 20) {
            // Summary card
            VStack(spacing: 16) {
                SummaryRow(label: "Total Assets", value: viewModel.totalAssets, color: .primary)
                SummaryRow(label: "Total Liabilities", value: viewModel.totalLiabilities, color: .red)
                Divider()
                SummaryRow(label: "Net Zakatable Wealth", value: viewModel.netZakatableAssets, color: .primary, isLarge: true)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)

            // Nisab status
            HStack {
                Image(systemName: viewModel.isAboveNisab ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(viewModel.isAboveNisab ? .green : .orange)

                Text(viewModel.isAboveNisab ? "Above Nisab threshold" : "Below Nisab threshold")
                    .font(.subheadline)

                Spacer()

                Text(formatCurrency(viewModel.currentNisab))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)

            // Zakat amount
            if viewModel.isAboveNisab {
                VStack(spacing: 12) {
                    Text("Zakat Due (2.5%)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(formatCurrency(viewModel.zakatAmount))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.green)

                    Text("May Allah accept your Zakat")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 24)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)

                    Text("No Zakat Due")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Your wealth is below the Nisab threshold. Zakat is not obligatory, but voluntary charity (Sadaqah) is always encouraged.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 24)
            }

            // Reset button
            Button {
                viewModel.reset()
            } label: {
                Label("Reset Calculator", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = viewModel.currency
        return formatter.string(from: NSNumber(value: value)) ?? "$\(value)"
    }
}

// MARK: - Supporting Views

struct AssetInputGroup<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            VStack(spacing: 8) {
                content
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
}

struct CurrencyInputRow: View {
    let label: String
    @Binding var value: Double

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)

            Spacer()

            TextField("0", value: $value, format: .currency(code: "USD"))
                .textFieldStyle(.plain)
                .multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad)
                .frame(width: 120)
        }
    }
}

struct SummaryRow: View {
    let label: String
    let value: Double
    let color: Color
    var isLarge: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .font(isLarge ? .headline : .subheadline)

            Spacer()

            Text(formatCurrency(value))
                .font(isLarge ? .title3 : .subheadline)
                .fontWeight(isLarge ? .bold : .regular)
                .foregroundColor(color)
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$\(value)"
    }
}

// MARK: - Zakat Info Sheet

struct ZakatInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // What is Zakat
                    InfoSection(title: "What is Zakat?") {
                        Text("Zakat is one of the Five Pillars of Islam. It is a mandatory charitable contribution, typically 2.5% of a Muslim's total savings and wealth above a minimum amount known as Nisab.")
                    }

                    // Nisab
                    InfoSection(title: "What is Nisab?") {
                        Text("Nisab is the minimum amount of wealth a Muslim must possess before they become eligible to pay Zakat. It is calculated based on the value of either 85 grams of gold or 595 grams of silver.")
                    }

                    // Who should pay
                    InfoSection(title: "Who Should Pay?") {
                        Text("Zakat is obligatory on every adult Muslim who possesses wealth above the Nisab threshold for a full lunar year (Hawl).")
                    }

                    // What is Zakatable
                    InfoSection(title: "Zakatable Assets") {
                        VStack(alignment: .leading, spacing: 8) {
                            BulletPoint(text: "Cash (in hand and bank accounts)")
                            BulletPoint(text: "Gold and silver")
                            BulletPoint(text: "Stocks and investments")
                            BulletPoint(text: "Business inventory")
                            BulletPoint(text: "Rental income from investment properties")
                            BulletPoint(text: "Loans given (that are expected to be repaid)")
                        }
                    }

                    // What is not Zakatable
                    InfoSection(title: "Non-Zakatable Assets") {
                        VStack(alignment: .leading, spacing: 8) {
                            BulletPoint(text: "Primary residence")
                            BulletPoint(text: "Personal vehicle")
                            BulletPoint(text: "Household furniture and items")
                            BulletPoint(text: "Personal clothing")
                        }
                    }

                    // Disclaimer
                    Text("Note: This calculator provides an estimate. For complex financial situations, please consult a qualified Islamic scholar.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color(.tertiarySystemGroupedBackground))
                        .cornerRadius(8)
                }
                .padding()
            }
            .navigationTitle("About Zakat")
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

struct InfoSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            content
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct BulletPoint: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
            Text(text)
        }
    }
}

#Preview {
    NavigationStack {
        ZakatCalculatorView()
    }
}
