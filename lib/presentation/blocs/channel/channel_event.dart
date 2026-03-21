import 'package:equatable/equatable.dart';

/// Channel BLoC Events
abstract class ChannelEvent extends Equatable {
  const ChannelEvent();
  @override
  List<Object?> get props => [];
}

class LoadChannels extends ChannelEvent {}

class AddChannel extends ChannelEvent {
  final String name;
  final String senderAddress;
  final String? buyTemplate;
  final String? sellTemplate;
  final String? fundTemplate;
  final String currency;

  const AddChannel({
    required this.name,
    required this.senderAddress,
    this.buyTemplate,
    this.sellTemplate,
    this.fundTemplate,
    this.currency = 'LKR',
  });

  @override
  List<Object?> get props =>
      [name, senderAddress, buyTemplate, sellTemplate, fundTemplate, currency];
}

class UpdateChannel extends ChannelEvent {
  final String id;
  final String name;
  final String senderAddress;
  final String? buyTemplate;
  final String? sellTemplate;
  final String? fundTemplate;
  final String currency;

  const UpdateChannel({
    required this.id,
    required this.name,
    required this.senderAddress,
    this.buyTemplate,
    this.sellTemplate,
    this.fundTemplate,
    this.currency = 'LKR',
  });

  @override
  List<Object?> get props =>
      [id, name, senderAddress, buyTemplate, sellTemplate, fundTemplate, currency];
}

class DeleteChannel extends ChannelEvent {
  final String id;
  const DeleteChannel(this.id);
  @override
  List<Object?> get props => [id];
}

class TestTemplate extends ChannelEvent {
  final String template;
  final String sampleSms;

  const TestTemplate({required this.template, required this.sampleSms});

  @override
  List<Object?> get props => [template, sampleSms];
}
