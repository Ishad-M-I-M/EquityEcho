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
  /// True when the trade was an IPO purchase — charges do NOT apply.
  final bool isIpo;
  /// True when the trade is intra-day exempt — only STL charged.
  final bool isIntraDayExempt;
  /// True when the trade is a holdings adjustment entry.
  final bool isAdjustment;

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
    this.isIpo = false,
    this.isIntraDayExempt = false,
    this.isAdjustment = false,
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
