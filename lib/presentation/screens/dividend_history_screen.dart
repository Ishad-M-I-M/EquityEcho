import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:equity_echo/core/theme/app_theme.dart';
import 'package:equity_echo/core/di/injection.dart';
import 'package:equity_echo/data/database/database.dart';
import 'package:equity_echo/data/database/daos/dividend_dao.dart';
import 'package:equity_echo/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:equity_echo/presentation/blocs/dashboard/dashboard_state.dart';
import 'package:equity_echo/presentation/blocs/dashboard/dashboard_event.dart';

class DividendHistoryScreen extends StatefulWidget {
  final String symbol;

  const DividendHistoryScreen({super.key, required this.symbol});

  @override
  State<DividendHistoryScreen> createState() => _DividendHistoryScreenState();
}

class _DividendHistoryScreenState extends State<DividendHistoryScreen> {
  late Future<List<Dividend>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    setState(() {
      _historyFuture = getIt<DividendDao>().getDividendsForSymbol(widget.symbol);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.symbol} Dividends'),
      ),
      body: FutureBuilder<List<Dividend>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: AppTheme.sellRed)));
          }

          final dividends = snapshot.data ?? [];
          if (dividends.isEmpty) {
            return Center(
              child: Text(
                'No dividend history found.',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16),
              ),
            );
          }

          return BlocBuilder<DashboardBloc, DashboardState>(
            builder: (context, dashboardState) {
              String currencySymbol = 'LKR ';
              if (dashboardState is DashboardLoaded) {
                currencySymbol = '${dashboardState.currency} ';
              }
              final currencyFormatter = NumberFormat.currency(
                symbol: currencySymbol,
                decimalDigits: 2,
              );

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: dividends.length,
                itemBuilder: (context, index) {
                  final div = dividends[index];

                  return GestureDetector(
                    onLongPress: () => _confirmDeleteDividend(context, div),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.buyGreen.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.arrow_downward, color: AppTheme.buyGreen, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'RECEIVED',
                                    style: TextStyle(
                                      color: AppTheme.buyGreen,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('MMM dd, yyyy').format(div.date),
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Text(
                            currencyFormatter.format(div.amount),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.buyGreen,
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
        },
      ),
    );
  }

  void _confirmDeleteDividend(BuildContext context, Dividend div) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Delete Dividend'),
        content: const Text('Are you sure you want to delete this dividend payout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await getIt<DividendDao>().deleteDividend(div.id);
              if (!context.mounted) return;
              context.read<DashboardBloc>().add(RefreshDashboard());
              _loadHistory();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Dividend deleted')),
              );
            },
            child: Text('Delete', style: TextStyle(color: AppTheme.sellRed)),
          ),
        ],
      ),
    );
  }
}
