import 'package:drift/drift.dart';
import 'package:equity_echo/data/database/database.dart';
import 'package:equity_echo/data/models/holding.dart';

part 'trade_dao.g.dart';

@DriftAccessor(tables: [Trades, StockSplits])
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

  /// Compute holdings natively by iterating trades and splits chronologically.
  Future<List<Holding>> getHoldings() async {
    final allTrades = await (select(trades)..orderBy([(t) => OrderingTerm.asc(t.smsDate)])).get();
    final allSplits = await (select(stockSplits)..orderBy([(s) => OrderingTerm.asc(s.splitDate)])).get();

    final List<dynamic> events = [...allTrades, ...allSplits];
    events.sort((a, b) {
      final dateA = (a is Trade) ? a.smsDate : (a as StockSplit).splitDate;
      final dateB = (b is Trade) ? b.smsDate : (b as StockSplit).splitDate;
      return dateA.compareTo(dateB);
    });

    final holdingsMap = <String, _SymbolState>{};

    for (var event in events) {
      if (event is Trade) {
        final symbol = event.symbol;
        final state = holdingsMap.putIfAbsent(symbol, () => _SymbolState());
        
        if (event.action == 'buy') {
          state.currentQty += event.quantity;
          state.investedPool += event.totalValue;
        } else if (event.action == 'sell') {
          if (state.currentQty > 0) {
            double costBasisForSale = (event.quantity / state.currentQty) * state.investedPool;
            state.investedPool -= costBasisForSale;
            state.realizedGain += event.totalValue - costBasisForSale;
          }
          state.currentQty -= event.quantity;
          state.totalSoldQty += event.quantity;
          state.totalSoldValue += event.totalValue;
        }
      } else if (event is StockSplit) {
        final symbol = event.symbol;
        final state = holdingsMap.putIfAbsent(symbol, () => _SymbolState());
        
        int newQtyFloor = (state.currentQty * event.newShares) ~/ event.oldShares;
        state.currentQty = newQtyFloor.toDouble();
        // investedPool (cost basis) remains explicitly the same. Note: Do not alter investedPool.
      }
    }

    final holdings = <Holding>[];
    for (var entry in holdingsMap.entries) {
      final symbol = entry.key;
      final state = entry.value;

      final avgPrice = state.currentQty > 0 ? state.investedPool / state.currentQty : 0.0;

      holdings.add(Holding(
        symbol: symbol,
        netQuantity: state.currentQty,
        avgBuyPrice: avgPrice,
        totalInvested: state.investedPool,
        totalSoldQuantity: state.totalSoldQty,
        totalSoldValue: state.totalSoldValue,
        realizedGain: state.realizedGain,
      ));
    }

    holdings.sort((a, b) => a.symbol.compareTo(b.symbol));
    return holdings;
  }

  /// Watch holdings (reactive)
  Stream<List<Holding>> watchHoldings() {
    // We can't use RxCombine easily without rxdart, but Drift allows watching multiple tables.
    // Instead, using customSelect to listen, then calling getHoldings()
    return customSelect('SELECT 1 FROM trades UNION SELECT 1 FROM stock_splits', readsFrom: {trades, stockSplits})
        .watch()
        .asyncMap((_) => getHoldings());
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

class _SymbolState {
  double currentQty = 0;
  double investedPool = 0;
  double realizedGain = 0;
  double totalSoldQty = 0;
  double totalSoldValue = 0;
}
