import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/auth/welcome_screen.dart';
import '../../presentation/auth/login_screen.dart';
import '../../presentation/shared/responsive_layout.dart';
import '../../presentation/dashboard/dashboard_screen.dart';
import '../../presentation/residents/residents_list_screen.dart';
import '../../presentation/residents/resident_profile_screen.dart';
import '../../presentation/careguide/chat_screen.dart';
import '../../presentation/settings/profile_settings_screen.dart';
import '../../presentation/auth/auth_provider.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

// Provide the router via Riverpod so it can react to auth state changes later
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    navigatorKey: _rootNavigatorKey,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ResponsiveLayout(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/residents',
                builder: (context, state) => const ResidentsListScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => ResidentProfileScreen(
                      residentId: state.pathParameters['id'] ?? '',
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/careguide',
                builder: (context, state) => const ChatScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const ProfileSettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoggedIn = authState.user != null;
      final isAuthPath = state.matchedLocation == '/' || state.matchedLocation == '/login';

      if (!isLoggedIn && !isAuthPath) {
        return '/';
      }
      if (isLoggedIn && isAuthPath) {
        return '/dashboard';
      }
      return null;
    },
  );
});

class PlaceholderScaffold extends StatelessWidget {
  final String title;
  const PlaceholderScaffold({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('Screen: $title')),
    );
  }
}
