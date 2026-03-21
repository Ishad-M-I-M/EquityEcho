import 'package:drift/drift.dart';
import 'package:equity_echo/data/database/database.dart';
import 'package:equity_echo/data/models/holding.dart';

part 'trade_dao.g.dart';

@DriftAccessor(tables: [Trades])
class TradeDao extends DatabaseAccessor<AppDatabase> with _$TradeDaoMixin {
  TradeDao(super.db);

  /// Get all trades, newest first
  Future<List<Trade>> getAllTrades() =>
      (select(trades)..orderBy([(t) => OrderingTerm.desc(t.smsDate)])).get();

  /// Watch all trades (reactive)
  Stream<List<Trade>> watchAllTrades() =>
      (select(trades)..orderBy([(t) => OrderingTerm.desc(t.smsDate)])).watch();

  /// Get trades for a specific symbol
  Future<List<Trade>> getTradesForSymbol(String symbol) =>
      (select(trades)
            ..where((t) => t.symbol.equals(symbol))
            ..orderBy([(t) => OrderingTerm.desc(t.smsDate)]))
          .get();

  /// Get trades for a specific channel
  Future<List<Trade>> getTradesForChannel(String channelId) =>
      (select(trades)
            ..where((t) => t.channelId.equals(channelId))
            ..orderBy([(t) => OrderingTerm.desc(t.smsDate)]))
          .get();

  /// Insert a trade
  Future<int> insertTrade(TradesCompanion trade) =>
      into(trades).insert(trade);

  /// Update a trade
  Future<bool> updateTrade(Trade trade) => update(trades).replace(trade);

  /// Delete a trade
  Future<int> deleteTrade(String id) =>
      (delete(trades)..where((t) => t.id.equals(id))).go();

  /// Delete all trades (for resync)
  Future<int> deleteAllTrades() => delete(trades).go();

  /// Check if a trade with the same SMS body + received date exists (dedup)
  Future<bool> existsByRawSms(String rawSmsBody, DateTime smsReceivedDate) async {
    final results = await (select(trades)
          ..where(
              (t) => t.rawSmsBody.equals(rawSmsBody) & t.smsReceivedDate.equals(smsReceivedDate)))
        .get();
    return results.isNotEmpty;
  }

  /// Compute holdings using weighted average.
  /// Groups buy trades by symbol to calculate total quantity and average price,
  /// then separately sums sell quantities and values.
  Future<List<Holding>> getHoldings() async {
    // Get all buy trades grouped by symbol
    final buyQuery = customSelect(
      'SELECT symbol, '
      'SUM(quantity) as total_qty, '
      'SUM(total_value) as total_invested '
      'FROM trades WHERE action = ? '
      'GROUP BY symbol',
      variables: [Variable.withString('buy')],
      readsFrom: {trades},
    );

    final buyResults = await buyQuery.get();

    // Get all sell trades grouped by symbol
    final sellQuery = customSelect(
      'SELECT symbol, '
      'SUM(quantity) as total_qty, '
      'SUM(total_value) as total_value '
      'FROM trades WHERE action = ? '
      'GROUP BY symbol',
      variables: [Variable.withString('sell')],
      readsFrom: {trades},
    );

    final sellResults = await sellQuery.get();

    // Build a map of sell data
    final sellMap = <String, ({double qty, double value})>{};
    for (final row in sellResults) {
      final symbol = row.read<String>('symbol');
      sellMap[symbol] = (
        qty: row.read<double>('total_qty'),
        value: row.read<double>('total_value'),
      );
    }

    // Build holdings list
    final holdings = <Holding>[];
    for (final row in buyResults) {
      final symbol = row.read<String>('symbol');
      final totalQty = row.read<double>('total_qty');
      final totalInvested = row.read<double>('total_invested');
      final avgPrice = totalQty > 0 ? totalInvested / totalQty : 0.0;

      final sell = sellMap[symbol];

      holdings.add(Holding(
        symbol: symbol,
        totalQuantity: totalQty,
        avgBuyPrice: avgPrice,
        totalInvested: totalInvested,
        totalSoldQuantity: sell?.qty ?? 0.0,
        totalSoldValue: sell?.value ?? 0.0,
      ));
    }

    // Sort by symbol
    holdings.sort((a, b) => a.symbol.compareTo(b.symbol));

    return holdings;
  }

  /// Watch holdings (reactive)
  Stream<List<Holding>> watchHoldings() {
    return (select(trades)).watch().asyncMap((_) => getHoldings());
  }

  /// Get total invested (sum of all BUY trades)
  Future<double> getTotalInvested() async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(total_value), 0.0) as total FROM trades WHERE action = ?',
      variables: [Variable.withString('buy')],
      readsFrom: {trades},
    ).getSingle();
    return result.read<double>('total');
  }

  /// Get total sold value (sum of all SELL trades)
  Future<double> getTotalSold() async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(total_value), 0.0) as total FROM trades WHERE action = ?',
      variables: [Variable.withString('sell')],
      readsFrom: {trades},
    ).getSingle();
    return result.read<double>('total');
  }
}
