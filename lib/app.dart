import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:equity_echo/core/theme/app_theme.dart';
import 'package:equity_echo/core/di/injection.dart';
import 'package:equity_echo/data/database/daos/channel_dao.dart';
import 'package:equity_echo/data/database/daos/trade_dao.dart';
import 'package:equity_echo/data/database/daos/fund_transfer_dao.dart';
import 'package:equity_echo/core/services/sms_service.dart';
import 'package:equity_echo/presentation/blocs/channel/channel_bloc.dart';
import 'package:equity_echo/presentation/blocs/channel/channel_event.dart';
import 'package:equity_echo/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:equity_echo/presentation/blocs/dashboard/dashboard_event.dart';
import 'package:equity_echo/presentation/blocs/trade/trade_bloc.dart';
import 'package:equity_echo/presentation/blocs/trade/trade_event.dart';
import 'package:equity_echo/presentation/blocs/fund_transfer/fund_transfer_bloc.dart';
import 'package:equity_echo/presentation/blocs/fund_transfer/fund_transfer_event.dart';
import 'package:equity_echo/presentation/blocs/activity_log/activity_log_bloc.dart';
import 'package:equity_echo/presentation/blocs/activity_log/activity_log_event.dart';
import 'package:equity_echo/presentation/blocs/sms_sync/sms_sync_bloc.dart';
import 'package:equity_echo/presentation/screens/dashboard_screen.dart';
import 'package:equity_echo/presentation/screens/holdings_screen.dart';
import 'package:equity_echo/presentation/screens/activity_log_screen.dart';
import 'package:equity_echo/presentation/screens/settings_screen.dart';
import 'package:equity_echo/presentation/screens/channels_screen.dart';
import 'package:equity_echo/presentation/screens/channel_config_screen.dart';
import 'package:equity_echo/presentation/screens/trade_form_screen.dart';
import 'package:equity_echo/presentation/screens/fund_form_screen.dart';
import 'package:equity_echo/presentation/screens/holding_detail_screen.dart';

class EquityEchoApp extends StatelessWidget {
  const EquityEchoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ChannelBloc(channelDao: getIt<ChannelDao>())
            ..add(LoadChannels()),
        ),
        BlocProvider(
          create: (_) => DashboardBloc(
            tradeDao: getIt<TradeDao>(),
            fundTransferDao: getIt<FundTransferDao>(),
            channelDao: getIt<ChannelDao>(),
          )..add(LoadDashboard()),
        ),
        BlocProvider(
          create: (_) =>
              TradeBloc(tradeDao: getIt<TradeDao>())..add(LoadTrades()),
        ),
        BlocProvider(
          create: (_) => FundTransferBloc(
              fundTransferDao: getIt<FundTransferDao>())
            ..add(LoadFundTransfers()),
        ),
        BlocProvider(
          create: (_) => ActivityLogBloc(
            tradeDao: getIt<TradeDao>(),
            fundTransferDao: getIt<FundTransferDao>(),
            channelDao: getIt<ChannelDao>(),
          )..add(LoadActivityLog()),
        ),
        BlocProvider(
          create: (_) => SmsSyncBloc(
            smsService: getIt<SmsService>(),
            channelDao: getIt<ChannelDao>(),
            tradeDao: getIt<TradeDao>(),
            fundTransferDao: getIt<FundTransferDao>(),
          ),
        ),
      ],
      child: MaterialApp.router(
        title: 'EquityEcho',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: _router,
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Router
// ────────────────────────────────────────────────────────────────────────────

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/dashboard',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => _AppShell(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/holdings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HoldingsScreen(),
          ),
        ),
        GoRoute(
          path: '/activity',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ActivityLogScreen(),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsScreen(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/channels',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ChannelsScreen(),
    ),
    GoRoute(
      path: '/channel/new',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ChannelConfigScreen(),
    ),
    GoRoute(
      path: '/channel/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => ChannelConfigScreen(
        channelId: state.pathParameters['id'],
      ),
    ),
    GoRoute(
      path: '/holding/:symbol',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => HoldingDetailScreen(
        symbol: state.pathParameters['symbol']!,
      ),
    ),
    GoRoute(
      path: '/trade/new',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => TradeFormScreen(
        initialSymbol: state.extra as String?,
      ),
    ),
    GoRoute(
      path: '/trade/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => TradeFormScreen(
        tradeId: state.pathParameters['id'],
      ),
    ),
    GoRoute(
      path: '/fund/new',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const FundFormScreen(),
    ),
  ],
);

// ────────────────────────────────────────────────────────────────────────────
// App Shell with Bottom Navigation
// ────────────────────────────────────────────────────────────────────────────

class _AppShell extends StatelessWidget {
  final Widget child;
  const _AppShell({required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/holdings')) return 1;
    if (location.startsWith('/activity')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex(context),
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/dashboard');
            case 1:
              context.go('/holdings');
            case 2:
              context.go('/activity');
            case 3:
              context.go('/settings');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'Holdings',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
