import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:equity_echo/core/di/injection.dart';
import 'package:equity_echo/app.dart';
import 'package:equity_echo/core/services/realtime_sync_manager.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await setupDependencies();
  
  // Initialize realtime sync manager so it starts background listeners if enabled
  getIt<RealtimeSyncManager>();
  
  runApp(const EquityEchoApp());
}
