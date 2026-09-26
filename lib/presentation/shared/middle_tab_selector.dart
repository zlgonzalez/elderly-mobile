import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class TabItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const TabItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class MiddleTabSelector extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  static const List<TabItemData> tabs = [
    TabItemData(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Portal',
    ),
    TabItemData(
      icon: Icons.photo_library_outlined,
      activeIcon: Icons.photo_library_rounded,
      label: 'Memories',
    ),
    TabItemData(
      icon: Icons.sentiment_satisfied_alt_outlined,
      activeIcon: Icons.mood_rounded,
      label: 'Mood',
    ),
    TabItemData(
      icon: Icons.fact_check_outlined,
      activeIcon: Icons.checklist_rounded,
      label: 'Tasks',
    ),
    TabItemData(
      icon: Icons.favorite_outline,
      activeIcon: Icons.favorite_rounded,
      label: 'Health',
    ),
    TabItemData(
      icon: Icons.spa_outlined,
      activeIcon: Icons.spa_rounded,
      label: 'Guide',
    ),
  ];

  const MiddleTabSelector({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0x66D0FAE5), // rgba(208, 250, 229, 0.4)
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(tabs.length, (index) {
            final tab = tabs[index];
            final isSelected = index == currentIndex;

            return Expanded(
              child: Tooltip(
                message: tab.label,
                child: InkWell(
                  onTap: () => onTabSelected(index),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0x80ECFDF5) // rgba(236, 253, 245, 0.5)
                          : Colors.transparent,
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected
                              ? const Color(0xFF00BC7D) // #00BC7D emerald active line
                              : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        isSelected ? tab.activeIcon : tab.icon,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textMuted,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
