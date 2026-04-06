import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:equity_echo/core/theme/app_theme.dart';
import 'package:equity_echo/core/di/injection.dart';
import 'package:equity_echo/core/utils/transaction_charges.dart';
import 'package:equity_echo/data/database/database.dart';
import 'package:equity_echo/data/database/daos/trade_dao.dart';
import 'package:equity_echo/data/database/daos/stock_split_dao.dart';
import 'package:equity_echo/data/database/daos/dividend_dao.dart';
import 'package:equity_echo/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:equity_echo/presentation/blocs/dashboard/dashboard_event.dart';
import 'package:equity_echo/presentation/blocs/dashboard/dashboard_state.dart';
import 'package:equity_echo/presentation/blocs/trade/trade_bloc.dart';
import 'package:equity_echo/presentation/blocs/trade/trade_event.dart';

import 'models/split_event_with_balance.dart';
import 'models/chart_data_point.dart';
import 'widgets/holding_timeline_chart.dart';
import 'widgets/holding_stats_card.dart';
import 'widgets/trade_card.dart';
import 'dialogs/adjust_holdings_dialog.dart';
import 'dialogs/add_split_dialog.dart';
import 'dialogs/convert_rights_dialog.dart';
import '../../widgets/delete_confirmation_dialog.dart';

class HoldingDetailScreen extends StatefulWidget {
  final String symbol;

  const HoldingDetailScreen({super.key, required this.symbol});

  @override
  State<HoldingDetailScreen> createState() => _HoldingDetailScreenState();
}

