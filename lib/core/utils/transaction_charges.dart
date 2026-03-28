/// CSE Transaction Charges (Below Rs. 100 Million)
///
/// Applied to all BUY and SELL trades EXCEPT IPO purchases.
///
/// **Intra-day exemption**: When a client buys and sells the same security
/// on the same day through the same broker, the side with the lower quantity
/// (or the sell side if equal) is exempt from Brokerage, CSE, CDS, and SEC
/// fees. Share Transaction Levy (0.300%) is ALWAYS charged on both sides.
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

  /// Exempt rate (STL only): 0.300%
  static const double exemptRate = shareTransactionLevyRate;

  // ─── Buy / Sell helpers ───────────────────────────────────────────────

  /// Total cost of a BUY = trade value + applicable charges.
  /// - IPO buys: no charges.
  /// - Intra-day exempt buys: only STL charged.
  /// - Normal buys: full charges.
  static double buyCost(double tradeValue, {bool isIpo = false, bool isExempt = false}) {
    if (isIpo) return tradeValue;
    if (isExempt) return tradeValue * (1 + exemptRate);
    return tradeValue * (1 + totalRate);
  }

  /// Net proceeds of a SELL = trade value − applicable charges.
  /// - Intra-day exempt sells: only STL deducted.
  /// - Normal sells: full charges deducted.
  static double sellProceeds(double tradeValue, {bool isExempt = false}) {
    if (isExempt) return tradeValue * (1 - exemptRate);
    return tradeValue * (1 - totalRate);
  }

  // ─── Breakdown calculators ────────────────────────────────────────────

  /// Full charges breakdown for a given trade value.
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

  /// Exempt breakdown: only Share Transaction Levy is charged.
  /// Brokerage, CSE, CDS, and SEC fees are zero.
  static ChargesBreakdown computeExempt(double tradeValue) {
    final stl = tradeValue * shareTransactionLevyRate;
    return ChargesBreakdown(
      tradeValue: tradeValue,
      brokerageFee: 0,
      cseFee: 0,
      cdsFee: 0,
      secCess: 0,
      shareTransactionLevy: stl,
      totalCharges: stl,
      grandTotal: tradeValue + stl,
      isExempt: true,
    );
  }

  // ─── Intra-day exemption engine ───────────────────────────────────────

  /// Determines which trade IDs are exempt from Brokerage/CSE/CDS/SEC fees
  /// due to intra-day netting rules.
  ///
  /// Rules:
  /// - Group trades by (symbol, date, channelId).
  /// - If both buys and sells exist in a group:
  ///   - If buyQty ≥ sellQty → sell side is exempt.
  ///   - If sellQty > buyQty → buy side is exempt.
  /// - Exempt trades still pay Share Transaction Levy (0.300%).
  /// - IPO trades are excluded from grouping (they never have charges).
  static Set<String> findIntraDayExemptions(List<TradeData> trades) {
    // Group by (symbol, YYYY-MM-DD, channelId)
    final groups = <String, List<TradeData>>{};

    for (final t in trades) {
      if (t.isIpo) continue; // IPO trades excluded from grouping
      final dateKey = '${t.date.year}-'
          '${t.date.month.toString().padLeft(2, '0')}-'
          '${t.date.day.toString().padLeft(2, '0')}';
      final groupKey = '${t.symbol}|$dateKey|${t.channelId}';
      groups.putIfAbsent(groupKey, () => []).add(t);
    }

    final exemptIds = <String>{};

    for (final group in groups.values) {
      final buys = group.where((t) => t.action == 'buy');
      final sells = group.where((t) => t.action == 'sell');

      final buyQty = buys.fold(0.0, (sum, t) => sum + t.quantity);
      final sellQty = sells.fold(0.0, (sum, t) => sum + t.quantity);

      if (buyQty == 0 || sellQty == 0) continue; // no intra-day pair

      // Exempt side: sell if buyQty ≥ sellQty, buy otherwise
      if (buyQty >= sellQty) {
        for (final t in sells) {
          exemptIds.add(t.id);
        }
      } else {
        for (final t in buys) {
          exemptIds.add(t.id);
        }
      }
    }

    return exemptIds;
  }
}

// ─── Data classes ─────────────────────────────────────────────────────────

/// Minimal trade data used by [TransactionCharges.findIntraDayExemptions].
/// Decoupled from the database Trade model to keep this utility layer-agnostic.
class TradeData {
  final String id;
  final String symbol;
  final String channelId;
  final String action; // 'buy' or 'sell'
  final double quantity;
  final DateTime date;
  final bool isIpo;

  const TradeData({
    required this.id,
    required this.symbol,
    required this.channelId,
    required this.action,
    required this.quantity,
    required this.date,
    required this.isIpo,
  });
}

/// Holds a full breakdown of CSE transaction charges for a trade.
class ChargesBreakdown {
  /// The raw trade value (quantity × price), before charges.
  final double tradeValue;

  /// Brokerage fee (0.640% of trade value, or 0 if exempt).
  final double brokerageFee;

  /// CSE Fees (0.084% of trade value, or 0 if exempt).
  final double cseFee;

  /// CDS Fees (0.024% of trade value, or 0 if exempt).
  final double cdsFee;

  /// SEC Cess (0.072% of trade value, or 0 if exempt).
  final double secCess;

  /// Share Transaction Levy (0.300% of trade value). Always charged.
  final double shareTransactionLevy;

  /// Total of all applicable charges.
  final double totalCharges;

  /// Grand total = trade value + all applicable charges.
  final double grandTotal;

  /// True if this trade is intra-day exempt (only STL charged).
  final bool isExempt;

  const ChargesBreakdown({
    required this.tradeValue,
    required this.brokerageFee,
    required this.cseFee,
    required this.cdsFee,
    required this.secCess,
    required this.shareTransactionLevy,
    required this.totalCharges,
    required this.grandTotal,
    this.isExempt = false,
  });
}
