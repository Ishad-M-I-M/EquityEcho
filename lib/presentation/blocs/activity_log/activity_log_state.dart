import 'package:equatable/equatable.dart';
import 'package:equity_echo/data/models/activity_item.dart';

abstract class ActivityLogState extends Equatable {
  const ActivityLogState();
  @override
  List<Object?> get props => [];
}

class ActivityLogInitial extends ActivityLogState {}

class ActivityLogLoading extends ActivityLogState {}

class ActivityLogLoaded extends ActivityLogState {
  final Map<String, List<ActivityItem>> groupedItems;
  final int? monthFilter;
  final int? yearFilter;
  final String? symbolFilter;
  final ActivityType? typeFilter;
  final List<String> availableSymbols;
  final List<int> availableYears;

  const ActivityLogLoaded({
    required this.groupedItems,
    this.monthFilter,
    this.yearFilter,
    this.symbolFilter,
    this.typeFilter,
    required this.availableSymbols,
    required this.availableYears,
  });

  @override
  List<Object?> get props => [
    groupedItems,
    monthFilter,
    yearFilter,
    symbolFilter,
    typeFilter,
    availableSymbols,
    availableYears,
  ];
}

class ActivityLogError extends ActivityLogState {
  final String message;
  const ActivityLogError(this.message);
  @override
  List<Object?> get props => [message];
}
