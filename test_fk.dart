import 'package:equity_echo/data/database/database.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart';

void main() async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  try {
    await db.into(db.trades).insert(TradesCompanion.insert(
      id: 'test_id',
      channelId: 'other',
      action: 'buy',
      symbol: 'TEST',
      quantity: 1.0,
      price: 1.0,
      totalValue: 1.0,
      smsDate: DateTime.now(),
      rawSmsBody: const Value(''),
    ));
    print('SUCCESS_INSERT');
  } catch (e) {
    print('ERROR_INSERT: \$e');
  }
}
