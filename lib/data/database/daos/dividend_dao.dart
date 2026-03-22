import 'package:drift/drift.dart';
import 'package:equity_echo/data/database/database.dart';

part 'dividend_dao.g.dart';

@DriftAccessor(tables: [Dividends])
class DividendDao extends DatabaseAccessor<AppDatabase> with _$DividendDaoMixin {
  DividendDao(super.db);

  /// Get all dividends
  Future<List<Dividend>> getAllDividends() =>
      (select(dividends)..orderBy([(d) => OrderingTerm.desc(d.date)])).get();

  /// Watch all dividends (reactive)
  Stream<List<Dividend>> watchAllDividends() =>
      (select(dividends)..orderBy([(d) => OrderingTerm.desc(d.date)])).watch();

  /// Get all dividends for a specific symbol
  Future<List<Dividend>> getDividendsForSymbol(String symbol) =>
      (select(dividends)
            ..where((d) => d.symbol.equals(symbol))
            ..orderBy([(d) => OrderingTerm.desc(d.date)]))
          .get();

  /// Insert a dividend
  Future<int> insertDividend(DividendsCompanion dividend) =>
      into(dividends).insert(dividend);

  /// Delete a dividend
  Future<int> deleteDividend(String id) =>
      (delete(dividends)..where((d) => d.id.equals(id))).go();

  /// Get total dividends
  Future<double> getTotalDividends() async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(amount), 0.0) as total FROM dividends',
      readsFrom: {dividends},
    ).getSingle();
    return result.read<double>('total');
  }
}
