import 'package:drift/drift.dart';
import 'package:equity_echo/data/database/database.dart';
import 'package:equity_echo/data/models/holding.dart';
import 'package:equity_echo/core/utils/transaction_charges.dart';

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

  /// Compute holdings by iterating trades and splits chronologically.
  ///
  /// Charges are factored in:
  /// - BUY (non-IPO): investedPool += tradeValue * (1 + 1.12%)
  /// - BUY (IPO):      investedPool += tradeValue  (no charges)
  /// - SELL:            netProceeds = tradeValue * (1 − 1.12%); realizedGain += netProceeds − costBasis
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
          final totalCost = TransactionCharges.buyCost(
            event.totalValue,
            isIpo: event.isIpo,
          );
          state.currentQty += event.quantity;
          state.investedPool += totalCost;
          // Track raw buy value (no charges) for raw avg price
          state.rawBuyValue += event.totalValue;
          state.totalBoughtQty += event.quantity;
        } else if (event.action == 'sell') {
          final netProceeds = TransactionCharges.sellProceeds(event.totalValue);
          if (state.currentQty > 0) {
            double costBasisForSale =
                (event.quantity / state.currentQty) * state.investedPool;
            state.investedPool -= costBasisForSale;
            state.realizedGain += netProceeds - costBasisForSale;
          }
          state.currentQty -= event.quantity;
          state.totalSoldQty += event.quantity;
          state.totalSoldValue += netProceeds;
        }
      } else if (event is StockSplit) {
        final symbol = event.symbol;
        final state = holdingsMap.putIfAbsent(symbol, () => _SymbolState());

        int newQtyFloor =
            (state.currentQty * event.newShares) ~/ event.oldShares;
        state.currentQty = newQtyFloor.toDouble();
        // investedPool (cost basis) remains explicitly the same.
      }
    }

    final holdings = <Holding>[];
    for (var entry in holdingsMap.entries) {
      final symbol = entry.key;
      final state = entry.value;

      // Raw average price (without charges)
      final avgRawPrice = state.totalBoughtQty > 0
          ? state.rawBuyValue / state.totalBoughtQty
          : 0.0;

      // Average cost with charges
      final avgCostWithCharges = state.currentQty > 0
          ? state.investedPool / state.currentQty
          : 0.0;

      holdings.add(Holding(
        symbol: symbol,
        netQuantity: state.currentQty,
        avgBuyPrice: avgRawPrice,
        avgCostWithCharges: avgCostWithCharges,
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
    return customSelect('SELECT 1 FROM trades UNION SELECT 1 FROM stock_splits', readsFrom: {trades, stockSplits})
        .watch()
        .asyncMap((_) => getHoldings());
  }

  /// Get total invested (sum of all BUY costs including charges).
  /// IPO buys are included at raw value (no charges).
  Future<double> getTotalInvested() async {
    final buyTrades = await (select(trades)
          ..where((t) => t.action.equals('buy')))
        .get();
    double total = 0;
    for (final t in buyTrades) {
      total += TransactionCharges.buyCost(t.totalValue, isIpo: t.isIpo);
    }
    return total;
  }

  /// Get total sold value (sum of all SELL net proceeds after charges).
  Future<double> getTotalSold() async {
    final sellTrades = await (select(trades)
          ..where((t) => t.action.equals('sell')))
        .get();
    double total = 0;
    for (final t in sellTrades) {
      total += TransactionCharges.sellProceeds(t.totalValue);
    }
    return total;
  }
}

class _SymbolState {
  double currentQty = 0;
  double investedPool = 0; // charges-adjusted cost basis
  double realizedGain = 0;
  double totalSoldQty = 0;
  double totalSoldValue = 0; // net proceeds after charges
  double rawBuyValue = 0; // raw trade value of buys (no charges)
  double totalBoughtQty = 0; // total qty bought (for raw avg price)
}
