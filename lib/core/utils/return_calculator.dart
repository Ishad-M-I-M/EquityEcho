import 'dart:math' as math;

import 'package:equity_echo/core/utils/transaction_charges.dart';

/// Result of a "what-if" buy → sell scenario.
///
/// All monetary values are in the account currency. Charges follow the CSE
/// schedule via [TransactionCharges].
class WhatIfResult {
  /// Raw buy value = quantity × buy price (before charges).
  final double buyValue;

  /// Charges added on the buy side (0 when the buy price already includes them).
  final double buyCharges;

  /// Total amount invested = buy value + buy charges.
  final double totalBuyCost;

  /// Raw sell value = quantity × sell price (before charges).
  final double sellValue;

  /// Charges deducted on the sell side.
  final double sellCharges;

  /// Net proceeds received from the sell = sell value − sell charges.
  final double netProceeds;

  /// Net gain/loss = net proceeds − total buy cost.
  final double netGain;

  /// Simple (absolute) return as a percentage of the amount invested.
  final double returnPct;

  /// Whole days between the buy and sell dates.
  final int holdingDays;

  /// Annualized return (CAGR) as a percentage.
  ///
  /// `null` when it cannot be computed meaningfully — e.g. the holding period
  /// is under a day, nothing was invested, or proceeds are non-positive.
  final double? annualizedPct;

  /// True when the sell leg was treated as intra-day exempt (same-day buy &
  /// sell), so only the Share Transaction Levy was charged on the sell side.
  final bool intraDayExempt;

  const WhatIfResult({
    required this.buyValue,
    required this.buyCharges,
    required this.totalBuyCost,
    required this.sellValue,
    required this.sellCharges,
    required this.netProceeds,
    required this.netGain,
    required this.returnPct,
    required this.holdingDays,
    required this.annualizedPct,
    required this.intraDayExempt,
  });

  /// True when the scenario yields a gain (or breaks even).
  bool get isProfit => netGain >= 0;

  /// Total transaction charges across both legs.
  double get totalCharges => buyCharges + sellCharges;

  /// Holding period expressed in fractional years (365.25-day basis).
  double get holdingYears => holdingDays / 365.25;
}

/// Computes hypothetical buy → sell returns, factoring in CSE transaction
/// charges and producing both absolute and annualized (CAGR) returns.
class ReturnCalculator {
  ReturnCalculator._();

  /// Compute a what-if buy → sell scenario.
  ///
  /// - [quantity]: number of shares.
  /// - [buyPrice]: price per share at purchase.
  /// - [sellPrice]: hypothetical price per share at sale.
  /// - [buyDate] / [sellDate]: used for the annualized (CAGR) return.
  /// - [buyPriceIncludesCharges]: when `true`, [buyPrice] is treated as the
  ///   effective per-share cost that already includes charges (e.g. an existing
  ///   holding's average cost), so no extra buy charges are added.
  /// - [applySellCharges]: when `true` (default), CSE sell charges are deducted
  ///   from the proceeds.
  ///
  /// Intra-day handling: when [buyDate] and [sellDate] fall on the same
  /// calendar day, the trade is treated as intra-day. Since the buy and sell
  /// quantities are equal, the sell leg (the lower-or-equal side under CSE
  /// netting) is exempt from Brokerage/CSE/CDS/SEC fees — only the 0.300%
  /// Share Transaction Levy is charged on the sell side. The buy leg keeps its
  /// full charges.
  static WhatIfResult compute({
    required double quantity,
    required double buyPrice,
    required double sellPrice,
    required DateTime buyDate,
    required DateTime sellDate,
    bool buyPriceIncludesCharges = false,
    bool applySellCharges = true,
  }) {
    final buyValue = quantity * buyPrice;
    final totalBuyCost = buyPriceIncludesCharges
        ? buyValue
        : TransactionCharges.buyCost(buyValue);
    final buyCharges = totalBuyCost - buyValue;

    final isSameDay =
        buyDate.year == sellDate.year &&
        buyDate.month == sellDate.month &&
        buyDate.day == sellDate.day;
    final intraDayExempt = isSameDay && applySellCharges;

    final sellValue = quantity * sellPrice;
    final netProceeds = applySellCharges
        ? TransactionCharges.sellProceeds(sellValue, isExempt: intraDayExempt)
        : sellValue;
    final sellCharges = sellValue - netProceeds;

    final netGain = netProceeds - totalBuyCost;
    final returnPct = totalBuyCost > 0 ? (netGain / totalBuyCost) * 100 : 0.0;

    final holdingDays = sellDate.difference(buyDate).inDays;

    double? annualizedPct;
    if (totalBuyCost > 0 && holdingDays > 0 && netProceeds > 0) {
      final years = holdingDays / 365.25;
      annualizedPct =
          (math.pow(netProceeds / totalBuyCost, 1 / years) - 1) * 100;
    }

    return WhatIfResult(
      buyValue: buyValue,
      buyCharges: buyCharges,
      totalBuyCost: totalBuyCost,
      sellValue: sellValue,
      sellCharges: sellCharges,
      netProceeds: netProceeds,
      netGain: netGain,
      returnPct: returnPct,
      holdingDays: holdingDays,
      annualizedPct: annualizedPct,
      intraDayExempt: intraDayExempt,
    );
  }
}
