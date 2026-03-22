import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equity_echo/data/database/daos/trade_dao.dart';
import 'package:equity_echo/data/database/daos/fund_transfer_dao.dart';
import 'package:equity_echo/data/database/daos/channel_dao.dart';
import 'package:equity_echo/data/models/activity_item.dart';
import 'package:equity_echo/data/models/enums.dart';
import 'activity_log_event.dart';
import 'activity_log_state.dart';

class ActivityLogBloc extends Bloc<ActivityLogEvent, ActivityLogState> {
  final TradeDao _tradeDao;
  final FundTransferDao _fundTransferDao;
  final ChannelDao _channelDao;

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

      emit(ActivityLogLoaded(allItems));
    } catch (e) {
      emit(ActivityLogError('Failed to load activity log: $e'));
    }
  }
}
