import 'package:equatable/equatable.dart';

/// Represents a computed stock holding (aggregated from trades)
class Holding extends Equatable {
  final String symbol;
  final double netQuantity;

  /// Average raw buy price (trade value / qty, before charges).
  final double avgBuyPrice;

  /// Average cost per share **including** transaction charges.
  final double avgCostWithCharges;

  /// Total invested including transaction charges for non-IPO buys.
  final double totalInvested;

  final double totalSoldQuantity;

  /// Total proceeds from sells **after** charges are deducted.
  final double totalSoldValue;

  /// Realized gain = sell net proceeds − proportional cost basis (charges-adjusted).
  final double realizedGain;

  const Holding({
    required this.symbol,
    required this.netQuantity,
    required this.avgBuyPrice,
    required this.avgCostWithCharges,
    required this.totalInvested,
    required this.totalSoldQuantity,
    required this.totalSoldValue,
    required this.realizedGain,
  });

  /// Historical total quantity (approximate if split)
  double get totalQuantity => netQuantity + totalSoldQuantity;

  /// Current book value (cost basis including charges)
  double get currentValue => netQuantity * avgCostWithCharges;

  @override
  List<Object?> get props => [
    symbol,
    netQuantity,
    avgBuyPrice,
    avgCostWithCharges,
    totalInvested,
    totalSoldQuantity,
    totalSoldValue,
    realizedGain,
  ];
}
