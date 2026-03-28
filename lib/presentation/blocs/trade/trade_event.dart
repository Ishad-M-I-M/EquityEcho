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
  });

  @override
  List<Object?> get props => [channelId, action, symbol, quantity, price, smsDate, isIpo];
}

class UpdateTrade extends TradeEvent {
  final String id;
  final String channelId;
  final String action;
  final String symbol;
  final double quantity;
  final double price;
  final DateTime smsDate;

  const UpdateTrade({
    required this.id,
    required this.channelId,
    required this.action,
    required this.symbol,
    required this.quantity,
    required this.price,
    required this.smsDate,
  });

  @override
  List<Object?> get props => [id, channelId, action, symbol, quantity, price];
}

class DeleteTrade extends TradeEvent {
  final String id;
  const DeleteTrade(this.id);
  @override
  List<Object?> get props => [id];
}
