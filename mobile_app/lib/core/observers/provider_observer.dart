// lib/core/observers/provider_observer.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppProviderObserver extends ProviderObserver {
  const AppProviderObserver();

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    debugPrint('══════════════════════════════════════');
    debugPrint('RIVERPOD PROVIDER ERROR:');
    debugPrint('Provider : ${provider.name ?? provider.runtimeType}');
    debugPrint('Error    : $error');
    debugPrint(stackTrace.toString());
    debugPrint('══════════════════════════════════════');
  }

  @override
  void didAddProvider(
    ProviderBase<Object?> provider,
    Object? value,
    ProviderContainer container,
  ) {
    if (kDebugMode) {
      debugPrint(
        '[Riverpod] Provider added: ${provider.name ?? provider.runtimeType}',
      );
    }
  }

  @override
  void didDisposeProvider(
    ProviderBase<Object?> provider,
    ProviderContainer container,
  ) {
    if (kDebugMode) {
      debugPrint(
        '[Riverpod] Provider disposed: ${provider.name ?? provider.runtimeType}',
      );
    }
  }

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    // Only log in debug mode and only for named providers
    // to avoid flooding the console with anonymous provider updates
    if (kDebugMode && provider.name != null) {
      debugPrint(
        '[Riverpod] ${provider.name} updated: '
        '${previousValue.runtimeType} → ${newValue.runtimeType}',
      );
    }
  }
}
