import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/auth/demo_login_screen.dart';
import '../../presentation/auth/login_screen.dart';
import '../../presentation/auth/auth_provider.dart';
import '../../presentation/shared/responsive_layout.dart';
import '../../presentation/family_portal/family_portal_screen.dart';
import '../../presentation/their_story/their_story_screen.dart';
import '../../presentation/memory_box/memory_box_screen.dart';
import '../../presentation/mood_journal/mood_journal_screen.dart';
import '../../presentation/care_tasks/care_tasks_screen.dart';
import '../../presentation/health_vitals/health_vitals_screen.dart';
import '../../presentation/activity_guide/activity_guide_screen.dart';
import '../../presentation/ai_assistant/ai_assistant_drawer.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    navigatorKey: _rootNavigatorKey,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const DemoLoginScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/story',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TheirStoryScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ResponsiveLayout(navigationShell: navigationShell);
        },
        branches: [
          // Tab 0: Family Portal
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/portal',
                builder: (context, state) => FamilyPortalScreen(
                  onAskKuboTap: () => AiAssistantDrawer.show(context, contextScreen: 'Family Portal'),
                ),
              ),
            ],
          ),
          // Tab 1: Memory Box
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/memories',
                builder: (context, state) => MemoryBoxScreen(
                  onAskKuboTap: () => AiAssistantDrawer.show(context, contextScreen: 'Memory Box'),
                ),
              ),
            ],
          ),
          // Tab 2: Mood Journal
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/mood',
                builder: (context, state) => MoodJournalScreen(
                  onAskKuboTap: () => AiAssistantDrawer.show(context, contextScreen: 'Mood Journal'),
                ),
              ),
            ],
          ),
          // Tab 3: Care Tasks
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tasks',
                builder: (context, state) => CareTasksScreen(
                  onAskKuboTap: () => AiAssistantDrawer.show(context, contextScreen: 'Care Tasks'),
                ),
              ),
            ],
          ),
          // Tab 4: Health & Vitals
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/health',
                builder: (context, state) => HealthVitalsScreen(
                  onAskKuboTap: () => AiAssistantDrawer.show(context, contextScreen: 'Health & Vitals'),
                ),
              ),
            ],
          ),
          // Tab 5: Activity Guide
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/guide',
                builder: (context, state) => ActivityGuideScreen(
                  onAskKuboTap: () => AiAssistantDrawer.show(context, contextScreen: 'Activity Guide'),
                ),
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
        return '/portal';
      }
      return null;
    },
  );
});
