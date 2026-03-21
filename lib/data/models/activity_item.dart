import 'package:equatable/equatable.dart';
import 'package:equity_echo/data/models/enums.dart';

/// Represents an item in the activity log.
/// Can be either a trade or a fund transfer.
enum ActivityType { trade, fundTransfer }

class ActivityItem extends Equatable {
  final String id;
  final ActivityType type;
  final String channelName;
  final DateTime date;
  final DateTime createdAt;
  final String rawSmsBody;
  final bool isManual;

  // Trade-specific fields (null for fund transfers)
  final TradeAction? tradeAction;
  final String? symbol;
  final double? quantity;
  final double? price;
  final double? totalValue;

  // Fund transfer-specific fields (null for trades)
  final FundAction? fundAction;
  final double? amount;

  const ActivityItem({
    required this.id,
    required this.type,
    required this.channelName,
    required this.date,
    required this.createdAt,
    required this.rawSmsBody,
    required this.isManual,
    this.tradeAction,
    this.symbol,
    this.quantity,
    this.price,
    this.totalValue,
    this.fundAction,
    this.amount,
  });

  /// Human-readable description of the activity
  String get description {
    if (type == ActivityType.trade) {
      return '${tradeAction?.label ?? ''} $quantity × $symbol @ $price';
    } else {
      return '${fundAction?.label ?? ''} $amount';
    }
  }

  @override
  List<Object?> get props => [id, type, date, createdAt];
}
