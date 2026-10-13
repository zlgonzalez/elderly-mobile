import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_scroll_behavior.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PlatformDispatcher.instance.onError = (error, stack) {
    final msg = error.toString();
    if (msg.contains('google_fonts') || msg.contains('fonts.gstatic.com')) {
      return true;
    }
    return false;
  };
  await AppConfigStorage.init();

  runApp(
    const ProviderScope(
      child: MontessoriCareApp(),
    ),
  );
}

class MontessoriCareApp extends ConsumerWidget {
  const MontessoriCareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Montessori Care App',
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      scrollBehavior: const AppScrollBehavior(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
