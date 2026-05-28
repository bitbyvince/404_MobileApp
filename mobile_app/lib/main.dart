import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/env.dart';
import 'config/firebase_config.dart';
import 'app.dart';
import 'core/observers/provider_observer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FLUTTER ERROR: ${details.exceptionAsString()}');
    debugPrint(details.stack.toString());
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('PLATFORM ERROR: $error');
    debugPrint(stack.toString());
    return true;
  };

  await runZonedGuarded(
    () async {
      Env.validate();

      // ── KEY FIX ────────────────────────────────────────────
      // Run the app FIRST so Flutter renders something on screen
      // immediately. Heavy initialization (Firebase, secure storage)
      // happens inside SplashScreen using compute() or Isolate,
      // NOT here blocking main before runApp() is even called.
      runApp(
        const ProviderScope(
          observers: const [AppProviderObserver()],
          child: const RespiraTrackApp(),
        ),
      );

      // Firebase can be initialized AFTER runApp
      // It will complete while the splash screen is showing
      // instead of freezing the screen before anything renders
      await FirebaseConfig.initialize();
    },
    (error, stack) {
      debugPrint('ZONE ERROR: $error');
      debugPrint(stack.toString());
    },
  );
}
