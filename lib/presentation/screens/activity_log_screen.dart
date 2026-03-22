import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equity_echo/core/theme/app_theme.dart';
import 'package:equity_echo/presentation/blocs/activity_log/activity_log_bloc.dart';
import 'package:equity_echo/presentation/blocs/activity_log/activity_log_event.dart';
import 'package:equity_echo/presentation/blocs/activity_log/activity_log_state.dart';
import 'package:equity_echo/presentation/widgets/activity_tile.dart';
import 'package:equity_echo/data/models/activity_item.dart';

class ActivityLogScreen extends StatelessWidget {
  const ActivityLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Log'),
        actions: [
          BlocBuilder<ActivityLogBloc, ActivityLogState>(
            builder: (context, state) {
              if (state is ActivityLogLoaded) {
                final hasFilters = state.monthFilter != null ||
                    state.yearFilter != null ||
                    state.symbolFilter != null ||
                    state.typeFilter != null;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: () => _showFilterDialog(context, state),
                    ),
                    if (hasFilters)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppTheme.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<ActivityLogBloc>().add(RefreshActivityLog()),
          ),
        ],
      ),
      body: BlocBuilder<ActivityLogBloc, ActivityLogState>(
        builder: (context, state) {
          if (state is ActivityLogLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ActivityLogError) {
            return Center(
              child: Text(
                state.message,
                style: TextStyle(color: AppTheme.sellRed),
              ),
            );
          }

          if (state is ActivityLogLoaded) {
            if (state.groupedItems.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history,
                        size: 64, color: AppTheme.textSecondary),
                    const SizedBox(height: 16),
                    Text(
                      'No activity found',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<ActivityLogBloc>().add(RefreshActivityLog());
              },
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: state.groupedItems.length,
                itemBuilder: (context, index) {
                  final key = state.groupedItems.keys.elementAt(index);
                  final items = state.groupedItems[key]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Text(
                          key,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                      ...items.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: ActivityTile(
                              item: item,
                              onTap: item.type == ActivityType.trade
                                  ? () => _showTradeDetails(context, item)
                                  : () => _showFundDetails(context, item),
                            ),
                          )),
                      const SizedBox(height: 8),
                    ],
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

  void _showTradeDetails(BuildContext context, ActivityItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${item.tradeAction?.label ?? ''} — ${item.symbol}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _DetailRow('Quantity', '${item.quantity}'),
            _DetailRow('Price', '${item.price}'),
            _DetailRow('Total Value', '${item.totalValue?.toStringAsFixed(2)}'),
            _DetailRow('Date', '${item.date}'),
            _DetailRow('Channel', item.channelName),
            _DetailRow('Source', item.isManual ? 'Manual Entry' : 'SMS'),
            if (item.rawSmsBody.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Original SMS',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.rawSmsBody,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showFundDetails(BuildContext context, ActivityItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${item.fundAction?.label ?? ''} — ${item.amount?.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _DetailRow('Date', '${item.date}'),
            _DetailRow('Channel', item.channelName),
            _DetailRow('Source', item.isManual ? 'Manual Entry' : 'SMS'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context, ActivityLogLoaded state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        int? selectedMonth = state.monthFilter;
        int? selectedYear = state.yearFilter;
        String? selectedSymbol = state.symbolFilter;
        ActivityType? selectedType = state.typeFilter;

        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.textSecondary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filters',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              selectedMonth = null;
                              selectedYear = null;
                              selectedSymbol = null;
                              selectedType = null;
                            });
                          },
                          child: Text(
                            'Reset',
                            style: TextStyle(color: AppTheme.accent),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    const Text('Type',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: selectedType == null,
                          onSelected: (val) {
                            if (val) setState(() => selectedType = null);
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Trades'),
                          selected: selectedType == ActivityType.trade,
                          onSelected: (val) {
                            if (val) setState(() => selectedType = ActivityType.trade);
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Funds'),
                          selected: selectedType == ActivityType.fundTransfer,
                          onSelected: (val) {
                            if (val) setState(() => selectedType = ActivityType.fundTransfer);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (state.availableYears.isNotEmpty) ...[
                      const Text('Year',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('All'),
                            selected: selectedYear == null,
                            onSelected: (val) {
                              if (val) setState(() => selectedYear = null);
                            },
                          ),
                          ...state.availableYears.map((year) => ChoiceChip(
                                label: Text(year.toString()),
                                selected: selectedYear == year,
                                onSelected: (val) {
                                  if (val) setState(() => selectedYear = year);
                                },
                              )),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    const Text('Month',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: selectedMonth == null,
                          onSelected: (val) {
                            if (val) setState(() => selectedMonth = null);
                          },
                        ),
                        ...List.generate(12, (index) {
                          final month = index + 1;
                          final monthName = _getMonthName(month);
                          return ChoiceChip(
                            label: Text(monthName),
                            selected: selectedMonth == month,
                            onSelected: (val) {
                              if (val) setState(() => selectedMonth = month);
                            },
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (state.availableSymbols.isNotEmpty) ...[
                      const Text('Symbol',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('All'),
                            selected: selectedSymbol == null,
                            onSelected: (val) {
                              if (val) setState(() => selectedSymbol = null);
                            },
                          ),
                          ...state.availableSymbols.map((symbol) => ChoiceChip(
                                label: Text(symbol),
                                selected: selectedSymbol == symbol,
                                onSelected: (val) {
                                  if (val) setState(() => selectedSymbol = symbol);
                                },
                              )),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          context.read<ActivityLogBloc>().add(
                                FilterActivityLog(
                                  month: selectedMonth,
                                  year: selectedYear,
                                  symbol: selectedSymbol,
                                  type: selectedType,
                                ),
                              );
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Apply Filters',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
