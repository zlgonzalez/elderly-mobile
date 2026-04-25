import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class SidebarNav extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const SidebarNav({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: (index) {
        navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        );
      },
      backgroundColor: AppTheme.surfaceColor,
      indicatorColor: AppTheme.primaryColor.withAlpha(26),
      labelType: NavigationRailLabelType.all,
      selectedLabelTextStyle: GoogleFonts.publicSans(
        color: AppTheme.primaryColor,
        fontWeight: FontWeight.bold,
      ),
      unselectedLabelTextStyle: GoogleFonts.publicSans(
        color: AppTheme.textSecondary,
      ),
      selectedIconTheme: const IconThemeData(color: AppTheme.primaryColor),
      unselectedIconTheme: const IconThemeData(color: AppTheme.textSecondary),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: Text('Dashboard'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: Text('Residents'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.chat_bubble_outline),
          selectedIcon: Icon(Icons.chat_bubble),
          label: Text('CareGuide'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text('Settings'),
        ),
      ],
      leading: Column(
        children: [
          const SizedBox(height: 24),
          const Icon(
            Icons.spa_rounded,
            color: AppTheme.primaryColor,
            size: 32,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