class _HoldingDetailScreenState extends State<HoldingDetailScreen> {
  late Future<Map<String, dynamic>> _eventsFuture;
  Set<String> _exemptIds = {};

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    setState(() {
      _eventsFuture = _fetchEvents();
    });
  }

  Future<Map<String, dynamic>> _fetchEvents() async {
    final trades = await getIt<TradeDao>().getTradesForSymbol(widget.symbol);
    final splits = await getIt<StockSplitDao>().getSplitsForSymbol(widget.symbol);
    final dividends = await getIt<DividendDao>().getDividendsForSymbol(widget.symbol);

    final tradeDataList = trades
        .map(
          (t) => TradeData(
            id: t.id,
            symbol: t.symbol,
            channelId: t.channelId,
            action: t.action,
            quantity: t.quantity,
            date: t.smsDate,
            isIpo: t.isIpo,
          ),
        )
        .toList();
    _exemptIds = TransactionCharges.findIntraDayExemptions(tradeDataList);

    final events = [...trades, ...splits, ...dividends];
    events.sort((a, b) {
      final dateA = (a is Trade) ? a.smsDate : ((a is StockSplit) ? a.splitDate : (a as Dividend).date);
      final dateB = (b is Trade) ? b.smsDate : ((b is StockSplit) ? b.splitDate : (b as Dividend).date);
      return dateA.compareTo(dateB);
    });

    double runningQty = 0;
    double lastKnownPrice = 0;
    double averageCost = 0;
    double netCashFlow = 0;
    List<dynamic> processedEvents = [];
    List<ChartDataPoint> chartDataPoints = [];

    for (var event in events) {
      if (event is Trade) {
        if (event.action.toLowerCase() == 'buy') {
          double totalCostBefore = runningQty * averageCost;
          double currentCost = event.quantity * event.price;
          runningQty += event.quantity;
          averageCost = runningQty > 0 ? (totalCostBefore + currentCost) / runningQty : 0;
          netCashFlow += currentCost;
        } else if (event.action.toLowerCase() == 'sell') {
          runningQty -= event.quantity;
          netCashFlow -= event.quantity * event.price;
        } else if (event.action.toLowerCase() == 'rights_convert') {
          runningQty -= event.quantity;
        }
        
        lastKnownPrice = event.price;
        
        ChartEventType chartType = ChartEventType.buy;
        String label = '';
        if (event.action.toLowerCase() == 'sell') {
          chartType = ChartEventType.sell;
        } else if (event.action.toLowerCase() == 'rights_convert') {
          chartType = ChartEventType.rightsConvert;
          label = 'Rights\nConverted';
        }
        
        chartDataPoints.add(ChartDataPoint(
          date: event.smsDate,
          runningQuantity: runningQty,
          price: lastKnownPrice,
          eventType: chartType,
          label: label,
          costBasisInvestment: runningQty * averageCost,
          netCashFlowInvestment: netCashFlow,
        ));
        
        processedEvents.add(event);
      } else if (event is StockSplit) {
        double beforeQty = runningQty;
        int newQtyFloor = (runningQty * event.newShares) ~/ event.oldShares;
        if (newQtyFloor > 0 && runningQty > 0) {
            averageCost = (runningQty * averageCost) / newQtyFloor;
        }
        runningQty = newQtyFloor.toDouble();
        
        chartDataPoints.add(ChartDataPoint(
          date: event.splitDate,
          runningQuantity: runningQty,
          price: lastKnownPrice,
          eventType: ChartEventType.split,
          label: 'Split ${event.oldShares}:${event.newShares}',
          costBasisInvestment: runningQty * averageCost,
          netCashFlowInvestment: netCashFlow,
        ));
        
        processedEvents.add(SplitEventWithBalance(
          split: event,
          beforeQty: beforeQty,
          afterQty: runningQty,
        ));
      } else if (event is Dividend) {
        netCashFlow -= event.amount;
        chartDataPoints.add(ChartDataPoint(
          date: event.date,
          runningQuantity: runningQty,
          price: lastKnownPrice,
          eventType: ChartEventType.dividend,
          label: 'Dividend ${event.amount.toStringAsFixed(2)}',
          costBasisInvestment: runningQty * averageCost,
          netCashFlowInvestment: netCashFlow,
        ));
        processedEvents.add(event);
      }
    }

    processedEvents.sort((a, b) {
      final dateA = (a is Trade) ? a.smsDate : ((a is SplitEventWithBalance) ? a.split.splitDate : (a as Dividend).date);
      final dateB = (b is Trade) ? b.smsDate : ((b is SplitEventWithBalance) ? b.split.splitDate : (b as Dividend).date);
      return dateB.compareTo(dateA);
    });

    return {
      'events': processedEvents,
      'chartData': chartDataPoints,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.symbol} Details'),
        actions: [
          if (widget.symbol.contains('.R'))
            IconButton(
              icon: const Icon(Icons.autorenew),
              onPressed: () =>
                  showConvertRightsDialog(context, widget.symbol, _loadEvents),
              tooltip: 'Convert Rights',
            ),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () =>
                showAdjustDialog(context, widget.symbol, _loadEvents),
            tooltip: 'Adjust Holdings',
          ),
          IconButton(
            icon: const Icon(Icons.call_split),
            onPressed: () =>
                showAddSplitDialog(context, widget.symbol, _loadEvents),
            tooltip: 'Add Sub-division',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/trade/new', extra: widget.symbol);
          if (!context.mounted) return;
          _loadEvents();
          context.read<DashboardBloc>().add(RefreshDashboard());
        },
        backgroundColor: AppTheme.accent,
        child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoaded) {
            final holding = state.holdings
                .where((h) => h.symbol == widget.symbol)
                .firstOrNull;
            if (holding == null) {
              return Center(
                child: Text(
                  'Holding not found.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }

            final currencyFormatter = NumberFormat.currency(
              symbol: '${state.currency} ',
              decimalDigits: 2,
            );

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                HoldingStatsCard(
                  holding: holding,
                  currencyFormatter: currencyFormatter,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Transaction History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                FutureBuilder<Map<String, dynamic>>(
                  future: _eventsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Text(
                        'Error: ${snapshot.error}',
                        style: TextStyle(color: AppTheme.sellRed),
                      );
                    }

                    final data = snapshot.data;
                    if (data == null) return const SizedBox.shrink();

                    final events = data['events'] as List<dynamic>;
                    final chartDataPoints = data['chartData'] as List<ChartDataPoint>;

                    return Column(
                      children: [
                        if (chartDataPoints.isNotEmpty) ...[
                          HoldingTimelineChart(
                            dataPoints: chartDataPoints,
                            currencyFormatter: currencyFormatter,
                            symbol: widget.symbol,
                          ),
                          const SizedBox(height: 24),
                        ],
                        if (events.isEmpty)
                          Text('No transactions found.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))
                        else
                          ...events.map((event) {
                            if (event is SplitEventWithBalance) {
                              return GestureDetector(
                                onLongPress: () => _confirmDeleteSplit(context, event.split),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.call_split, color: Colors.blueAccent, size: 20),
                                          const SizedBox(width: 8),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'SUB-DIVISION',
                                                style: TextStyle(
                                                  color: Colors.blueAccent,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                DateFormat('MMM dd, yyyy').format(event.split.splitDate),
                                                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Ratio ${event.split.oldShares} : ${event.split.newShares}',
                                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text(
                                                event.beforeQty.toStringAsFixed(0),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 14,
                                                  decoration: TextDecoration.lineThrough,
                                                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              const Icon(Icons.arrow_forward, size: 12, color: Colors.blueAccent),
                                              const SizedBox(width: 6),
                                              Text(
                                                event.afterQty.toStringAsFixed(0),
                                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            } else if (event is Dividend) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.monetization_on, color: Colors.purpleAccent, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('DIVIDEND', style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.w700)),
                                          const SizedBox(height: 4),
                                          Text(
                                            DateFormat('MMM dd, yyyy').format(event.date),
                                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '+ ${currencyFormatter.format(event.amount)}',
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.purpleAccent),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final trade = event as Trade;
                            return TradeCard(
                              trade: trade,
                              currentSymbol: widget.symbol,
                              currencyFormatter: currencyFormatter,
                              isExempt: _exemptIds.contains(trade.id),
                              onDelete: () => _confirmDeleteTrade(context, trade),
                            );
                          }),
                      ],
                    );
                  },
                ),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Future<void> _confirmDeleteTrade(BuildContext context, Trade trade) async {
    final result = await DeleteConfirmationDialog.show(
      context,
      title: 'Delete Transaction',
      content: 'Are you sure you want to delete this transaction?',
    );

    if (result != null && result.confirmed) {
      if (!context.mounted) return;
      context.read<TradeBloc>().add(
        DeleteTrade(
          trade.id,
          reason: result.reason,
          reasonOther: result.reasonOther,
        ),
      );
      context.read<DashboardBloc>().add(RefreshDashboard());
      _loadEvents();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Transaction deleted')));
    }
  }

  Future<void> _confirmDeleteSplit(
    BuildContext context,
    StockSplit split,
  ) async {
    final result = await DeleteConfirmationDialog.show(
      context,
      title: 'Delete Sub-division',
      content: 'Are you sure you want to delete this sub-division event?',
    );

    if (result != null && result.confirmed) {
      if (!context.mounted) return;
      await getIt<StockSplitDao>().deleteSplit(
        split.id,
        reason: result.reason,
        reasonOther: result.reasonOther,
      );
      if (!context.mounted) return;
      context.read<DashboardBloc>().add(RefreshDashboard());
      _loadEvents();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sub-division deleted')));
    }
  }
}
