import 'package:drift/drift.dart';
import 'package:equity_echo/data/database/database.dart';

part 'dividend_dao.g.dart';

@DriftAccessor(tables: [Dividends])
class DividendDao extends DatabaseAccessor<AppDatabase>
    with _$DividendDaoMixin {
  DividendDao(super.db);

  /// Get all dividends
  Future<List<Dividend>> getAllDividends() =>
      (select(dividends)
            ..where((d) => d.isDeleted.equals(false))
            ..orderBy([(d) => OrderingTerm.desc(d.date)]))
          .get();

  /// Watch all dividends (reactive)
  Stream<List<Dividend>> watchAllDividends() =>
      (select(dividends)
            ..where((d) => d.isDeleted.equals(false))
            ..orderBy([(d) => OrderingTerm.desc(d.date)]))
          .watch();

  /// Get all dividends for a specific symbol
  Future<List<Dividend>> getDividendsForSymbol(String symbol) =>
      (select(dividends)
            ..where((d) => d.isDeleted.equals(false) & d.symbol.equals(symbol))
            ..orderBy([(d) => OrderingTerm.desc(d.date)]))
          .get();

  /// Insert a dividend
  Future<int> insertDividend(DividendsCompanion dividend) =>
      into(dividends).insert(dividend);

  Future<int> deleteDividend(
    String id, {
    String? reason,
    String? reasonOther,
  }) async {
    return (update(dividends)..where((d) => d.id.equals(id))).write(
      DividendsCompanion(
        isDeleted: const Value(true),
        deleteReason: Value(reason),
        deleteReasonOther: Value(reasonOther),
      ),
    );
  }

  /// Restore a dividend
  Future<int> restoreDividend(String id) async {
    return (update(dividends)..where((d) => d.id.equals(id))).write(
      const DividendsCompanion(
        isDeleted: Value(false),
        deleteReason: Value(null),
        deleteReasonOther: Value(null),
      ),
    );
  }

  /// Get deleted dividends
  Future<List<Dividend>> getDeletedDividends() =>
      (select(dividends)
            ..where((d) => d.isDeleted.equals(true))
            ..orderBy([(d) => OrderingTerm.desc(d.date)]))
          .get();

  /// Get total dividends
  Future<double> getTotalDividends() async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(amount), 0.0) as total FROM dividends WHERE is_deleted = 0',
      readsFrom: {dividends},
    ).getSingle();
    return result.read<double>('total');
  }
}
