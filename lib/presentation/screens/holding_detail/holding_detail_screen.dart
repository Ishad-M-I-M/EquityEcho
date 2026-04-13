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
import 'package:equity_echo/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:equity_echo/presentation/blocs/dashboard/dashboard_event.dart';
import 'package:equity_echo/presentation/blocs/dashboard/dashboard_state.dart';
import 'package:equity_echo/presentation/blocs/trade/trade_bloc.dart';
import 'package:equity_echo/presentation/blocs/trade/trade_event.dart';

import 'models/split_event_with_balance.dart';
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
  late Future<List<dynamic>> _eventsFuture;
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

  Future<List<dynamic>> _fetchEvents() async {
    final trades = await getIt<TradeDao>().getTradesForSymbol(widget.symbol);
    final splits = await getIt<StockSplitDao>().getSplitsForSymbol(
      widget.symbol,
    );

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

    final events = [...trades, ...splits];
    events.sort((a, b) {
      final dateA = (a is Trade) ? a.smsDate : (a as StockSplit).splitDate;
      final dateB = (b is Trade) ? b.smsDate : (b as StockSplit).splitDate;
      return dateA.compareTo(dateB);
    });

    double runningQty = 0;
    List<dynamic> processedEvents = [];

    for (var event in events) {
      if (event is Trade) {
        if (event.action.toLowerCase() == 'buy') {
          runningQty += event.quantity;
        } else if (event.action.toLowerCase() == 'sell') {
          runningQty -= event.quantity;
        }
        processedEvents.add(event);
      } else if (event is StockSplit) {
        double beforeQty = runningQty;
        int newQtyFloor = (runningQty * event.newShares) ~/ event.oldShares;
        runningQty = newQtyFloor.toDouble();
        processedEvents.add(
          SplitEventWithBalance(
            split: event,
            beforeQty: beforeQty,
            afterQty: runningQty,
          ),
        );
      }
    }

    processedEvents.sort((a, b) {
      final dateA = (a is Trade)
          ? a.smsDate
          : (a as SplitEventWithBalance).split.splitDate;
      final dateB = (b is Trade)
          ? b.smsDate
          : (b as SplitEventWithBalance).split.splitDate;
      return dateB.compareTo(dateA);
    });

    return processedEvents;
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
                FutureBuilder<List<dynamic>>(
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

                    final events = snapshot.data ?? [];
                    if (events.isEmpty) {
                      return Text(
                        'No transactions found.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      );
                    }

                    return Column(
                      children: events.map((event) {
                        if (event is SplitEventWithBalance) {
                          return GestureDetector(
                            onLongPress: () =>
                                _confirmDeleteSplit(context, event.split),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.call_split,
                                        color: Colors.blueAccent,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                            DateFormat(
                                              'MMM dd, yyyy',
                                            ).format(event.split.splitDate),
                                            style: TextStyle(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                              fontSize: 12,
                                            ),
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
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            event.beforeQty.toStringAsFixed(0),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                              decoration:
                                                  TextDecoration.lineThrough,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant
                                                  .withValues(alpha: 0.6),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Icon(
                                            Icons.arrow_forward,
                                            size: 12,
                                            color: Colors.blueAccent,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            event.afterQty.toStringAsFixed(0),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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
                      }).toList(),
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
