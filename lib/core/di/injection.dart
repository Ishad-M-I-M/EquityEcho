import 'package:get_it/get_it.dart';
import 'package:equity_echo/data/database/database.dart';
import 'package:equity_echo/data/database/daos/channel_dao.dart';
import 'package:equity_echo/data/database/daos/trade_dao.dart';
import 'package:equity_echo/data/database/daos/fund_transfer_dao.dart';
import 'package:equity_echo/data/database/daos/stock_split_dao.dart';
import 'package:equity_echo/data/database/daos/dividend_dao.dart';
import 'package:equity_echo/core/services/sms_service.dart';
import 'package:equity_echo/core/services/auth_service.dart';
import 'package:equity_echo/core/services/cloud_sync_service.dart';
import 'package:equity_echo/data/services/firebase_auth_service.dart';
import 'package:equity_echo/data/services/firestore_cloud_sync_service.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:equity_echo/core/services/realtime_sync_manager.dart';

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
  getIt.registerSingleton<DividendDao>(database.dividendDao);

  // Services
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);

  getIt.registerSingleton<SmsService>(SmsService());
  getIt.registerSingleton<AuthService>(FirebaseAuthService());
  getIt.registerSingleton<CloudSyncService>(FirestoreCloudSyncService());

  getIt.registerSingleton<RealtimeSyncManager>(
    RealtimeSyncManager(
      prefs: getIt<SharedPreferences>(),
      db: getIt<AppDatabase>(),
      authService: getIt<AuthService>(),
      syncService: getIt<CloudSyncService>(),
    ),
  );
}
