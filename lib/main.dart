import 'package:flutter/material.dart';
import 'package:equity_echo/core/di/injection.dart';
import 'package:equity_echo/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDependencies();
  runApp(const EquityEchoApp());
}
