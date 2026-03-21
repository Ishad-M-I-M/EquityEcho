import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equity_echo/core/theme/app_theme.dart';
import 'package:equity_echo/presentation/blocs/sms_sync/sms_sync_bloc.dart';

void showSyncProgressDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => BlocConsumer<SmsSyncBloc, SmsSyncState>(
      listener: (ctx, state) {
        if (state is SmsSyncComplete) {
          Navigator.of(ctx).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.isCancelled
                  ? 'Sync cancelled. Processed partial messages.'
                  : 'Sync complete! Added ${state.tradesAdded} trades and ${state.fundsAdded} funds.'),
            ),
          );
        } else if (state is SmsSyncError) {
          Navigator.of(ctx).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (ctx, state) {
        int processed = 0;
        int total = 0;
        if (state is SmsSyncInProgress) {
          processed = state.processed;
          total = state.total;
        }
        final progress = total > 0 ? (processed / total) : null;

        return AlertDialog(
          backgroundColor: AppTheme.cardDark,
          title: const Text('Syncing SMS...'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(
                value: progress,
                color: AppTheme.accent,
                backgroundColor: AppTheme.surfaceDark,
              ),
              const SizedBox(height: 16),
              Text(
                total > 0
                    ? 'Processed $processed of $total messages'
                    : 'Preparing sync...',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                context.read<SmsSyncBloc>().add(CancelInitialSync());
              },
              child: Text('Cancel', style: TextStyle(color: AppTheme.sellRed)),
            ),
          ],
        );
      },
    ),
  );
}
