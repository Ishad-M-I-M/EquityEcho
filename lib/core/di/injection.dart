import 'package:get_it/get_it.dart';
import 'package:equity_echo/data/database/database.dart';
import 'package:equity_echo/data/database/daos/channel_dao.dart';
import 'package:equity_echo/data/database/daos/trade_dao.dart';
import 'package:equity_echo/data/database/daos/fund_transfer_dao.dart';
import 'package:equity_echo/data/database/daos/stock_split_dao.dart';
import 'package:equity_echo/core/services/sms_service.dart';

final getIt = GetIt.instance;

/// Initialize all dependencies
Future<void> setupDependencies() async {
  // Database
  final database = AppDatabase();
  getIt.registerSingleton<AppDatabase>(database);

  // DAOs
  getIt.registerSingleton<ChannelDao>(database.channelDao);
  getIt.registerSingleton<TradeDao>(database.tradeDao);
  getIt.registerSingleton<FundTransferDao>(database.fundTransferDao);
  getIt.registerSingleton<StockSplitDao>(database.stockSplitDao);

  // Services
  getIt.registerSingleton<SmsService>(SmsService());
}
