import 'package:equatable/equatable.dart';

abstract class TradeEvent extends Equatable {
  const TradeEvent();
  @override
  List<Object?> get props => [];
}

class LoadTrades extends TradeEvent {}

class AddTrade extends TradeEvent {
  final String channelId;
  final String action; // 'buy' or 'sell'
  final String symbol;
  final double quantity;
  final double price;
  final DateTime smsDate;
  final String rawSmsBody;
  final bool isManual;

  /// Whether this trade is an IPO purchase. Charges do NOT apply when true.
  final bool isIpo;

  /// Whether this trade is a holdings adjustment entry.
  final bool isAdjustment;
  final String? targetSymbol;

  const AddTrade({
    required this.channelId,
    required this.action,
    required this.symbol,
    required this.quantity,
    required this.price,
    required this.smsDate,
    this.rawSmsBody = '',
    this.isManual = true,
    this.isIpo = false,
    this.isAdjustment = false,
    this.targetSymbol,
  });

  @override
  List<Object?> get props => [
    channelId,
    action,
    symbol,
    quantity,
    price,
    smsDate,
    isIpo,
    isAdjustment,
    targetSymbol,
  ];
}

class UpdateTrade extends TradeEvent {
  final String id;
  final String channelId;
  final String action;
  final String symbol;
  final double quantity;
  final double price;
  final DateTime smsDate;
  final String? targetSymbol;

  const UpdateTrade({
    required this.id,
    required this.channelId,
    required this.action,
    required this.symbol,
    required this.quantity,
    required this.price,
    required this.smsDate,
    this.targetSymbol,
  });

  @override
  List<Object?> get props => [
    id,
    channelId,
    action,
    symbol,
    quantity,
    price,
    targetSymbol,
  ];
}

class DeleteTrade extends TradeEvent {
  final String id;
  final String? reason;
  final String? reasonOther;

  const DeleteTrade(this.id, {this.reason, this.reasonOther});

  @override
  List<Object?> get props => [id, reason, reasonOther];
}
