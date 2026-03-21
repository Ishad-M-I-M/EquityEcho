import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equity_echo/core/theme/app_theme.dart';
import 'package:equity_echo/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:equity_echo/presentation/blocs/dashboard/dashboard_event.dart';
import 'package:equity_echo/presentation/blocs/dashboard/dashboard_state.dart';
import 'package:equity_echo/presentation/widgets/holding_card.dart';

class HoldingsScreen extends StatelessWidget {
  const HoldingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Holdings'),
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is DashboardLoaded) {
            if (state.holdings.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pie_chart_outline,
                        size: 64, color: AppTheme.textSecondary),
                    const SizedBox(height: 16),
                    Text(
                      'No holdings yet',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your stock holdings will appear here',
                      style: TextStyle(
                        color: AppTheme.textSecondary.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<DashboardBloc>().add(RefreshDashboard());
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.holdings.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // Summary header
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.accent.withValues(alpha: 0.1),
                            AppTheme.surfaceDark,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _SummaryItem(
                            label: 'Stocks',
                            value: '${state.holdings.length}',
                            color: AppTheme.accent,
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: AppTheme.divider,
                          ),
                          _SummaryItem(
                            label: 'Total Invested',
                            value: '${state.currency} ${state.totalInvested.toStringAsFixed(0)}',
                            color: AppTheme.buyGreen,
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: AppTheme.divider,
                          ),
                          _SummaryItem(
                            label: 'Book Value',
                            value: '${state.currency} ${state.totalBookValue.toStringAsFixed(0)}',
                            color: AppTheme.fundBlue,
                          ),
                        ],
                      ),
                    );
                  }

                  final holding = state.holdings[index - 1];
                  return HoldingCard(
                    holding: holding,
                    currency: state.currency,
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
