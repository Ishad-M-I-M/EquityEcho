import 'package:flutter_test/flutter_test.dart';
import 'package:equity_echo/core/utils/return_calculator.dart';

void main() {
  group('ReturnCalculator.compute', () {
    test('new purchase applies CSE charges on both buy and sell legs', () {
      final r = ReturnCalculator.compute(
        quantity: 100,
        buyPrice: 10,
        sellPrice: 15,
        buyDate: DateTime(2023, 1, 1),
        sellDate: DateTime(2024, 1, 1),
      );

      // Buy: 1000 + 1.12% = 1011.2
      expect(r.buyValue, closeTo(1000, 1e-9));
      expect(r.totalBuyCost, closeTo(1011.2, 1e-9));
      expect(r.buyCharges, closeTo(11.2, 1e-9));

      // Sell: 1500 - 1.12% = 1483.2
      expect(r.sellValue, closeTo(1500, 1e-9));
      expect(r.netProceeds, closeTo(1483.2, 1e-9));
      expect(r.sellCharges, closeTo(16.8, 1e-9));

      expect(r.netGain, closeTo(472.0, 1e-9));
      expect(r.returnPct, closeTo(46.6772, 1e-3));
      expect(r.isProfit, isTrue);
    });

    test('existing holding does not re-apply buy charges', () {
      final r = ReturnCalculator.compute(
        quantity: 50,
        buyPrice: 20, // avg cost already incl. charges
        sellPrice: 25,
        buyDate: DateTime(2023, 1, 1),
        sellDate: DateTime(2024, 1, 1),
        buyPriceIncludesCharges: true,
      );

      expect(r.buyCharges, closeTo(0, 1e-9));
      expect(r.totalBuyCost, closeTo(1000, 1e-9)); // 50 * 20
      // Sell still charged: 1250 - 1.12% = 1236.0
      expect(r.netProceeds, closeTo(1236.0, 1e-9));
      expect(r.netGain, closeTo(236.0, 1e-9));
    });

    test('loss scenario reports negative gain and isProfit false', () {
      final r = ReturnCalculator.compute(
        quantity: 100,
        buyPrice: 50,
        sellPrice: 40,
        buyDate: DateTime(2023, 1, 1),
        sellDate: DateTime(2023, 6, 1),
      );

      expect(r.netGain, lessThan(0));
      expect(r.returnPct, lessThan(0));
      expect(r.isProfit, isFalse);
      expect(r.annualizedPct, isNotNull);
      expect(r.annualizedPct, lessThan(0));
    });

    test('annualized return (CAGR) for a doubling over ~2 years', () {
      final r = ReturnCalculator.compute(
        quantity: 100,
        buyPrice: 10,
        sellPrice: 20,
        buyDate: DateTime(2022, 1, 1),
        sellDate: DateTime(2024, 1, 1), // 730 days
        buyPriceIncludesCharges: true,
        applySellCharges: false,
      );

      expect(r.totalBuyCost, closeTo(1000, 1e-9));
      expect(r.netProceeds, closeTo(2000, 1e-9));
      expect(r.returnPct, closeTo(100, 1e-9));
      // CAGR of a 2x over ~2 years ≈ 41.4% p.a.
      expect(r.annualizedPct, isNotNull);
      expect(r.annualizedPct, closeTo(41.45, 0.5));
    });

    test('annualized is null for a same-day sale', () {
      final r = ReturnCalculator.compute(
        quantity: 100,
        buyPrice: 10,
        sellPrice: 12,
        buyDate: DateTime(2024, 1, 1),
        sellDate: DateTime(2024, 1, 1),
      );

      expect(r.holdingDays, 0);
      expect(r.annualizedPct, isNull);
    });

    test('applySellCharges=false keeps full sell proceeds', () {
      final r = ReturnCalculator.compute(
        quantity: 10,
        buyPrice: 100,
        sellPrice: 120,
        buyDate: DateTime(2023, 1, 1),
        sellDate: DateTime(2023, 7, 1),
        applySellCharges: false,
      );

      expect(r.sellCharges, closeTo(0, 1e-9));
      expect(r.netProceeds, closeTo(1200, 1e-9));
    });

    test('same-day buy & sell exempts the sell leg (STL only)', () {
      final r = ReturnCalculator.compute(
        quantity: 100,
        buyPrice: 10,
        sellPrice: 12,
        buyDate: DateTime(2024, 3, 5, 9, 30),
        sellDate: DateTime(2024, 3, 5, 14, 45),
      );

      expect(r.intraDayExempt, isTrue);
      // Buy leg keeps full charges: 1000 + 1.12% = 1011.2
      expect(r.totalBuyCost, closeTo(1011.2, 1e-9));
      // Sell leg STL only: 1200 - 0.300% = 1196.4 (charges = 3.6)
      expect(r.sellCharges, closeTo(3.6, 1e-9));
      expect(r.netProceeds, closeTo(1196.4, 1e-9));
      expect(r.netGain, closeTo(185.2, 1e-9));
      expect(r.annualizedPct, isNull); // 0-day holding period
    });

    test('different days do NOT trigger the intra-day exemption', () {
      final r = ReturnCalculator.compute(
        quantity: 100,
        buyPrice: 10,
        sellPrice: 12,
        buyDate: DateTime(2024, 3, 5),
        sellDate: DateTime(2024, 3, 6),
      );

      expect(r.intraDayExempt, isFalse);
      // Full sell charges: 1200 - 1.12% = 1186.56 (charges = 13.44)
      expect(r.sellCharges, closeTo(13.44, 1e-9));
      expect(r.netProceeds, closeTo(1186.56, 1e-9));
    });
  });
}
