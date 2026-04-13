import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:equity_echo/core/theme/app_theme.dart';
import 'package:equity_echo/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:equity_echo/presentation/blocs/dashboard/dashboard_event.dart';
import 'package:equity_echo/presentation/blocs/dashboard/dashboard_state.dart';
import 'package:equity_echo/presentation/blocs/sms_sync/sms_sync_bloc.dart';
import 'package:equity_echo/presentation/widgets/stat_card.dart';
import 'package:equity_echo/presentation/widgets/holding_card.dart';
import 'package:equity_echo/presentation/widgets/sync_progress_dialog.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EquityEcho'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync SMS',
            onPressed: () {
              context.read<SmsSyncBloc>().add(StartInitialSync());
              showSyncProgressDialog(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Channels',
            onPressed: () => context.push('/channels'),
          ),
        ],
      ),
      body: BlocListener<SmsSyncBloc, SmsSyncState>(
        listener: (context, state) {
          if (state is SmsSyncComplete && !state.isCancelled) {
            context.read<DashboardBloc>().add(RefreshDashboard());
          }
        },
        child: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is DashboardError) {
              return _EmptyState(
                icon: Icons.error_outline,
                title: 'Error',
                subtitle: state.message,
                onAction: () =>
                    context.read<DashboardBloc>().add(LoadDashboard()),
                actionLabel: 'Retry',
              );
            }

            if (state is DashboardLoaded) {
              if (state.holdings.isEmpty && state.totalTrades == 0) {
                return _EmptyState(
                  icon: Icons.trending_up,
                  title: 'Welcome to EquityEcho',
                  subtitle:
                      'Configure a broker channel and sync your SMS to get started',
                  onAction: () => context.push('/channels'),
                  actionLabel: 'Setup Channel',
                );
              }

              final currencyFormatter = NumberFormat.currency(
                symbol: '${state.currency} ',
                decimalDigits: 2,
              );

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<DashboardBloc>().add(RefreshDashboard());
                },
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Stats Grid — using Rows for flexible height
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: StatCard(
                              label: 'Total Invested',
                              value: currencyFormatter.format(
                                state.totalInvested,
                              ),
                              icon: Icons.account_balance,
                              color: AppTheme.buyGreen,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatCard(
                              label: 'Realized Gain',
                              value: currencyFormatter.format(
                                state.totalRealizedGain,
                              ),
                              icon: Icons.monetization_on,
                              color: state.totalRealizedGain >= 0
                                  ? AppTheme.accent
                                  : AppTheme.sellRed,
                              onTap: () => context.push('/realized-gains'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: StatCard(
                              label: 'Deposits',
                              value: currencyFormatter.format(
                                state.totalDeposits,
                              ),
                              icon: Icons.account_balance_wallet,
                              color: AppTheme.fundBlue,
                              onTap: () => context.push('/deposits'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatCard(
                              label: 'Dividends',
                              value: currencyFormatter.format(
                                state.totalDividends,
                              ),
                              icon: Icons.card_giftcard,
                              color: AppTheme.buyGreen,
                              subtitle: 'Received',
                              onTap: () => context.push('/dividends'),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Holdings Section
                    Row(
                      children: [
                        const Text(
                          'Holdings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${state.holdings.length} stocks',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Book Value summary
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.accent.withValues(alpha: 0.08),
                            AppTheme.accent.withValues(alpha: 0.02),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.accent.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.assessment,
                            color: AppTheme.accent,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Portfolio Book Value',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                currencyFormatter.format(state.totalBookValue),
                                style: TextStyle(
                                  color: AppTheme.accent,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Holdings list
                    ...state.holdings
                        .where((h) => h.netQuantity > 0)
                        .map(
                          (h) => HoldingCard(
                            holding: h,
                            currency: state.currency,
                            onTap: () => context.push('/holding/${h.symbol}'),
                          ),
                        ),

                    if (state.holdings.any((h) => h.netQuantity <= 0)) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Past Holdings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...state.holdings
                          .where((h) => h.netQuantity <= 0)
                          .map(
                            (h) => Opacity(
                              opacity: 0.6,
                              child: HoldingCard(
                                holding: h,
                                currency: state.currency,
                                onTap: () =>
                                    context.push('/holding/${h.symbol}'),
                              ),
                            ),
                          ),
                    ],
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMenu(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.buyGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.trending_up, color: AppTheme.buyGreen),
              ),
              title: const Text('Add Trade'),
              subtitle: Text(
                'Manually add a buy or sell trade',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/trade/new');
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.new_releases, color: AppTheme.accent),
              ),
              title: const Text('Add IPO Purchase'),
              subtitle: Text(
                'Record an IPO allotment and deposit',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/ipo/new');
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.fundBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: AppTheme.fundBlue,
                ),
              ),
              title: const Text('Add Fund Transfer'),
              subtitle: Text(
                'Record a deposit or withdrawal',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/fund/new');
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onAction;
  final String? actionLabel;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.accent, size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
