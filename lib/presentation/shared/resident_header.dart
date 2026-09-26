import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../family_portal/resident_provider.dart';
import 'resident_switch_modal.dart';
import 'middle_tab_selector.dart';

class ResidentHeader extends ConsumerWidget {
  final int? activeTabIndex;
  final ValueChanged<int>? onTabSelected;

  const ResidentHeader({
    super.key,
    this.activeTabIndex,
    this.onTabSelected,
  });

  int _resolveCurrentIndex(BuildContext context) {
    if (activeTabIndex != null) return activeTabIndex!;
    try {
      final location = GoRouterState.of(context).matchedLocation;
      if (location.startsWith('/memories')) return 1;
      if (location.startsWith('/mood')) return 2;
      if (location.startsWith('/tasks')) return 3;
      if (location.startsWith('/health')) return 4;
      if (location.startsWith('/guide')) return 5;
      return 0;
    } catch (_) {
      return 0;
    }
  }

  void _onTabSelected(BuildContext context, int index) {
    if (onTabSelected != null) {
      onTabSelected!(index);
      return;
    }
    const routes = [
      '/portal',
      '/memories',
      '/mood',
      '/tasks',
      '/health',
      '/guide',
    ];
    if (index >= 0 && index < routes.length) {
      try {
        debugPrint('Navigating to tab $index: ${routes[index]}');
        context.go(routes[index]);
      } catch (e, stack) {
        debugPrint('Navigation error: $e\n$stack');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resident = ref.watch(residentProvider);
    final contact = resident.contacts.isNotEmpty ? resident.contacts.first : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  'Kubo North',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Home Circle · Family Care',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            resident.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Age ${resident.age}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (contact != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${contact.name} (${contact.relation}) — ${contact.phone}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => ResidentSwitchModal.show(context),
                  icon: const Icon(Icons.swap_horiz, size: 18, color: AppColors.primary),
                  label: const Text(
                    'Switch',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.surfaceVariant,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: const Size(48, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Middle Navigation Selectors matching Figma design
            MiddleTabSelector(
              currentIndex: _resolveCurrentIndex(context),
              onTabSelected: (index) => _onTabSelected(context, index),
            ),
          ],
        ),
      ),
    );
  }
}
