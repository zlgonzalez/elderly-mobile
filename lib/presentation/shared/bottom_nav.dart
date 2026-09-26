import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_bottom_nav.dart';

class BottomNav extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const BottomNav({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return AppBottomNav(
      currentIndex: navigationShell.currentIndex,
      onTabSelected: (index) {
        navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        );
      },
    );
  }
}
