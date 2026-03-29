import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:equity_echo/core/theme/app_theme.dart';
import 'package:equity_echo/core/di/injection.dart';
import 'package:equity_echo/data/database/database.dart';
import 'package:equity_echo/data/database/daos/stock_split_dao.dart';
import 'package:equity_echo/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:equity_echo/presentation/blocs/dashboard/dashboard_event.dart';

void showAddSplitDialog(BuildContext context, String symbol, VoidCallback onAdded) {
  DateTime selectedDate = DateTime.now();
  final oldSharesController = TextEditingController();
  final newSharesController = TextEditingController();

  showDialog(
    context: context,
    builder: (dialogCtx) {
      return StatefulBuilder(
        builder: (context, setStateLocal) {
          return AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            title: Text('Sub-division for $symbol'),
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
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
                    symbol: symbol,
                    splitDate: selectedDate,
                    oldShares: oldS,
                    newShares: newS,
                  );
                  await getIt<StockSplitDao>().insertSplit(companion);

                  if (!context.mounted) return;
                  onAdded();
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
