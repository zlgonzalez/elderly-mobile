import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'sidebar_nav.dart';
import 'bottom_nav.dart';

class ResponsiveLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ResponsiveLayout({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width >= 800;

    if (isLargeScreen) {
      return Scaffold(
        body: Row(
          children: [
            SidebarNav(navigationShell: navigationShell),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: navigationShell,
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNav(navigationShell: navigationShell),
    );
  }
}
