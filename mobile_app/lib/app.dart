// lib/app.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class RespiraTrackApp extends ConsumerWidget {
  const RespiraTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    // ── ScreenUtilInit must wrap MaterialApp ──────────────
    // designSize matches the screen size you designed for.
    // Standard is 375x812 (iPhone X) or 360x800 (Android).
    // Use whichever your UI was designed around.
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true, // ← this is the field that was uninitialized
      splitScreenMode: true,
      useInheritedMediaQuery: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'RespiraTrack',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          routerConfig: router,
          builder: (context, widget) {
            // Ensures ScreenUtil text scaling applies everywhere
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.noScaling),
              child: widget!,
            );
          },
        );
      },
    );
  }
}
