import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/env.dart';
import 'config/firebase_config.dart';
import 'app.dart';
import 'core/observers/provider_observer.dart';

Future<void> main() async {
  runZonedGuarded(
    () async {
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

      Env.validate();

      runApp(
        const ProviderScope(
          observers: [AppProviderObserver()],
          child: RespiraTrackApp(),
        ),
      );

      await FirebaseConfig.initialize();
    },
    (error, stack) {
      debugPrint('ZONE ERROR: $error');
      debugPrint(stack.toString());
    },
  );
}
