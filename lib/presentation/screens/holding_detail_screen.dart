import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:equity_echo/core/theme/app_theme.dart';
import 'package:equity_echo/core/di/injection.dart';
import 'package:equity_echo/data/database/database.dart';
import 'package:equity_echo/data/database/daos/trade_dao.dart';
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
  late Future<List<Trade>> _tradesFuture;

  @override
  void initState() {
    super.initState();
    _tradesFuture = getIt<TradeDao>().getTradesForSymbol(widget.symbol);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.symbol} Details'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/trade/new', extra: widget.symbol);
          if (!context.mounted) return;
          // Refresh trades timeline after we return
          setState(() {
            _tradesFuture = getIt<TradeDao>().getTradesForSymbol(widget.symbol);
          });
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
                      _StatRow('Total Invested', currencyFormatter.format(holding.totalInvested), color: AppTheme.buyGreen),
                      Divider(height: 24, color: AppTheme.divider),
                      _StatRow('Total Sold', currencyFormatter.format(holding.totalSoldValue), color: AppTheme.textSecondary),
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
                FutureBuilder<List<Trade>>(
                  future: _tradesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}', style: TextStyle(color: AppTheme.sellRed));
                    }

                    final trades = snapshot.data ?? [];
                    if (trades.isEmpty) {
                      return Text('No transactions found.', style: TextStyle(color: AppTheme.textSecondary));
                    }

                    return Column(
                      children: trades.map((trade) {
                        final isBuy = trade.action.toLowerCase() == 'buy';
                        final color = isBuy ? AppTheme.buyGreen : AppTheme.sellRed;
return GestureDetector(
                          onLongPress: () => _confirmDeleteTrade(context, trade),
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
                                    '${trade.quantity.toStringAsFixed(0)} shares',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'at ${currencyFormatter.format(trade.price)}',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    currencyFormatter.format(trade.totalValue),
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ));
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
              setState(() {
                _tradesFuture = getIt<TradeDao>().getTradesForSymbol(widget.symbol);
              });
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
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _StatRow(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
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
