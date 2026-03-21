import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equity_echo/core/theme/app_theme.dart';
import 'package:equity_echo/core/services/sms_service.dart';
import 'package:equity_echo/core/di/injection.dart';
import 'package:equity_echo/data/database/daos/trade_dao.dart';
import 'package:equity_echo/data/database/daos/fund_transfer_dao.dart';
import 'package:equity_echo/presentation/blocs/sms_sync/sms_sync_bloc.dart';


class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // App header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.accent.withValues(alpha: 0.12),
                  AppTheme.surfaceDark,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.trending_up,
                      color: AppTheme.accent, size: 28),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EquityEcho',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Version 1.0.0',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Channels section
          _SectionTitle('Configuration'),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.sms,
            title: 'Broker Channels',
            subtitle: 'Manage SMS channels and templates',
            onTap: () => context.push('/channels'),
          ),
          const SizedBox(height: 24),

          // SMS section
          _SectionTitle('SMS'),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.sync,
            title: 'Sync SMS Inbox',
            subtitle: 'Scan existing SMS messages',
            onTap: () {
              context.read<SmsSyncBloc>().add(StartInitialSync());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('SMS sync started...')),
              );
            },
          ),
          const SizedBox(height: 6),
          _SettingsTile(
            icon: Icons.notifications_active,
            title: 'Real-time Listener',
            subtitle: 'Start listening for new SMS',
            onTap: () {
              context.read<SmsSyncBloc>().add(StartRealtimeListener());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Real-time SMS listener started')),
              );
            },
          ),
          const SizedBox(height: 6),
          _SettingsTile(
            icon: Icons.security,
            title: 'SMS Permissions',
            subtitle: 'Grant SMS reading permission',
            onTap: () async {
              final smsService = getIt<SmsService>();
              final granted = await smsService.requestPermission();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(granted
                        ? 'SMS permission granted'
                        : 'SMS permission denied'),
                  ),
                );
              }
            },
          ),

          const SizedBox(height: 24),

          // Data section
          _SectionTitle('Data'),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.add_chart,
            title: 'Add Trade',
            subtitle: 'Manually add a trade entry',
            onTap: () => context.push('/trade/new'),
          ),
          const SizedBox(height: 6),
          _SettingsTile(
            icon: Icons.account_balance_wallet,
            title: 'Add Fund Transfer',
            subtitle: 'Record a deposit or withdrawal',
            onTap: () => context.push('/fund/new'),
          ),

          const SizedBox(height: 24),

          // Danger zone
          _SectionTitle('Data Management'),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.refresh,
            title: 'Clear & Re-sync',
            subtitle: 'Delete all trades/funds and resync from SMS',
            color: AppTheme.warning,
            onTap: () => _confirmClearAndResync(context),
          ),
          const SizedBox(height: 6),
          _SettingsTile(
            icon: Icons.delete_forever,
            title: 'Clear All Data',
            subtitle: 'Delete all trades and fund transfers',
            color: AppTheme.sellRed,
            onTap: () => _confirmClearData(context),
          ),

          const SizedBox(height: 40),

          // About
          Center(
            child: Text(
              'Built with ❤️ for equity tracking',
              style: TextStyle(
                color: AppTheme.textSecondary.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _confirmClearData(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Clear All Data?'),
        content: const Text(
            'This will permanently delete all trades and fund transfers. Channel configurations will be kept.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final tradeDao = getIt<TradeDao>();
              final fundDao = getIt<FundTransferDao>();
              await tradeDao.deleteAllTrades();
              await fundDao.deleteAllFundTransfers();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data cleared')),
                );
              }
            },
            child: Text('Clear', style: TextStyle(color: AppTheme.sellRed)),
          ),
        ],
      ),
    );
  }

  void _confirmClearAndResync(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Clear & Re-sync?'),
        content: const Text(
            'This will delete all existing trades and fund transfers, then re-sync from your SMS inbox.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final tradeDao = getIt<TradeDao>();
              final fundDao = getIt<FundTransferDao>();
              await tradeDao.deleteAllTrades();
              await fundDao.deleteAllFundTransfers();
              if (context.mounted) {
                context.read<SmsSyncBloc>().add(StartInitialSync());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Data cleared. Re-syncing SMS...')),
                );
              }
            },
            child: Text('Clear & Sync', style: TextStyle(color: AppTheme.warning)),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? color;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tileColor = color ?? AppTheme.accent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: tileColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: tileColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: AppTheme.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
