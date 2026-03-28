import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:equity_echo/data/database/daos/trade_dao.dart';
import 'package:equity_echo/data/database/daos/fund_transfer_dao.dart';
import 'package:equity_echo/data/database/daos/channel_dao.dart';
import 'package:equity_echo/data/models/activity_item.dart';
import 'package:equity_echo/data/models/enums.dart';
import 'package:equity_echo/core/utils/transaction_charges.dart';
import 'activity_log_event.dart';
import 'activity_log_state.dart';

class ActivityLogBloc extends Bloc<ActivityLogEvent, ActivityLogState> {
  final TradeDao _tradeDao;
  final FundTransferDao _fundTransferDao;
  final ChannelDao _channelDao;

  List<ActivityItem> _allItems = [];
  int? _monthFilter;
  int? _yearFilter;
  String? _symbolFilter;
  ActivityType? _typeFilter;

  ActivityLogBloc({
    required TradeDao tradeDao,
    required FundTransferDao fundTransferDao,
    required ChannelDao channelDao,
  })  : _tradeDao = tradeDao,
        _fundTransferDao = fundTransferDao,
        _channelDao = channelDao,
        super(ActivityLogInitial()) {
    on<LoadActivityLog>(_onLoad);
    on<RefreshActivityLog>(_onLoad);
    on<FilterActivityLog>(_onFilter);
    on<ClearFilters>(_onClearFilters);
  }

  Future<void> _onLoad(
    ActivityLogEvent event,
    Emitter<ActivityLogState> emit,
  ) async {
    emit(ActivityLogLoading());
    try {
      // Fetch channels for name lookup
      final channels = await _channelDao.getAllChannels();
      final channelMap = {for (var c in channels) c.id: c.name};

      // Fetch trades
      final trades = await _tradeDao.getAllTrades();

      // Compute intra-day exemptions
      final tradeDataList = trades
          .map((t) => TradeData(
                id: t.id,
                symbol: t.symbol,
                channelId: t.channelId,
                action: t.action,
                quantity: t.quantity,
                date: t.smsDate,
                isIpo: t.isIpo,
              ))
          .toList();
      final exemptIds = TransactionCharges.findIntraDayExemptions(tradeDataList);

      final tradeItems = trades.map((t) => ActivityItem(
            id: t.id,
            type: ActivityType.trade,
            channelName: channelMap[t.channelId] ?? 'Unknown',
            date: t.smsDate,
            createdAt: t.createdAt,
            rawSmsBody: t.rawSmsBody,
            isManual: t.isManual,
            tradeAction:
                t.action == 'buy' ? TradeAction.buy : TradeAction.sell,
            symbol: t.symbol,
            quantity: t.quantity,
            price: t.price,
            totalValue: t.totalValue,
            isIpo: t.isIpo,
            isIntraDayExempt: exemptIds.contains(t.id),
          ));

      // Fetch fund transfers
      final transfers = await _fundTransferDao.getAllFundTransfers();
      final transferItems = transfers.map((f) => ActivityItem(
            id: f.id,
            type: ActivityType.fundTransfer,
            channelName: channelMap[f.channelId] ?? 'Unknown',
            date: f.smsDate,
            createdAt: f.createdAt,
            rawSmsBody: f.rawSmsBody,
            isManual: f.isManual,
            fundAction: f.action == 'deposit'
                ? FundAction.deposit
                : (f.action == 'ipo_deposit' ? FundAction.ipoDeposit : FundAction.withdrawal),
            amount: f.amount,
          ));

      // Combine and sort by date descending
      final allItems = [...tradeItems, ...transferItems];
      allItems.sort((a, b) => b.date.compareTo(a.date));
      _allItems = allItems;

      _emitFiltered(emit);
    } catch (e) {
      emit(ActivityLogError('Failed to load activity log: $e'));
    }
  }

  void _onFilter(
    FilterActivityLog event,
    Emitter<ActivityLogState> emit,
  ) {
    _monthFilter = event.month;
    _yearFilter = event.year;
    _symbolFilter = event.symbol;
    _typeFilter = event.type;
    _emitFiltered(emit);
  }

  void _onClearFilters(
    ClearFilters event,
    Emitter<ActivityLogState> emit,
  ) {
    _monthFilter = null;
    _yearFilter = null;
    _symbolFilter = null;
    _typeFilter = null;
    _emitFiltered(emit);
  }

  void _emitFiltered(Emitter<ActivityLogState> emit) {
    // Collect available filters
    final Set<String> symbolSet = {};
    final Set<int> yearSet = {};
    for (var item in _allItems) {
      if (item.symbol != null) {
        symbolSet.add(item.symbol!);
      }
      yearSet.add(item.date.year);
    }
    final availableSymbols = symbolSet.toList()..sort();
    final availableYears = yearSet.toList()..sort((a, b) => b.compareTo(a));

    // Apply filters
    final filteredIter = _allItems.where((item) {
      if (_monthFilter != null && item.date.month != _monthFilter) return false;
      if (_yearFilter != null && item.date.year != _yearFilter) return false;
      if (_symbolFilter != null && item.symbol != _symbolFilter) return false;
      if (_typeFilter != null && item.type != _typeFilter) return false;
      return true;
    });

    final filteredItems = filteredIter.toList();

    // Group by month and year
    final Map<String, List<ActivityItem>> grouped = {};
    final dateFormat = DateFormat('MMMM yyyy');

    for (var item in filteredItems) {
      final key = dateFormat.format(item.date);
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(item);
    }

    emit(ActivityLogLoaded(
      groupedItems: grouped,
      monthFilter: _monthFilter,
      yearFilter: _yearFilter,
      symbolFilter: _symbolFilter,
      typeFilter: _typeFilter,
      availableSymbols: availableSymbols,
      availableYears: availableYears,
    ));
  }
}
