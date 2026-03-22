import 'package:drift/drift.dart';
import 'package:equity_echo/data/database/database.dart';

part 'stock_split_dao.g.dart';

@DriftAccessor(tables: [StockSplits])
class StockSplitDao extends DatabaseAccessor<AppDatabase> with _$StockSplitDaoMixin {
  StockSplitDao(super.db);

  /// Get all stock splits for a specific symbol
  Future<List<StockSplit>> getSplitsForSymbol(String symbol) =>
      (select(stockSplits)
            ..where((s) => s.symbol.equals(symbol))
            ..orderBy([(s) => OrderingTerm.desc(s.splitDate)]))
          .get();

  /// Insert a stock split
  Future<int> insertSplit(StockSplitsCompanion split) =>
      into(stockSplits).insert(split);

  /// Delete a stock split
  Future<int> deleteSplit(String id) =>
      (delete(stockSplits)..where((s) => s.id.equals(id))).go();
}
