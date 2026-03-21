import 'package:equatable/equatable.dart';
import 'package:equity_echo/data/database/database.dart';

abstract class TradeState extends Equatable {
  const TradeState();
  @override
  List<Object?> get props => [];
}

class TradeInitial extends TradeState {}

class TradeLoading extends TradeState {}

class TradesLoaded extends TradeState {
  final List<Trade> trades;
  const TradesLoaded(this.trades);
  @override
  List<Object?> get props => [trades];
}

class TradeOperationSuccess extends TradeState {
  final String message;
  const TradeOperationSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class TradeError extends TradeState {
  final String message;
  const TradeError(this.message);
  @override
  List<Object?> get props => [message];
}
