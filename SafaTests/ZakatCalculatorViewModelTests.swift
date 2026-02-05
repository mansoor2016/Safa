// MARK: - ZakatCalculatorViewModelTests.swift
// PURPOSE: Unit tests for ZakatCalculatorViewModel functionality
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

final class ZakatCalculatorViewModelTests: XCTestCase {

    var sut: ZakatCalculatorViewModel!

    override func setUp() {
        super.setUp()
        sut = ZakatCalculatorViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func test_initialState_allAssetsAreZero() {
        XCTAssertEqual(sut.cashInHand, 0)
        XCTAssertEqual(sut.cashInBank, 0)
        XCTAssertEqual(sut.goldValue, 0)
        XCTAssertEqual(sut.silverValue, 0)
        XCTAssertEqual(sut.stocksValue, 0)
        XCTAssertEqual(sut.businessInventory, 0)
        XCTAssertEqual(sut.investmentProperties, 0)
        XCTAssertEqual(sut.receivables, 0)
        XCTAssertEqual(sut.otherAssets, 0)
    }

    func test_initialState_allLiabilitiesAreZero() {
        XCTAssertEqual(sut.debtsOwed, 0)
        XCTAssertEqual(sut.otherLiabilities, 0)
    }

    func test_initialState_nisabTypeIsGold() {
        XCTAssertEqual(sut.nisabType, .gold)
    }

    func test_initialState_currencyIsUSD() {
        XCTAssertEqual(sut.currency, "USD")
    }

    func test_initialState_totalAssetsIsZero() {
        XCTAssertEqual(sut.totalAssets, 0)
    }

    func test_initialState_totalLiabilitiesIsZero() {
        XCTAssertEqual(sut.totalLiabilities, 0)
    }

    func test_initialState_netZakatableAssetsIsZero() {
        XCTAssertEqual(sut.netZakatableAssets, 0)
    }

    func test_initialState_isNotAboveNisab() {
        XCTAssertFalse(sut.isAboveNisab)
    }

    func test_initialState_zakatAmountIsZero() {
        XCTAssertEqual(sut.zakatAmount, 0)
    }

    // MARK: - Nisab Constants Tests

    func test_goldNisabGramsConstant() {
        XCTAssertEqual(ZakatCalculatorViewModel.goldNisabGrams, 85)
    }

    func test_silverNisabGramsConstant() {
        XCTAssertEqual(ZakatCalculatorViewModel.silverNisabGrams, 595)
    }

    func test_goldPricePerGramConstant() {
        XCTAssertEqual(ZakatCalculatorViewModel.goldPricePerGram, 65)
    }

    func test_silverPricePerGramConstant() {
        XCTAssertEqual(ZakatCalculatorViewModel.silverPricePerGram, 0.80)
    }

    // MARK: - Nisab Calculation Tests

    func test_goldNisab_calculatesCorrectly() {
        // 85 grams * $65/gram = $5,525
        XCTAssertEqual(sut.goldNisab, 5525)
    }

    func test_silverNisab_calculatesCorrectly() {
        // 595 grams * $0.80/gram = $476
        XCTAssertEqual(sut.silverNisab, 476)
    }

    func test_currentNisab_returnsGoldNisab_whenNisabTypeIsGold() {
        sut.nisabType = .gold
        XCTAssertEqual(sut.currentNisab, sut.goldNisab)
    }

    func test_currentNisab_returnsSilverNisab_whenNisabTypeIsSilver() {
        sut.nisabType = .silver
        XCTAssertEqual(sut.currentNisab, sut.silverNisab)
    }

    // MARK: - Total Assets Calculation Tests

    func test_totalAssets_sumsCashCorrectly() {
        sut.cashInHand = 1000
        sut.cashInBank = 5000
        XCTAssertEqual(sut.totalAssets, 6000)
    }

    func test_totalAssets_sumsAllAssetsCorrectly() {
        sut.cashInHand = 1000
        sut.cashInBank = 2000
        sut.goldValue = 3000
        sut.silverValue = 500
        sut.stocksValue = 4000
        sut.businessInventory = 1500
        sut.investmentProperties = 10000
        sut.receivables = 2000
        sut.otherAssets = 1000

        let expectedTotal: Double = 1000 + 2000 + 3000 + 500 + 4000 + 1500 + 10000 + 2000 + 1000
        XCTAssertEqual(sut.totalAssets, expectedTotal)
    }

    // MARK: - Total Liabilities Calculation Tests

    func test_totalLiabilities_sumsCorrectly() {
        sut.debtsOwed = 5000
        sut.otherLiabilities = 2000
        XCTAssertEqual(sut.totalLiabilities, 7000)
    }

    // MARK: - Net Zakatable Assets Tests

    func test_netZakatableAssets_subtractsLiabilitiesFromAssets() {
        sut.cashInBank = 10000
        sut.debtsOwed = 3000
        XCTAssertEqual(sut.netZakatableAssets, 7000)
    }

    func test_netZakatableAssets_neverGoesNegative() {
        sut.cashInBank = 1000
        sut.debtsOwed = 5000
        XCTAssertEqual(sut.netZakatableAssets, 0)
    }

    // MARK: - Above Nisab Tests

    func test_isAboveNisab_returnsFalse_whenBelowGoldNisab() {
        sut.nisabType = .gold
        sut.cashInBank = 5000 // Below gold nisab of $5,525
        XCTAssertFalse(sut.isAboveNisab)
    }

    func test_isAboveNisab_returnsTrue_whenAboveGoldNisab() {
        sut.nisabType = .gold
        sut.cashInBank = 6000 // Above gold nisab of $5,525
        XCTAssertTrue(sut.isAboveNisab)
    }

    func test_isAboveNisab_returnsTrue_whenExactlyAtGoldNisab() {
        sut.nisabType = .gold
        sut.cashInBank = 5525 // Exactly at gold nisab
        XCTAssertTrue(sut.isAboveNisab)
    }

    func test_isAboveNisab_returnsTrue_whenAboveSilverNisab() {
        sut.nisabType = .silver
        sut.cashInBank = 500 // Above silver nisab of $476
        XCTAssertTrue(sut.isAboveNisab)
    }

    func test_isAboveNisab_returnsFalse_whenBelowSilverNisab() {
        sut.nisabType = .silver
        sut.cashInBank = 400 // Below silver nisab of $476
        XCTAssertFalse(sut.isAboveNisab)
    }

    // MARK: - Zakat Amount Calculation Tests

    func test_zakatAmount_isZero_whenBelowNisab() {
        sut.cashInBank = 1000 // Below nisab
        XCTAssertEqual(sut.zakatAmount, 0)
    }

    func test_zakatAmount_is2Point5Percent_whenAboveNisab() {
        sut.cashInBank = 10000
        // 10000 * 0.025 = 250
        XCTAssertEqual(sut.zakatAmount, 250)
    }

    func test_zakatAmount_calculatesCorrectly_withLiabilities() {
        sut.cashInBank = 10000
        sut.debtsOwed = 2000
        // Net = 8000, Zakat = 8000 * 0.025 = 200
        XCTAssertEqual(sut.zakatAmount, 200)
    }

    func test_zakatAmount_isZero_whenLiabilitiesBringBelowNisab() {
        sut.nisabType = .gold
        sut.cashInBank = 6000
        sut.debtsOwed = 2000 // Net = 4000, below gold nisab of 5525
        XCTAssertEqual(sut.zakatAmount, 0)
    }

    func test_zakatAmount_calculatesCorrectly_forLargeAmounts() {
        sut.cashInBank = 100000
        sut.stocksValue = 50000
        sut.investmentProperties = 200000
        // Total = 350000, Zakat = 350000 * 0.025 = 8750
        XCTAssertEqual(sut.zakatAmount, 8750)
    }

    // MARK: - Reset Tests

    func test_reset_clearsAllAssets() {
        sut.cashInHand = 1000
        sut.cashInBank = 2000
        sut.goldValue = 3000
        sut.silverValue = 500
        sut.stocksValue = 4000
        sut.businessInventory = 1500
        sut.investmentProperties = 10000
        sut.receivables = 2000
        sut.otherAssets = 1000

        sut.reset()

        XCTAssertEqual(sut.cashInHand, 0)
        XCTAssertEqual(sut.cashInBank, 0)
        XCTAssertEqual(sut.goldValue, 0)
        XCTAssertEqual(sut.silverValue, 0)
        XCTAssertEqual(sut.stocksValue, 0)
        XCTAssertEqual(sut.businessInventory, 0)
        XCTAssertEqual(sut.investmentProperties, 0)
        XCTAssertEqual(sut.receivables, 0)
        XCTAssertEqual(sut.otherAssets, 0)
    }

    func test_reset_clearsAllLiabilities() {
        sut.debtsOwed = 5000
        sut.otherLiabilities = 2000

        sut.reset()

        XCTAssertEqual(sut.debtsOwed, 0)
        XCTAssertEqual(sut.otherLiabilities, 0)
    }

    func test_reset_doesNotChangeNisabType() {
        sut.nisabType = .silver
        sut.cashInBank = 10000

        sut.reset()

        XCTAssertEqual(sut.nisabType, .silver)
    }

    func test_reset_resultsInZeroZakat() {
        sut.cashInBank = 100000

        sut.reset()

        XCTAssertEqual(sut.zakatAmount, 0)
    }

    // MARK: - NisabType Enum Tests

    func test_nisabType_goldRawValue() {
        XCTAssertEqual(NisabType.gold.rawValue, "Gold")
    }

    func test_nisabType_silverRawValue() {
        XCTAssertEqual(NisabType.silver.rawValue, "Silver")
    }

    func test_nisabType_allCases() {
        XCTAssertEqual(NisabType.allCases.count, 2)
        XCTAssertTrue(NisabType.allCases.contains(.gold))
        XCTAssertTrue(NisabType.allCases.contains(.silver))
    }
}
