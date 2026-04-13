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
import '../widgets/delete_confirmation_dialog.dart';

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
      _historyFuture = getIt<DividendDao>().getDividendsForSymbol(
        widget.symbol,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.symbol} Dividends')),
      body: FutureBuilder<List<Dividend>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(color: AppTheme.sellRed),
              ),
            );
          }

          final dividends = snapshot.data ?? [];
          if (dividends.isEmpty) {
            return Center(
              child: Text(
                'No dividend history found.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 16,
                ),
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
                  return _DividendCard(
                    div: div,
                    currencyFormatter: currencyFormatter,
                    onDelete: () => _confirmDeleteDividend(context, div),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteDividend(
    BuildContext context,
    Dividend div,
  ) async {
    final result = await DeleteConfirmationDialog.show(
      context,
      title: 'Delete Dividend',
      content: 'Are you sure you want to delete this dividend payout?',
    );

    if (result != null && result.confirmed) {
      if (!context.mounted) return;
      await getIt<DividendDao>().deleteDividend(
        div.id,
        reason: result.reason,
        reasonOther: result.reasonOther,
      );
      if (!context.mounted) return;
      context.read<DashboardBloc>().add(RefreshDashboard());
      _loadHistory();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Dividend deleted')));
    }
  }
}

class _DividendCard extends StatefulWidget {
  final Dividend div;
  final NumberFormat currencyFormatter;
  final VoidCallback onDelete;

  const _DividendCard({
    required this.div,
    required this.currencyFormatter,
    required this.onDelete,
  });

  @override
  State<_DividendCard> createState() => _DividendCardState();
}

class _DividendCardState extends State<_DividendCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final div = widget.div;
    final dps = div.dividendPerShare;
    final shares = div.shares;
    final tax = div.tax;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            onLongPress: widget.onDelete,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                        child: Icon(
                          Icons.arrow_downward,
                          color: AppTheme.buyGreen,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'RECEIVED',
                                style: TextStyle(
                                  color: AppTheme.buyGreen,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              if (dps > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accent.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${dps.toStringAsFixed(2)} / sh',
                                    style: TextStyle(
                                      color: AppTheme.accent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM dd, yyyy').format(div.date),
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
                  Row(
                    children: [
                      Text(
                        widget.currencyFormatter.format(div.amount),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.buyGreen,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 18,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 50, right: 16, bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  children: [
                    _DetailRow(
                      label: 'Shares Held',
                      value: shares.toStringAsFixed(0),
                      icon: Icons.pie_chart_outline,
                    ),
                    const SizedBox(height: 8),
                    _DetailRow(
                      label: 'Dividend / Share',
                      value: widget.currencyFormatter.format(dps),
                      icon: Icons.monetization_on_outlined,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1),
                    ),
                    _DetailRow(
                      label: 'Gross Amount',
                      value: widget.currencyFormatter.format(shares * dps),
                    ),
                    const SizedBox(height: 4),
                    _DetailRow(
                      label: 'Tax Deducted',
                      value: '- ${widget.currencyFormatter.format(tax)}',
                      valueColor: AppTheme.sellRed,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1),
                    ),
                    _DetailRow(
                      label: 'Net Amount',
                      value: widget.currencyFormatter.format(div.amount),
                      valueColor: AppTheme.buyGreen,
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;
  final bool isBold;

  const _DetailRow({
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: valueColor ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
