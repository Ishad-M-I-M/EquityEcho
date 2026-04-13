import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equity_echo/data/database/daos/trade_dao.dart';
import 'package:equity_echo/data/database/daos/fund_transfer_dao.dart';
import 'package:equity_echo/data/database/daos/channel_dao.dart';
import 'package:equity_echo/data/database/daos/dividend_dao.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final TradeDao _tradeDao;
  final FundTransferDao _fundTransferDao;
  final ChannelDao _channelDao;
  final DividendDao _dividendDao;

  DashboardBloc({
    required TradeDao tradeDao,
    required FundTransferDao fundTransferDao,
    required ChannelDao channelDao,
    required DividendDao dividendDao,
  }) : _tradeDao = tradeDao,
       _fundTransferDao = fundTransferDao,
       _channelDao = channelDao,
       _dividendDao = dividendDao,
       super(DashboardInitial()) {
    on<LoadDashboard>(_onLoadDashboard);
    on<RefreshDashboard>(_onLoadDashboard);
  }

  Future<void> _onLoadDashboard(
    DashboardEvent event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    try {
      final holdings = await _tradeDao.getHoldings();
      final totalInvested = await _tradeDao.getTotalInvested();
      final totalSold = await _tradeDao.getTotalSold();
      final chargesPaid = await _tradeDao.getTotalChargesPaid();
      final totalDeposits = await _fundTransferDao.getTotalDeposits();
      final totalWithdrawals = await _fundTransferDao.getTotalWithdrawals();
      final regularDeposits = await _fundTransferDao.getTotalRegularDeposits();
      final ipoDeposits = await _fundTransferDao.getTotalIpoDeposits();
      final allTrades = await _tradeDao.getAllTrades();
      final totalDividends = await _dividendDao.getTotalDividends();

      // Get currency from first channel, default to LKR
      final channels = await _channelDao.getAllChannels();
      final currency = channels.isNotEmpty ? channels.first.currency : 'LKR';

      emit(DashboardLoaded(
        holdings: holdings,
        totalInvested: totalInvested,
        totalSold: totalSold,
        totalDeposits: totalDeposits,
        totalWithdrawals: totalWithdrawals,
        totalTrades: allTrades.length,
        totalDividends: totalDividends,
        currency: currency,
        regularDeposits: regularDeposits,
        ipoDeposits: ipoDeposits,
        chargesPaid: chargesPaid,
      ));
    } catch (e) {
      emit(DashboardError('Failed to load dashboard: $e'));
    }
  }
}

