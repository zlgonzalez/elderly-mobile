import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'data/local/user_entity.dart';
import 'data/local/resident_entity.dart';
import 'data/local/care_log_entity.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(UserEntityAdapter());
  Hive.registerAdapter(ResidentEntityAdapter());
  Hive.registerAdapter(CareLogEntityAdapter());

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
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
