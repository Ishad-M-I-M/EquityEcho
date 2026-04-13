import 'package:equatable/equatable.dart';
import 'package:equity_echo/data/models/activity_item.dart';

abstract class ActivityLogEvent extends Equatable {
  const ActivityLogEvent();
  @override
  List<Object?> get props => [];
}

class LoadActivityLog extends ActivityLogEvent {}

class RefreshActivityLog extends ActivityLogEvent {}

class FilterActivityLog extends ActivityLogEvent {
  final int? month;
  final int? year;
  final String? symbol;
  final ActivityType? type;

  const FilterActivityLog({this.month, this.year, this.symbol, this.type});

  @override
  List<Object?> get props => [month, year, symbol, type];
}

class ClearFilters extends ActivityLogEvent {}
