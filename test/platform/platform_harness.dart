import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elderly_mobile/core/theme/app_theme.dart';
import 'package:elderly_mobile/core/theme/app_scroll_behavior.dart';

/// Test harness helper for platform-aware tests on iOS and Android
Widget createPlatformTestWidget({
  required Widget child,
  TargetPlatform platform = TargetPlatform.iOS,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: AppTheme.lightTheme.copyWith(
        platform: platform,
      ),
      scrollBehavior: const AppScrollBehavior(),
      home: Scaffold(body: child),
    ),
  );
}
