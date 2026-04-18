import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equity_echo/core/theme/app_theme.dart';
import 'package:equity_echo/core/services/sms_service.dart';
import 'package:equity_echo/core/di/injection.dart';
import 'package:equity_echo/presentation/blocs/sms_sync/sms_sync_bloc.dart';
import 'package:equity_echo/presentation/widgets/sync_progress_dialog.dart';
import 'package:equity_echo/core/theme/theme_cubit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
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
                  Theme.of(context).colorScheme.surface,
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
                  child: Icon(
                    Icons.trending_up,
                    color: AppTheme.accent,
                    size: 28,
                  ),
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
                      'Version ${String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0')}',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const SizedBox(height: 24),

          // Appearance section
          _SectionTitle('Appearance'),
          const SizedBox(height: 8),
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, themeMode) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.palette,
                        color: AppTheme.accent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Theme',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<ThemeMode>(
                        value: themeMode,
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        dropdownColor: Theme.of(context).cardColor,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: ThemeMode.system,
                            child: Text('System'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.light,
                            child: Text('Light'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.dark,
                            child: Text('Dark'),
                          ),
                        ],
                        onChanged: (mode) {
                          if (mode != null) {
                            context.read<ThemeCubit>().setTheme(mode);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
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
            subtitle: 'Scan new SMS since last sync',
            onTap: () {
              context.read<SmsSyncBloc>().add(const StartInitialSync());
              showSyncProgressDialog(context);
            },
          ),
          const SizedBox(height: 6),
          _SettingsTile(
            icon: Icons.history,
            title: 'Sync All Messages',
            subtitle: 'Re-scan the entire SMS inbox',
            onTap: () => _confirmFullSync(context),
          ),
          const SizedBox(height: 6),
          _SettingsTile(
            icon: Icons.notifications_active,
            title: 'Real-time Listener',
            subtitle: 'Start listening for new SMS',
            onTap: () {
              context.read<SmsSyncBloc>().add(StartRealtimeListener());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Real-time SMS listener started')),
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
                    content: Text(
                      granted
                          ? 'SMS permission granted'
                          : 'SMS permission denied',
                    ),
                  ),
                );
              }
            },
          ),

          const SizedBox(height: 24),

          // Cloud Sync section
          _SectionTitle('Cloud Sync & Backup'),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.cloud_sync,
            title: 'Cloud Sync',
            subtitle: 'Backup or restore data from the cloud',
            onTap: () => context.push('/auth'),
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
            icon: Icons.auto_delete,
            title: 'Deleted Entries',
            subtitle: 'View and restore soft-deleted items',
            onTap: () => context.push('/deleted-entries'),
          ),

          const SizedBox(height: 40),

          // About
          Center(
            child: Text(
              'Built with ❤️ for equity tracking',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _confirmFullSync(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Sync All Messages?'),
        content: const Text(
          'This ignores the last sync time and re-scans every SMS from your '
          'configured broker channels. Duplicate entries are automatically '
          'skipped, so this is safe to run.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<SmsSyncBloc>().add(
                const StartInitialSync(fullSync: true),
              );
              showSyncProgressDialog(context);
            },
            child: Text(
              'Sync All',
              style: TextStyle(color: AppTheme.accent),
            ),
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
        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
          color: Theme.of(context).cardColor,
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
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
