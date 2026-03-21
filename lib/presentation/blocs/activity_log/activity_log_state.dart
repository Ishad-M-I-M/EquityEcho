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
  final List<ActivityItem> items;
  const ActivityLogLoaded(this.items);
  @override
  List<Object?> get props => [items];
}

class ActivityLogError extends ActivityLogState {
  final String message;
  const ActivityLogError(this.message);
  @override
  List<Object?> get props => [message];
}
