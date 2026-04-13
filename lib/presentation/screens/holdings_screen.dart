import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:equity_echo/core/theme/app_theme.dart';
import 'package:equity_echo/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:equity_echo/presentation/blocs/dashboard/dashboard_event.dart';
import 'package:equity_echo/presentation/blocs/dashboard/dashboard_state.dart';
import 'package:equity_echo/presentation/widgets/holding_card.dart';
import 'package:equity_echo/presentation/widgets/portfolio_allocation_chart.dart';

class HoldingsScreen extends StatefulWidget {
  const HoldingsScreen({super.key});

  @override
  State<HoldingsScreen> createState() => _HoldingsScreenState();
}

class _HoldingsScreenState extends State<HoldingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Holdings')),
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
                    Icon(
                      Icons.pie_chart_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No holdings yet',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your stock holdings will appear here',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }

            final filteredHoldings = state.holdings.where((h) {
              return h.symbol.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              );
            }).toList();

            final activeHoldings = filteredHoldings
                .where((h) => h.netQuantity > 0)
                .toList();
            final pastHoldings = filteredHoldings
                .where((h) => h.netQuantity <= 0)
                .toList();

            return RefreshIndicator(
              onRefresh: () async {
                context.read<DashboardBloc>().add(RefreshDashboard());
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Summary header
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.accent.withValues(alpha: 0.1),
                          Theme.of(context).colorScheme.surface,
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
                          color: Theme.of(context).dividerColor,
                        ),
                        _SummaryItem(
                          label: 'Total Invested',
                          value:
                              '${state.currency} ${state.totalInvested.toStringAsFixed(0)}',
                          color: AppTheme.buyGreen,
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: Theme.of(context).dividerColor,
                        ),
                        _SummaryItem(
                          label: 'Book Value',
                          value:
                              '${state.currency} ${state.totalBookValue.toStringAsFixed(0)}',
                          color: AppTheme.fundBlue,
                        ),
                      ],
                    ),
                  ),

                  // Search bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search symbol...',
                      prefixIcon: Icon(
                        Icons.search,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(fontSize: 14),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  if (activeHoldings.isNotEmpty && _searchQuery.isEmpty)
                    PortfolioAllocationChart(
                      holdings: activeHoldings,
                      onHoldingTap: (symbol) => context.push('/holding/$symbol'),
                    ),

                  if (activeHoldings.isNotEmpty) ...[
                    const Text(
                      'Active Holdings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...activeHoldings.map(
                      (holding) => HoldingCard(
                        holding: holding,
                        currency: state.currency,
                        onTap: () => context.push('/holding/${holding.symbol}'),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (pastHoldings.isNotEmpty) ...[
                    Text(
                      'Past Holdings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...pastHoldings.map(
                      (holding) => Opacity(
                        opacity: 0.6,
                        child: HoldingCard(
                          holding: holding,
                          currency: state.currency,
                          onTap: () =>
                              context.push('/holding/${holding.symbol}'),
                        ),
                      ),
                    ),
                  ],

                  if (activeHoldings.isEmpty && pastHoldings.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Text(
                          'No matching holdings found',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                ],
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
            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
