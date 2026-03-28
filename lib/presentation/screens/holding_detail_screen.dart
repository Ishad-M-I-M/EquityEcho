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
    final splits = await getIt<StockSplitDao>().getSplitsForSymbol(widget.symbol);

    // Compute intra-day exemptions for this symbol's trades
    final tradeDataList = trades
        .map((t) => TradeData(
              id: t.id,
              symbol: t.symbol,
              channelId: t.channelId,
              action: t.action,
              quantity: t.quantity,
              date: t.smsDate,
              isIpo: t.isIpo,
            ))
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
        processedEvents.add(_SplitEventWithBalance(
          split: event,
          beforeQty: beforeQty,
          afterQty: runningQty,
        ));
      }
    }

    processedEvents.sort((a, b) {
      final dateA = (a is Trade) ? a.smsDate : (a as _SplitEventWithBalance).split.splitDate;
      final dateB = (b is Trade) ? b.smsDate : (b as _SplitEventWithBalance).split.splitDate;
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
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => _showAdjustDialog(context),
            tooltip: 'Adjust Holdings',
          ),
          IconButton(
            icon: const Icon(Icons.call_split),
            onPressed: () => _showAddSplitDialog(context),
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
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoaded) {
            final holding = state.holdings.where((h) => h.symbol == widget.symbol).firstOrNull;
            if (holding == null) {
              return Center(
                child: Text('Holding not found.', style: TextStyle(color: AppTheme.textSecondary)),
              );
            }

            final currencyFormatter = NumberFormat.currency(
              symbol: '${state.currency} ',
              decimalDigits: 2,
            );

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Top stats card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Column(
                    children: [
                      _StatRow('Net Quantity', '${holding.netQuantity.toStringAsFixed(0)} shares'),
                      Divider(height: 24, color: AppTheme.divider),
                      _StatRow('Average Price', currencyFormatter.format(holding.avgBuyPrice)),
                      Divider(height: 24, color: AppTheme.divider),
                      _StatRow('Average Cost', currencyFormatter.format(holding.avgCostWithCharges),
                          subtitle: 'incl. charges'),
                      Divider(height: 24, color: AppTheme.divider),
                      _StatRow('Total Invested', currencyFormatter.format(holding.totalInvested),
                          color: AppTheme.buyGreen, subtitle: 'incl. charges'),
                      Divider(height: 24, color: AppTheme.divider),
                      _StatRow('Total Sold', currencyFormatter.format(holding.totalSoldValue),
                          color: AppTheme.textSecondary, subtitle: 'net of charges'),
                      Divider(height: 24, color: AppTheme.divider),
                      _StatRow(
                        'Realized Gain',
                        currencyFormatter.format(holding.realizedGain),
                        color: holding.realizedGain >= 0 ? AppTheme.accent : AppTheme.sellRed,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Transaction History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                FutureBuilder<List<dynamic>>(
                  future: _eventsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}', style: TextStyle(color: AppTheme.sellRed));
                    }

                    final events = snapshot.data ?? [];
                    if (events.isEmpty) {
                      return Text('No transactions found.', style: TextStyle(color: AppTheme.textSecondary));
                    }

                    return Column(
                      children: events.map((event) {
                        // Stock sub-division event
                        if (event is _SplitEventWithBalance) {
                          return GestureDetector(
                            onLongPress: () => _confirmDeleteSplit(context, event.split),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceDark,
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
                                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
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
                                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            event.beforeQty.toStringAsFixed(0),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                              decoration: TextDecoration.lineThrough,
                                              color: Colors.white54,
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
                        }

                        // Trade event — expandable card
                        final trade = event as Trade;
                        return _TradeCard(
                          trade: trade,
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

  void _confirmDeleteTrade(BuildContext context, Trade trade) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<TradeBloc>().add(DeleteTrade(trade.id));
              context.read<DashboardBloc>().add(RefreshDashboard());
              _loadEvents();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Transaction scheduled for deletion')),
              );
            },
            child: Text('Delete', style: TextStyle(color: AppTheme.sellRed)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSplit(BuildContext context, StockSplit split) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Delete Sub-division'),
        content: const Text('Are you sure you want to delete this sub-division event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await getIt<StockSplitDao>().deleteSplit(split.id);
              if (!context.mounted) return;
              context.read<DashboardBloc>().add(RefreshDashboard());
              _loadEvents();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sub-division deleted')),
              );
            },
            child: Text('Delete', style: TextStyle(color: AppTheme.sellRed)),
          ),
        ],
      ),
    );
  }

  void _showAdjustDialog(BuildContext context) {
    final qtyController = TextEditingController();
    final priceController = TextEditingController();

    // Get current tracked holding state
    final dashState = context.read<DashboardBloc>().state;
    final currentHolding = dashState is DashboardLoaded
        ? dashState.holdings.where((h) => h.symbol == widget.symbol).firstOrNull
        : null;
    final currentQty = currentHolding?.netQuantity ?? 0.0;
    final currentAvgCost = currentHolding?.avgCostWithCharges ?? 0.0;
    final currentPool = currentQty * currentAvgCost;
    const channelId = 'other';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final targetQty = double.tryParse(qtyController.text) ?? 0;
            final targetAvgPrice = double.tryParse(priceController.text) ?? 0;
            final targetPool = targetQty * targetAvgPrice;

            final diffQty = targetQty - currentQty;
            final diffValue = targetPool - currentPool;

            final hasDiff = diffQty != 0 && targetAvgPrice > 0;
            double effectiveAdjPrice = 0;
            bool isAddition = false;
            bool isValid = false;

            if (hasDiff) {
              effectiveAdjPrice = diffValue / diffQty;
              isAddition = diffQty > 0;
              isValid = effectiveAdjPrice > 0;
            }

            ChargesBreakdown? breakdown;
            double rawAdjPrice = 0;
            double adjustmentTotalValueForRecord = 0;

            if (isValid) {
              rawAdjPrice = isAddition
                  ? effectiveAdjPrice / (1 + TransactionCharges.totalRate)
                  : effectiveAdjPrice / (1 - TransactionCharges.totalRate);
              adjustmentTotalValueForRecord = diffQty.abs() * rawAdjPrice;
              breakdown = TransactionCharges.compute(adjustmentTotalValueForRecord);
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.85,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.textSecondary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.tune, color: AppTheme.accent, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Adjust ${widget.symbol} Holdings',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Correct your tracked portfolio to match your actual statement.',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Current state: ${currentQty.toStringAsFixed(0)} shares @ ${currentAvgCost.toStringAsFixed(2)} average',
                              style: TextStyle(
                                color: AppTheme.textSecondary.withValues(alpha: 0.7),
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: qtyController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Target Total Quantity',
                                hintText: 'Enter your total shares...',
                              ),
                              onChanged: (_) => setSheetState(() {}),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: priceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Target Average Cost (incl. charges)',
                                hintText: 'Enter your statement average...',
                              ),
                              onChanged: (_) => setSheetState(() {}),
                            ),
                            const SizedBox(height: 20),

                            // Preview
                            if (isValid) ...[
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: (isAddition ? AppTheme.buyGreen : AppTheme.sellRed)
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: (isAddition ? AppTheme.buyGreen : AppTheme.sellRed)
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          isAddition
                                              ? 'Adjustment: Addition'
                                              : 'Adjustment: Removal',
                                          style: TextStyle(
                                            color: isAddition ? AppTheme.buyGreen : AppTheme.sellRed,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          '${diffQty.abs().toStringAsFixed(0)} shares @ ${effectiveAdjPrice.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isAddition
                                          ? 'Creating a BUY entry to increase cost basis to your target.'
                                          : 'Creating a SELL entry to reduce holdings and cost basis.',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Divider(height: 20, color: AppTheme.divider),
                                    _detailRow(
                                      'Raw Trade Value',
                                      adjustmentTotalValueForRecord.toStringAsFixed(2),
                                    ),
                                    _detailRow(
                                      'Applicable Charges (1.12%)',
                                      breakdown!.totalCharges.toStringAsFixed(2),
                                      color: AppTheme.warning,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          isAddition ? 'Net Addition Value' : 'Net Removal Value',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          (isAddition
                                                  ? TransactionCharges.buyCost(adjustmentTotalValueForRecord)
                                                  : TransactionCharges.sellProceeds(adjustmentTotalValueForRecord))
                                              .toStringAsFixed(2),
                                          style: TextStyle(
                                            color: isAddition ? AppTheme.buyGreen : AppTheme.sellRed,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ] else if (hasDiff && !isValid) ...[
                              Container(
                                padding: const EdgeInsets.all(14),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppTheme.sellRed.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.error_outline, color: AppTheme.sellRed, size: 18),
                                        const SizedBox(width: 8),
                                        const Text('Impossible Adjustment',
                                            style: TextStyle(fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'The target states requires increasing quantity while decreasing total value (or vice-versa), which cannot be mapped to a single trade. Please check your targets.',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else if (targetQty > 0 && targetAvgPrice > 0 && diffQty == 0) ...[
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppTheme.accent.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle, color: AppTheme.accent, size: 18),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text('Current quantity matches target. No shares to add or remove.'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),

                            // Submit button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isValid
                                    ? () {
                                        Navigator.pop(sheetCtx);
                                        context.read<TradeBloc>().add(AddTrade(
                                              channelId: channelId,
                                              action: isAddition ? 'buy' : 'sell',
                                              symbol: widget.symbol,
                                              quantity: diffQty.abs(),
                                              price: rawAdjPrice,
                                              smsDate: DateTime.now(),
                                              isManual: true,
                                              isAdjustment: true,
                                            ));
                                        context.read<DashboardBloc>().add(RefreshDashboard());
                                        _loadEvents();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Adjustment: Created ${isAddition ? "BUY" : "SELL"} entry for ${diffQty.abs().toStringAsFixed(0)} shares.',
                                            ),
                                          ),
                                        );
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isValid
                                      ? (isAddition ? AppTheme.buyGreen : AppTheme.sellRed)
                                      : AppTheme.divider,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  isValid ? 'Apply Adjustment' : 'Invalid Targets',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          Text(value,
              style: TextStyle(
                  color: color ?? AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showAddSplitDialog(BuildContext context) {
    DateTime selectedDate = DateTime.now();
    final oldSharesController = TextEditingController();
    final newSharesController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setStateLocal) {
            return AlertDialog(
              backgroundColor: AppTheme.cardDark,
              title: Text('Sub-division for ${widget.symbol}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Date'),
                    subtitle: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                    trailing: const Icon(Icons.calendar_today, size: 20),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setStateLocal(() => selectedDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: oldSharesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Old Shares',
                      hintText: 'e.g. 10',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: newSharesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'New Shares',
                      hintText: 'e.g. 1',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rule: 10 old into 1 new => Ratio 10:1',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                ),
                TextButton(
                  onPressed: () async {
                    final oldS = int.tryParse(oldSharesController.text);
                    final newS = int.tryParse(newSharesController.text);
                    if (oldS == null || newS == null || oldS <= 0 || newS <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter valid integers')),
                      );
                      return;
                    }

                    Navigator.pop(dialogCtx);

                    final companion = StockSplitsCompanion.insert(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      symbol: widget.symbol,
                      splitDate: selectedDate,
                      oldShares: oldS,
                      newShares: newS,
                    );
                    await getIt<StockSplitDao>().insertSplit(companion);

                    if (!context.mounted) return;
                    _loadEvents();
                    context.read<DashboardBloc>().add(RefreshDashboard());
                  },
                  child: Text('Save', style: TextStyle(color: AppTheme.accent)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ─── Trade Card (expandable) ───────────────────────────────────────────────

class _TradeCard extends StatefulWidget {
  final Trade trade;
  final NumberFormat currencyFormatter;
  final VoidCallback onDelete;
  final bool isExempt;

  const _TradeCard({
    required this.trade,
    required this.currencyFormatter,
    required this.onDelete,
    this.isExempt = false,
  });

  @override
  State<_TradeCard> createState() => _TradeCardState();
}

class _TradeCardState extends State<_TradeCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final trade = widget.trade;
    final fmt = widget.currencyFormatter;
    final isBuy = trade.action.toLowerCase() == 'buy';
    final color = isBuy ? AppTheme.buyGreen : AppTheme.sellRed;
    final isIpo = trade.isIpo;
    final isExempt = widget.isExempt;
    final hasCharges = !isIpo || !isBuy; // sells always have charges
    final breakdown = hasCharges
        ? (isExempt
            ? TransactionCharges.computeExempt(trade.totalValue)
            : TransactionCharges.compute(trade.totalValue))
        : null;

    // Effective total: what you actually pay (buy) or receive (sell)
    final effectiveTotal = isBuy
        ? TransactionCharges.buyCost(trade.totalValue, isIpo: isIpo, isExempt: isExempt)
        : TransactionCharges.sellProceeds(trade.totalValue, isExempt: isExempt);

    return GestureDetector(
      onTap: hasCharges ? () => setState(() => _expanded = !_expanded) : null,
      onLongPress: widget.onDelete,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Main trade row
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isBuy ? Icons.arrow_downward : Icons.arrow_upward,
                            color: color,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isBuy ? 'BOUGHT' : 'SOLD',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (isIpo) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.purple.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'IPO',
                                style: TextStyle(
                                  color: Colors.purple,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                          if (isExempt) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.teal.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'INTRA-DAY',
                                style: TextStyle(
                                  color: Colors.teal,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ],
                          if (trade.isAdjustment) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'ADJUSTMENT',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        DateFormat('MMM dd, yyyy').format(trade.smsDate),
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${trade.quantity.toStringAsFixed(0)} × ${fmt.format(trade.price)}',
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fmt.format(effectiveTotal),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      if (hasCharges) ...[
                        const SizedBox(height: 2),
                        Text(
                          isBuy ? 'Total Cost' : 'Net Proceeds',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Expand indicator
            if (hasCharges && !_expanded)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: AppTheme.textSecondary.withValues(alpha: 0.5),
                ),
              ),

            // Expandable charges breakdown
            if (hasCharges && _expanded && breakdown != null) ...[
              Divider(height: 1, color: AppTheme.divider),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Column(
                  children: [
                    _TradeChargeRow('Trade Value', '', trade.totalValue, fmt, isHeader: true),
                    const SizedBox(height: 4),
                    _TradeChargeRow('Brokerage Fee', '0.640%', breakdown.brokerageFee, fmt),
                    _TradeChargeRow('CSE Fees', '0.084%', breakdown.cseFee, fmt),
                    _TradeChargeRow('CDS Fees', '0.024%', breakdown.cdsFee, fmt),
                    _TradeChargeRow('SEC Cess', '0.072%', breakdown.secCess, fmt),
                    _TradeChargeRow('Share Trans. Levy', '0.300%', breakdown.shareTransactionLevy, fmt),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Charges',
                          style: TextStyle(
                            color: AppTheme.warning,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          fmt.format(breakdown.totalCharges),
                          style: TextStyle(
                            color: AppTheme.warning,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isBuy ? 'Total Cost' : 'Net Proceeds',
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          fmt.format(effectiveTotal),
                          style: TextStyle(
                            color: color,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Icon(
                  Icons.keyboard_arrow_up,
                  size: 16,
                  color: AppTheme.textSecondary.withValues(alpha: 0.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Helper widgets ────────────────────────────────────────────────────────

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final String? subtitle;

  const _StatRow(this.label, this.value, {this.color, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.6), fontSize: 10),
              ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

class _TradeChargeRow extends StatelessWidget {
  final String label;
  final String rate;
  final double amount;
  final NumberFormat formatter;
  final bool isHeader;

  const _TradeChargeRow(this.label, this.rate, this.amount, this.formatter,
      {this.isHeader = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isHeader ? Colors.white70 : AppTheme.textSecondary,
                  fontSize: isHeader ? 12 : 11,
                  fontWeight: isHeader ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              if (rate.isNotEmpty) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    rate,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
          Text(
            formatter.format(amount),
            style: TextStyle(
              color: isHeader ? Colors.white70 : AppTheme.textSecondary,
              fontSize: isHeader ? 12 : 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _SplitEventWithBalance {
  final StockSplit split;
  final double beforeQty;
  final double afterQty;

  _SplitEventWithBalance({
    required this.split,
    required this.beforeQty,
    required this.afterQty,
  });
}
