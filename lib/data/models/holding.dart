import 'package:equatable/equatable.dart';

/// Represents a computed stock holding (aggregated from trades)
class Holding extends Equatable {
  final String symbol;
  final double netQuantity;
  final double avgBuyPrice;
  final double totalInvested;
  final double totalSoldQuantity;
  final double totalSoldValue;
  final double realizedGain;

  const Holding({
    required this.symbol,
    required this.netQuantity,
    required this.avgBuyPrice,
    required this.totalInvested,
    required this.totalSoldQuantity,
    required this.totalSoldValue,
    required this.realizedGain,
  });

  /// Historical total quantity (approximate if split)
  double get totalQuantity => netQuantity + totalSoldQuantity;

  /// Current book value (cost basis)
  double get currentValue => netQuantity * avgBuyPrice;

  @override
  List<Object?> get props => [
        symbol,
        netQuantity,
        avgBuyPrice,
        totalInvested,
        totalSoldQuantity,
        totalSoldValue,
        realizedGain,
      ];
}
