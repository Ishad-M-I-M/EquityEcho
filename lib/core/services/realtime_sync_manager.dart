import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:equity_echo/core/services/auth_service.dart';
import 'package:equity_echo/core/services/cloud_sync_service.dart';
import 'package:equity_echo/data/database/database.dart';

class RealtimeSyncManager {
  final SharedPreferences _prefs;
  final AppDatabase _db;
  final AuthService _authService;
  final CloudSyncService _syncService;

  StreamSubscription? _authSubscription;
  StreamSubscription? _dbSubscription;
  StreamSubscription? _firestoreSubscription;

  bool _isRealtimeSyncEnabled = false;
  bool _isSyncingUp = false;
  bool _isSyncingDown = false;
  Timer? _debounceTimer;

  static const String _prefKey = 'is_realtime_sync_enabled';

  RealtimeSyncManager({
    required SharedPreferences prefs,
    required AppDatabase db,
    required AuthService authService,
    required CloudSyncService syncService,
  })  : _prefs = prefs,
        _db = db,
        _authService = authService,
        _syncService = syncService {
    _isRealtimeSyncEnabled = _prefs.getBool(_prefKey) ?? false;
    _startAuthListener();
  }

  bool get isRealtimeSyncEnabled => _isRealtimeSyncEnabled;

  Future<void> setRealtimeSyncEnabled(bool enabled) async {
    if (_isRealtimeSyncEnabled == enabled) return;

    _isRealtimeSyncEnabled = enabled;
    await _prefs.setBool(_prefKey, enabled);

    if (enabled) {
      _startListenersForCurrentUser();
    } else {
      _stopListeners();
    }
  }

  void _startAuthListener() {
    _authSubscription?.cancel();
    _authSubscription = _authService.authStateChanges.listen((user) {
      if (user != null && _isRealtimeSyncEnabled) {
        _startListenersForCurrentUser();
      } else {
        _stopListeners();
      }
    });
  }

  void _startListenersForCurrentUser() {
    final user = _authService.currentUser;
    if (user == null) return;

    _stopListeners(); // ensure clean state

    // 1. Listen to Local Database Changes
    _dbSubscription = _db.tableUpdates().listen((updates) {
      if (_isSyncingDown) return; // Ignore updates caused by our own syncDown

      // Debounce the call to avoid spamming Firestore
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(seconds: 2), () {
        _performSyncUp(user.id);
      });
    });

    // 2. Listen to Firestore Remote Changes
    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.id);
    _firestoreSubscription = userDoc.snapshots().listen((snapshot) {
      if (_isSyncingUp) return; // Ignore updates caused by our own syncUp

      if (snapshot.exists) {
        // Checking if we should sync down based on the lastUpdatedAt field.
        // We sync down whenever it changes remotely.
        _performSyncDown(user.id);
      }
    });
  }

  void _stopListeners() {
    _debounceTimer?.cancel();
    _dbSubscription?.cancel();
    _firestoreSubscription?.cancel();
    _dbSubscription = null;
    _firestoreSubscription = null;
  }

  Future<void> _performSyncUp(String userId) async {
    if (_isSyncingUp || _isSyncingDown) return;

    try {
      _isSyncingUp = true;
      await _syncService.syncUp(userId, _db);
    } catch (e) {
      debugPrint('RealtimeSyncManager Error Syncing Up: $e');
    } finally {
      // Small delay to prevent echo from remote listener
      Future.delayed(const Duration(seconds: 1), () {
        _isSyncingUp = false;
      });
    }
  }

  Future<void> _performSyncDown(String userId) async {
    if (_isSyncingDown || _isSyncingUp) return;

    try {
      _isSyncingDown = true;
      await _syncService.syncDown(userId, _db);
    } catch (e) {
      debugPrint('RealtimeSyncManager Error Syncing Down: $e');
    } finally {
      // Small delay to prevent echo from local tableUpdates
      Future.delayed(const Duration(seconds: 1), () {
        _isSyncingDown = false;
      });
    }
  }

  void dispose() {
    _authSubscription?.cancel();
    _stopListeners();
  }
}
