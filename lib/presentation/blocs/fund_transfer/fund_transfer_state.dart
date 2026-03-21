import 'package:equatable/equatable.dart';
import 'package:equity_echo/data/database/database.dart';

abstract class FundTransferState extends Equatable {
  const FundTransferState();
  @override
  List<Object?> get props => [];
}

class FundTransferInitial extends FundTransferState {}

class FundTransferLoading extends FundTransferState {}

class FundTransfersLoaded extends FundTransferState {
  final List<FundTransfer> transfers;
  const FundTransfersLoaded(this.transfers);
  @override
  List<Object?> get props => [transfers];
}

class FundTransferOperationSuccess extends FundTransferState {
  final String message;
  const FundTransferOperationSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class FundTransferError extends FundTransferState {
  final String message;
  const FundTransferError(this.message);
  @override
  List<Object?> get props => [message];
}
