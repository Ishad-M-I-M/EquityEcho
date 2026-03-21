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
            if (state.items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history,
                        size: 64, color: AppTheme.textSecondary),
                    const SizedBox(height: 16),
                    Text(
                      'No activity yet',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Trades and fund transfers will appear here',
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
                context.read<ActivityLogBloc>().add(RefreshActivityLog());
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.items.length,
                itemBuilder: (context, index) {
                  final item = state.items[index];
                  return ActivityTile(
                    item: item,
                    onTap: item.type == ActivityType.trade
                        ? () => _showTradeDetails(context, item)
                        : () => _showFundDetails(context, item),
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
