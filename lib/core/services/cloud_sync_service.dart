import 'package:equity_echo/data/database/database.dart';

abstract class CloudSyncService {
  /// Pushes local changes to the cloud
  Future<void> syncUp(String userId, AppDatabase db);
  
  /// Pulls remote changes from the cloud
  Future<void> syncDown(String userId, AppDatabase db);
}
