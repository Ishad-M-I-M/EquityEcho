import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:equity_echo/core/theme/app_theme.dart';
import 'package:equity_echo/core/di/injection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equity_echo/data/database/database.dart';
import 'package:equity_echo/data/database/daos/trade_dao.dart';
import 'package:equity_echo/data/database/daos/fund_transfer_dao.dart';
import 'package:equity_echo/data/database/daos/dividend_dao.dart';
import 'package:equity_echo/data/database/daos/stock_split_dao.dart';
import 'package:equity_echo/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:equity_echo/presentation/blocs/dashboard/dashboard_event.dart';

class DeletedEntriesScreen extends StatefulWidget {
  const DeletedEntriesScreen({super.key});

  @override
  State<DeletedEntriesScreen> createState() => _DeletedEntriesScreenState();
}

class _DeletedEntriesScreenState extends State<DeletedEntriesScreen> {
  late Future<List<dynamic>> _deletedEntriesFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadDeletedEntries();
  }

  void _loadDeletedEntries() {
    setState(() {
      _deletedEntriesFuture = _fetchDeletedEntries();
    });
  }

  Future<List<dynamic>> _fetchDeletedEntries() async {
    final trades = await getIt<TradeDao>().getDeletedTrades();
    final funds = await getIt<FundTransferDao>().getDeletedFundTransfers();
    final dividends = await getIt<DividendDao>().getDeletedDividends();
    final splits = await getIt<StockSplitDao>().getDeletedSplits();

    final allEntries = [...trades, ...funds, ...dividends, ...splits];

    // Sort logic (if required, rough sort by timestamp)
    allEntries.sort((a, b) {
      DateTime dateA;
      if (a is Trade) {
        dateA = a.smsDate;
      } else if (a is FundTransfer) {
        dateA = a.smsDate;
      } else if (a is Dividend) {
        dateA = a.date;
      } else {
        dateA = (a as StockSplit).splitDate;
      }

      DateTime dateB;
      if (b is Trade) {
        dateB = b.smsDate;
      } else if (b is FundTransfer) {
        dateB = b.smsDate;
      } else if (b is Dividend) {
        dateB = b.date;
      } else {
        dateB = (b as StockSplit).splitDate;
      }

      return dateB.compareTo(dateA); // Newest first
    });

    return allEntries;
  }

  Future<void> _restoreEntry(dynamic entry) async {
    if (entry is Trade) {
      await getIt<TradeDao>().restoreTrade(entry.id);
    } else if (entry is FundTransfer) {
      await getIt<FundTransferDao>().restoreFundTransfer(entry.id);
    } else if (entry is Dividend) {
      await getIt<DividendDao>().restoreDividend(entry.id);
    } else if (entry is StockSplit) {
      await getIt<StockSplitDao>().restoreSplit(entry.id);
    }

    if (!mounted) return;
    context.read<DashboardBloc>().add(RefreshDashboard());
    _loadDeletedEntries();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Entry restored successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deleted Entries'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Filter by symbol or action...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),

      body: FutureBuilder<List<dynamic>>(
        future: _deletedEntriesFuture,
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

          final allEntries = snapshot.data ?? [];
          final filteredEntries = allEntries.where((entry) {
            if (_searchQuery.isEmpty) return true;

            String? symbol;
            String? action;

            if (entry is Trade) {
              symbol = entry.symbol.toLowerCase();
              action = entry.action.toLowerCase();
            } else if (entry is FundTransfer) {
              action = entry.action.toLowerCase();
            } else if (entry is Dividend) {
              symbol = entry.symbol.toLowerCase();
            } else if (entry is StockSplit) {
              symbol = entry.symbol.toLowerCase();
            }

            final matchesSymbol = symbol?.contains(_searchQuery) ?? false;
            final matchesAction = action?.contains(_searchQuery) ?? false;

            return matchesSymbol || matchesAction;
          }).toList();

          if (filteredEntries.isEmpty) {
            return Center(
              child: Text(
                _searchQuery.isEmpty
                    ? 'No deleted entries.'
                    : 'No matching entries found.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 16,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredEntries.length,
            itemBuilder: (context, index) {
              final entry = filteredEntries[index];

              return _DeletedEntryCard(
                entry: entry,
                onRestore: () => _restoreEntry(entry),
              );
            },
          );
        },
      ),
    );
  }
}

class _DeletedEntryCard extends StatelessWidget {
  final dynamic entry;
  final VoidCallback onRestore;

  const _DeletedEntryCard({required this.entry, required this.onRestore});

  @override
  Widget build(BuildContext context) {
    String title = 'Unknown';
    String subtitle = '';
    String reason = 'No reason provided';
    DateTime? date;

    if (entry is Trade) {
      final t = entry as Trade;
      final isBuy = t.action.toLowerCase() == 'buy';
      title = 'Trade (${isBuy ? 'Buy' : 'Sell'}) - ${t.symbol}';
      subtitle =
          'Qty: ${t.quantity.toStringAsFixed(0)} @ ${t.price.toStringAsFixed(2)}';
      reason = t.deleteReasonOther?.isNotEmpty == true
          ? '${t.deleteReason} - ${t.deleteReasonOther}'
          : '${t.deleteReason}';
      date = t.smsDate;
    } else if (entry is FundTransfer) {
      final f = entry as FundTransfer;
      title =
          'Fund ${f.action.toLowerCase() == 'deposit' ? 'Deposit' : 'Withdrawal'}';
      subtitle = 'Amount: ${f.amount.toStringAsFixed(2)}';
      reason = f.deleteReasonOther?.isNotEmpty == true
          ? '${f.deleteReason} - ${f.deleteReasonOther}'
          : '${f.deleteReason}';
      date = f.smsDate;
    } else if (entry is Dividend) {
      final d = entry as Dividend;
      title = 'Dividend - ${d.symbol}';
      subtitle = 'Amount: ${d.amount.toStringAsFixed(2)}';
      reason = d.deleteReasonOther?.isNotEmpty == true
          ? '${d.deleteReason} - ${d.deleteReasonOther}'
          : '${d.deleteReason}';
      date = d.date;
    } else if (entry is StockSplit) {
      final s = entry as StockSplit;
      title = 'Stock Split - ${s.symbol}';
      subtitle = 'Ratio: ${s.oldShares}:${s.newShares}';
      reason = s.deleteReasonOther?.isNotEmpty == true
          ? '${s.deleteReason} - ${s.deleteReasonOther}'
          : '${s.deleteReason}';
      date = s.splitDate;
    }

    if (reason == 'null') reason = 'No reason provided';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.sellRed.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.restore, color: AppTheme.buyGreen),
                tooltip: 'Restore',
                onPressed: onRestore,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          if (date != null) ...[
            Text(
              'Date: ${DateFormat('MMM dd, yyyy HH:mm').format(date)}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.errorContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Reason: $reason',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
