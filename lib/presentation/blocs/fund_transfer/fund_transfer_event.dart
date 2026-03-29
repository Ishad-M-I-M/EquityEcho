import 'package:equatable/equatable.dart';

abstract class FundTransferEvent extends Equatable {
  const FundTransferEvent();
  @override
  List<Object?> get props => [];
}

class LoadFundTransfers extends FundTransferEvent {}

class AddFundTransfer extends FundTransferEvent {
  final String channelId;
  final String action; // 'deposit' or 'withdrawal'
  final double amount;
  final DateTime smsDate;
  final String rawSmsBody;
  final bool isManual;

  const AddFundTransfer({
    required this.channelId,
    required this.action,
    required this.amount,
    required this.smsDate,
    this.rawSmsBody = '',
    this.isManual = true,
  });

  @override
  List<Object?> get props => [channelId, action, amount, smsDate];
}

class DeleteFundTransfer extends FundTransferEvent {
  final String id;
  final String? reason;
  final String? reasonOther;

  const DeleteFundTransfer(this.id, {this.reason, this.reasonOther});

  @override
  List<Object?> get props => [id, reason, reasonOther];
}
