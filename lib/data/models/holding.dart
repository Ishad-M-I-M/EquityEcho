import 'package:equatable/equatable.dart';

/// Represents a computed stock holding (aggregated from trades)
class Holding extends Equatable {
  final String symbol;
  final double totalQuantity;
  final double avgBuyPrice;
  final double totalInvested;
  final double totalSoldQuantity;
  final double totalSoldValue;

  const Holding({
    required this.symbol,
    required this.totalQuantity,
    required this.avgBuyPrice,
    required this.totalInvested,
    required this.totalSoldQuantity,
    required this.totalSoldValue,
  });

  /// Net quantity currently held
  double get netQuantity => totalQuantity - totalSoldQuantity;

  /// Current book value (cost basis)
  double get currentValue => netQuantity * avgBuyPrice;

  @override
  List<Object?> get props => [
        symbol,
        totalQuantity,
        avgBuyPrice,
        totalInvested,
        totalSoldQuantity,
        totalSoldValue,
      ];
}
