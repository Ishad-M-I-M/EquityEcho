/// CSE Transaction Charges (Below Rs. 100 Million)
///
/// Applied to all BUY and SELL trades EXCEPT IPO purchases.
class TransactionCharges {
  /// Brokerage Fee rate: 0.640%
  static const double brokerageFeeRate = 0.00640;

  /// CSE Fees rate: 0.084%
  static const double cseFeeRate = 0.00084;

  /// CDS (Central Depository Systems) Fee rate: 0.024%
  static const double cdsFeeRate = 0.00024;

  /// SEC Cess (Securities and Exchange Commission) rate: 0.072%
  static const double secCessRate = 0.00072;

  /// Share Transaction Levy rate: 0.300%
  static const double shareTransactionLevyRate = 0.00300;

  /// Total combined rate: 1.120%
  static const double totalRate = 0.01120;

  /// Total cost of a BUY = trade value + charges.
  /// For IPO buys (isIpo=true), returns raw trade value.
  static double buyCost(double tradeValue, {bool isIpo = false}) {
    return isIpo ? tradeValue : tradeValue * (1 + totalRate);
  }

  /// Net proceeds of a SELL = trade value − charges.
  /// Sells always have charges (even for shares originally bought via IPO).
  static double sellProceeds(double tradeValue) {
    return tradeValue * (1 - totalRate);
  }

  /// Compute the full charges breakdown for a given trade value.
  /// Returns a [ChargesBreakdown] with all individual fees and totals.
  static ChargesBreakdown compute(double tradeValue) {
    final brokerageFee = tradeValue * brokerageFeeRate;
    final cseFee = tradeValue * cseFeeRate;
    final cdsFee = tradeValue * cdsFeeRate;
    final secCess = tradeValue * secCessRate;
    final shareTransactionLevy = tradeValue * shareTransactionLevyRate;
    final totalCharges = tradeValue * totalRate;

    return ChargesBreakdown(
      tradeValue: tradeValue,
      brokerageFee: brokerageFee,
      cseFee: cseFee,
      cdsFee: cdsFee,
      secCess: secCess,
      shareTransactionLevy: shareTransactionLevy,
      totalCharges: totalCharges,
      grandTotal: tradeValue + totalCharges,
    );
  }
}

/// Holds a full breakdown of CSE transaction charges for a trade.
class ChargesBreakdown {
  /// The raw trade value (quantity × price), before charges.
  final double tradeValue;

  /// Brokerage fee (0.640% of trade value).
  final double brokerageFee;

  /// CSE Fees (0.084% of trade value).
  final double cseFee;

  /// CDS Fees (0.024% of trade value).
  final double cdsFee;

  /// SEC Cess (0.072% of trade value).
  final double secCess;

  /// Share Transaction Levy (0.300% of trade value).
  final double shareTransactionLevy;

  /// Total of all charges (1.120% of trade value).
  final double totalCharges;

  /// Grand total = trade value + all charges.
  final double grandTotal;

  const ChargesBreakdown({
    required this.tradeValue,
    required this.brokerageFee,
    required this.cseFee,
    required this.cdsFee,
    required this.secCess,
    required this.shareTransactionLevy,
    required this.totalCharges,
    required this.grandTotal,
  });
}
