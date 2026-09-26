import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

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
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.surfaceVariant,
      labelType: NavigationRailLabelType.all,
      selectedLabelTextStyle: GoogleFonts.plusJakartaSans(
        color: AppColors.primary,
        fontWeight: FontWeight.bold,
        fontSize: 11,
      ),
      unselectedLabelTextStyle: GoogleFonts.plusJakartaSans(
        color: AppColors.textSecondary,
        fontSize: 11,
      ),
      selectedIconTheme: const IconThemeData(color: AppColors.primary),
      unselectedIconTheme: const IconThemeData(color: AppColors.textSecondary),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: Text('Portal'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.photo_album_outlined),
          selectedIcon: Icon(Icons.photo_album),
          label: Text('Memories'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.mood_outlined),
          selectedIcon: Icon(Icons.mood),
          label: Text('Mood'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.checklist_outlined),
          selectedIcon: Icon(Icons.checklist),
          label: Text('Tasks'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.monitor_heart_outlined),
          selectedIcon: Icon(Icons.monitor_heart),
          label: Text('Health'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.spa_outlined),
          selectedIcon: Icon(Icons.spa),
          label: Text('Guide'),
        ),
      ],
      leading: const Column(
        children: [
          SizedBox(height: 24),
          Icon(
            Icons.spa_rounded,
            color: AppColors.primary,
            size: 32,
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}
