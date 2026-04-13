import 'package:flutter/material.dart';

import 'package:equity_echo/core/services/auth_service.dart';
import 'package:equity_echo/core/services/cloud_sync_service.dart';
import 'package:equity_echo/core/di/injection.dart';
import 'package:equity_echo/data/database/database.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equity_echo/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:equity_echo/presentation/blocs/dashboard/dashboard_event.dart';
import 'package:equity_echo/core/theme/app_theme.dart';
import 'package:equity_echo/core/services/realtime_sync_manager.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;

  final authService = getIt<AuthService>();
  final syncService = getIt<CloudSyncService>();
  final db = getIt<AppDatabase>();

  Future<void> _submitEmailPassword() async {
    final email = _emailController.text.trim();
    final pw = _passwordController.text;
    final cpw = _confirmPasswordController.text;
    if (email.isEmpty || pw.isEmpty) return;

    if (!_isLogin && pw != cpw) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await authService.signInWithEmailAndPassword(email, pw);
      } else {
        await authService.signUpWithEmailAndPassword(email, pw);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await authService.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _syncData(bool isUp) async {
    final user = authService.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      if (isUp) {
        await syncService.syncUp(user.id, db);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Sync Up Complete')));
        }
      } else {
        await syncService.syncDown(user.id, db);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Sync Down Complete')));
          context.read<DashboardBloc>().add(LoadDashboard());
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sync Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cloud Sync & Backup')),
      body: StreamBuilder(
        stream: authService.authStateChanges,
        builder: (context, snapshot) {
          final user = snapshot.data;

          if (user != null) {
            // Logged in UI
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.cloud_done, size: 64, color: Colors.green),
                  const SizedBox(height: 16),
                  Text(
                    'Signed in as',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    user.email,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('Backup Data to Cloud'),
                    onPressed: _isLoading ? null : () => _syncData(true),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.cloud_download),
                    label: const Text('Restore Data from Cloud'),
                    onPressed: _isLoading ? null : () => _syncData(false),
                  ),
                  const SizedBox(height: 16),
                  const _RealtimeSyncTile(),
                  const Spacer(),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator()),
                  const Spacer(),
                  TextButton(
                    onPressed: () => authService.signOut(),
                    child: const Text(
                      'Sign Out',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );
          }

          // Not logged in UI
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _isLogin ? 'Login to Sync' : 'Create Account to Sync',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  if (!_isLogin) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirmPasswordController,
                      decoration: const InputDecoration(
                        labelText: 'Confirm Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitEmailPassword,
                    child: Text(_isLogin ? 'Login' : 'Sign Up'),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: Text(
                      _isLogin
                          ? 'Need an account? Sign Up'
                          : 'Have an account? Login',
                    ),
                  ),
                  const Divider(height: 48),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.login), // simplified icon
                    label: const Text('Sign in with Google'),
                    onPressed: _isLoading ? null : _signInWithGoogle,
                  ),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RealtimeSyncTile extends StatefulWidget {
  const _RealtimeSyncTile();

  @override
  State<_RealtimeSyncTile> createState() => _RealtimeSyncTileState();
}

class _RealtimeSyncTileState extends State<_RealtimeSyncTile> {
  late bool _isEnabled;

  @override
  void initState() {
    super.initState();
    _isEnabled = getIt<RealtimeSyncManager>().isRealtimeSyncEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.autorenew, color: AppTheme.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Realtime Auto Sync',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  'Sync data in background instantly',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isEnabled,
            activeTrackColor: AppTheme.accent.withValues(alpha: 0.5),
            activeThumbColor: AppTheme.accent,
            onChanged: (val) {
              setState(() {
                _isEnabled = val;
              });
              getIt<RealtimeSyncManager>().setRealtimeSyncEnabled(val);
            },
          ),
        ],
      ),
    );
  }
}
