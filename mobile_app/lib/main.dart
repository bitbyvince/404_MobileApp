// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/env.dart';
import 'config/firebase_config.dart';
import 'app.dart';

Future<void> main() async {
  // Required before any async work in main()
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Validate environment config — crashes early with a
  //    clear message if a required value is missing
  Env.validate();

  // 2. Initialize Firebase — must happen before runApp()
  await FirebaseConfig.initialize();

  // 3. Run the app wrapped in ProviderScope for Riverpod
  runApp(const ProviderScope(child: RespiraTrackApp()));
}
