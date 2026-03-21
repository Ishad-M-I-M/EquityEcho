import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:equity_echo/data/database/database.dart';
import 'package:equity_echo/data/database/daos/fund_transfer_dao.dart';
import 'fund_transfer_event.dart';
import 'fund_transfer_state.dart';

class FundTransferBloc extends Bloc<FundTransferEvent, FundTransferState> {
  final FundTransferDao _fundTransferDao;
  static const _uuid = Uuid();

  FundTransferBloc({required FundTransferDao fundTransferDao})
      : _fundTransferDao = fundTransferDao,
        super(FundTransferInitial()) {
    on<LoadFundTransfers>(_onLoadFundTransfers);
    on<AddFundTransfer>(_onAddFundTransfer);
    on<DeleteFundTransfer>(_onDeleteFundTransfer);
  }

  Future<void> _onLoadFundTransfers(
    LoadFundTransfers event,
    Emitter<FundTransferState> emit,
  ) async {
    emit(FundTransferLoading());
    try {
      final transfers = await _fundTransferDao.getAllFundTransfers();
      emit(FundTransfersLoaded(transfers));
    } catch (e) {
      emit(FundTransferError('Failed to load transfers: $e'));
    }
  }

  Future<void> _onAddFundTransfer(
    AddFundTransfer event,
    Emitter<FundTransferState> emit,
  ) async {
    try {
      await _fundTransferDao.insertFundTransfer(FundTransfersCompanion.insert(
        id: _uuid.v4(),
        channelId: event.channelId,
        action: event.action,
        amount: event.amount,
        smsDate: event.smsDate,
        rawSmsBody: Value(event.rawSmsBody),
        isManual: Value(event.isManual),
      ));
      emit(const FundTransferOperationSuccess('Fund transfer added'));
      add(LoadFundTransfers());
    } catch (e) {
      emit(FundTransferError('Failed to add transfer: $e'));
    }
  }

  Future<void> _onDeleteFundTransfer(
    DeleteFundTransfer event,
    Emitter<FundTransferState> emit,
  ) async {
    try {
      await _fundTransferDao.deleteFundTransfer(event.id);
      emit(const FundTransferOperationSuccess('Fund transfer deleted'));
      add(LoadFundTransfers());
    } catch (e) {
      emit(FundTransferError('Failed to delete transfer: $e'));
    }
  }
}
