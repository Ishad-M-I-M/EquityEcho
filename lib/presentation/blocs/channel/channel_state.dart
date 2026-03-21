import 'package:equatable/equatable.dart';
import 'package:equity_echo/data/database/database.dart';
import 'package:equity_echo/core/services/template_parser.dart';

/// Channel BLoC States
abstract class ChannelState extends Equatable {
  const ChannelState();
  @override
  List<Object?> get props => [];
}

class ChannelInitial extends ChannelState {}

class ChannelLoading extends ChannelState {}

class ChannelsLoaded extends ChannelState {
  final List<Channel> channels;
  const ChannelsLoaded(this.channels);
  @override
  List<Object?> get props => [channels];
}

class ChannelOperationSuccess extends ChannelState {
  final String message;
  const ChannelOperationSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class ChannelError extends ChannelState {
  final String message;
  const ChannelError(this.message);
  @override
  List<Object?> get props => [message];
}

class TemplateTestResult extends ChannelState {
  final bool matched;
  final ParseResult? result;
  final String regexPattern;

  const TemplateTestResult({
    required this.matched,
    this.result,
    required this.regexPattern,
  });

  @override
  List<Object?> get props => [matched, result, regexPattern];
}
