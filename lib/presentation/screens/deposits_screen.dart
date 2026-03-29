import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:equity_echo/core/theme/app_theme.dart';
import 'package:equity_echo/core/di/injection.dart';
import 'package:equity_echo/data/database/database.dart';
import 'package:equity_echo/data/database/daos/fund_transfer_dao.dart';
import 'package:equity_echo/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:equity_echo/presentation/blocs/dashboard/dashboard_event.dart';

class DepositsScreen extends StatefulWidget {
  const DepositsScreen({super.key});

  @override
  State<DepositsScreen> createState() => _DepositsScreenState();
}

class _DepositsScreenState extends State<DepositsScreen> {
  late Future<List<FundTransfer>> _depositsFuture;

  @override
  void initState() {
    super.initState();
    _loadDeposits();
  }

  void _loadDeposits() {
    _depositsFuture = getIt<FundTransferDao>().getAllFundTransfers().then(
          (transfers) => transfers.where((t) {
            final a = t.action.toLowerCase();
            return a == 'deposit' || a == 'ipo_deposit';
          }).toList(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deposits Log'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/fund/new', extra: 'deposit').then((_) {
            if (!context.mounted) return;
            setState(() {
              _loadDeposits();
            });
            context.read<DashboardBloc>().add(RefreshDashboard());
          });
        },
        backgroundColor: AppTheme.fundBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: FutureBuilder<List<FundTransfer>>(
        future: _depositsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final deposits = snapshot.data ?? [];

          if (deposits.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_balance_wallet_outlined, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('No deposits found', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16)),
                ],
              ),
            );
          }

          final currencyFormatter = NumberFormat.currency(symbol: '');
          final dateFormatter = DateFormat('MMM dd, yyyy • HH:mm');

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: deposits.length,
            itemBuilder: (context, index) {
              final deposit = deposits[index];
              final isIpo = deposit.action.toLowerCase() == 'ipo_deposit';
              final dColor = isIpo ? AppTheme.accent : AppTheme.fundBlue;
              final dIcon = isIpo ? Icons.new_releases : Icons.arrow_downward;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: dColor.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: dColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(dIcon, color: dColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '+ ${currencyFormatter.format(deposit.amount)}',
                                style: TextStyle(
                                  color: dColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            if (isIpo) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accent.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    deposit.rawSmsBody.isNotEmpty ? 'IPO: ${deposit.rawSmsBody}' : 'IPO', 
                                    style: TextStyle(color: AppTheme.accent, fontSize: 10, fontWeight: FontWeight.bold)
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateFormatter.format(deposit.smsDate),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
