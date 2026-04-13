import 'package:equatable/equatable.dart';
import 'package:equity_echo/data/models/holding.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final List<Holding> holdings;
  final double totalInvested;
  final double totalSold;
  final double totalDeposits;
  final double totalWithdrawals;
  final int totalTrades;
  final double totalDividends;
  final String currency;

  const DashboardLoaded({
    required this.holdings,
    required this.totalInvested,
    required this.totalSold,
    required this.totalDeposits,
    required this.totalWithdrawals,
    required this.totalTrades,
    required this.totalDividends,
    required this.currency,
  });

  /// Net fund balance = deposits - withdrawals - totalInvested + totalSold + totalDividends
  double get netFundBalance =>
      totalDeposits -
      totalWithdrawals -
      totalInvested +
      totalSold +
      totalDividends;

  /// Total realized gain from all past sells
  double get totalRealizedGain =>
      holdings.fold(0.0, (sum, h) => sum + h.realizedGain);

  /// Total book value of current holdings
  double get totalBookValue =>
      holdings.fold(0.0, (sum, h) => sum + h.currentValue);

  @override
  List<Object?> get props => [
    holdings,
    totalInvested,
    totalSold,
    totalDeposits,
    totalWithdrawals,
    totalTrades,
    totalDividends,
    currency,
  ];
}

class DashboardError extends DashboardState {
  final String message;
  const DashboardError(this.message);
  @override
  List<Object?> get props => [message];
}
