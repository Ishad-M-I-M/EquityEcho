import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
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
  DateTime? _lastSyncTime;
  Timestamp? _lastSeenRemoteUpdate;

  static const String _prefKey = 'is_realtime_sync_enabled';
  static const String _lastSyncKey = 'realtime_last_sync_time';

  RealtimeSyncManager({
    required SharedPreferences prefs,
    required AppDatabase db,
    required AuthService authService,
    required CloudSyncService syncService,
  }) : _prefs = prefs,
       _db = db,
       _authService = authService,
       _syncService = syncService {
    _isRealtimeSyncEnabled = _prefs.getBool(_prefKey) ?? false;
    final lastSyncMs = _prefs.getInt(_lastSyncKey);
    if (lastSyncMs != null) {
      _lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSyncMs);
    }
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
      if (snapshot.metadata.hasPendingWrites) {
        return; // ignore local writes mirroring
      }

      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null && data.containsKey('lastUpdatedAt')) {
          final lastUpdatedAt = data['lastUpdatedAt'] as Timestamp?;
          if (lastUpdatedAt != null) {
            if (_lastSeenRemoteUpdate != null &&
                lastUpdatedAt.compareTo(_lastSeenRemoteUpdate!) <= 0) {
              return; // Already processed this or newer update
            }
            _lastSeenRemoteUpdate = lastUpdatedAt;
          }
        }

        if (_isSyncingUp) return; // Secondary safeguard
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
      final syncStart = DateTime.now().toUtc();

      await _syncService.syncUp(userId, _db, since: _lastSyncTime);

      _lastSyncTime = syncStart;
      await _prefs.setInt(_lastSyncKey, syncStart.millisecondsSinceEpoch);

      // Record the timestamp created by our own transaction to ignore the incoming snapshot
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (doc.exists && doc.data()?.containsKey('lastUpdatedAt') == true) {
        _lastSeenRemoteUpdate = doc.data()?['lastUpdatedAt'] as Timestamp?;
      }
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
