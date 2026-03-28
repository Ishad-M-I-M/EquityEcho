import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:equity_echo/data/database/database.dart';
import 'package:equity_echo/data/database/daos/trade_dao.dart';
import 'trade_event.dart';
import 'trade_state.dart';

class TradeBloc extends Bloc<TradeEvent, TradeState> {
  final TradeDao _tradeDao;
  static const _uuid = Uuid();

  TradeBloc({required TradeDao tradeDao})
      : _tradeDao = tradeDao,
        super(TradeInitial()) {
    on<LoadTrades>(_onLoadTrades);
    on<AddTrade>(_onAddTrade);
    on<UpdateTrade>(_onUpdateTrade);
    on<DeleteTrade>(_onDeleteTrade);
  }

  Future<void> _onLoadTrades(
    LoadTrades event,
    Emitter<TradeState> emit,
  ) async {
    emit(TradeLoading());
    try {
      final trades = await _tradeDao.getAllTrades();
      emit(TradesLoaded(trades));
    } catch (e) {
      emit(TradeError('Failed to load trades: $e'));
    }
  }

  Future<void> _onAddTrade(
    AddTrade event,
    Emitter<TradeState> emit,
  ) async {
    try {
      await _tradeDao.insertTrade(TradesCompanion.insert(
        id: _uuid.v4(),
        channelId: event.channelId,
        action: event.action,
        symbol: event.symbol,
        quantity: event.quantity,
        price: event.price,
        totalValue: event.quantity * event.price,
        smsDate: event.smsDate,
        rawSmsBody: Value(event.rawSmsBody),
        isManual: Value(event.isManual),
        isIpo: Value(event.isIpo),
      ));
      emit(const TradeOperationSuccess('Trade added'));
      add(LoadTrades());
    } catch (e) {
      emit(TradeError('Failed to add trade: $e'));
    }
  }

  Future<void> _onUpdateTrade(
    UpdateTrade event,
    Emitter<TradeState> emit,
  ) async {
    try {
      final existing = (await _tradeDao.getAllTrades())
          .firstWhere((t) => t.id == event.id);

      final updated = Trade(
        id: event.id,
        channelId: event.channelId,
        action: event.action,
        symbol: event.symbol,
        quantity: event.quantity,
        price: event.price,
        totalValue: event.quantity * event.price,
        smsDate: event.smsDate,
        rawSmsBody: existing.rawSmsBody,
        createdAt: existing.createdAt,
        isManual: existing.isManual,
        isEdited: true,
        isIpo: existing.isIpo,
      );

      await _tradeDao.updateTrade(updated);
      emit(const TradeOperationSuccess('Trade updated'));
      add(LoadTrades());
    } catch (e) {
      emit(TradeError('Failed to update trade: $e'));
    }
  }

  Future<void> _onDeleteTrade(
    DeleteTrade event,
    Emitter<TradeState> emit,
  ) async {
    try {
      await _tradeDao.deleteTrade(event.id);
      emit(const TradeOperationSuccess('Trade deleted'));
      add(LoadTrades());
    } catch (e) {
      emit(TradeError('Failed to delete trade: $e'));
    }
  }
}
