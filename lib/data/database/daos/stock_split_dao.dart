import 'package:drift/drift.dart';
import 'package:equity_echo/data/database/database.dart';

part 'stock_split_dao.g.dart';

@DriftAccessor(tables: [StockSplits])
class StockSplitDao extends DatabaseAccessor<AppDatabase>
    with _$StockSplitDaoMixin {
  StockSplitDao(super.db);

  /// Get all stock splits
  Future<List<StockSplit>> getAllStockSplits() =>
      (select(stockSplits)
            ..where((s) => s.isDeleted.equals(false))
            ..orderBy([(s) => OrderingTerm.desc(s.splitDate)]))
          .get();

  /// Get all stock splits for a specific symbol
  Future<List<StockSplit>> getSplitsForSymbol(String symbol) =>
      (select(stockSplits)
            ..where((s) => s.isDeleted.equals(false) & s.symbol.equals(symbol))
            ..orderBy([(s) => OrderingTerm.desc(s.splitDate)]))
          .get();

  /// Insert a stock split
  Future<int> insertSplit(StockSplitsCompanion split) =>
      into(stockSplits).insert(split);

  Future<int> deleteSplit(
    String id, {
    String? reason,
    String? reasonOther,
  }) async {
    return (update(stockSplits)..where((s) => s.id.equals(id))).write(
      StockSplitsCompanion(
        isDeleted: const Value(true),
        deleteReason: Value(reason),
        deleteReasonOther: Value(reasonOther),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Restore a stock split
  Future<int> restoreSplit(String id) async {
    return (update(stockSplits)..where((s) => s.id.equals(id))).write(
      StockSplitsCompanion(
        isDeleted: const Value(false),
        deleteReason: const Value(null),
        deleteReasonOther: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Get deleted stock splits
  Future<List<StockSplit>> getDeletedSplits() =>
      (select(stockSplits)
            ..where((s) => s.isDeleted.equals(true))
            ..orderBy([(s) => OrderingTerm.desc(s.splitDate)]))
          .get();

  /// Get modified stock splits since
  Future<List<StockSplit>> getModifiedSplitsSince(DateTime since) => (select(
    stockSplits,
  )..where((s) => s.updatedAt.isBiggerThanValue(since))).get();
}
