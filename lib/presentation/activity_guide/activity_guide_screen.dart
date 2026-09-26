import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/montessori_activity.dart';
import '../shared/resident_header.dart';
import '../shared/ask_kubo_floating_button.dart';
import 'montessori_provider.dart';
import 'widgets/activity_card.dart';

class ActivityGuideScreen extends ConsumerWidget {
  final VoidCallback? onAskKuboTap;

  const ActivityGuideScreen({super.key, this.onAskKuboTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final montessoriState = ref.watch(montessoriProvider);
    final notifier = ref.read(montessoriProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Resident Switch Header
            const ResidentHeader(activeTabIndex: 5),

            // Top Montessori Dignity Banner
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.volunteer_activism_outlined, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Montessori Principles: Support independence, preserve dignity, focus on abilities rather than limitations.',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar & Category Filters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                onChanged: (val) => notifier.setSearchQuery(val),
                decoration: InputDecoration(
                  hintText: 'Search activities, materials, tags...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                ),
              ),
            ),

            // Category Filter Pills (Horizontal)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildCategoryChip(
                    context: context,
                    label: 'All',
                    icon: '🌟',
                    count: montessoriState.getCountForCategory(null),
                    isSelected: montessoriState.selectedCategory == null,
                    onTap: () => notifier.selectCategory(null),
                  ),
                  ...MontessoriCategory.values.map((cat) {
                    final isSelected = montessoriState.selectedCategory == cat;
                    return _buildCategoryChip(
                      context: context,
                      label: cat.label,
                      icon: cat.icon,
                      count: montessoriState.getCountForCategory(cat),
                      isSelected: isSelected,
                      onTap: () => notifier.selectCategory(isSelected ? null : cat),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Activities List Content
            Expanded(
              child: montessoriState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : montessoriState.filteredActivities.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, size: 48, color: AppColors.textSecondary.withOpacity(0.5)),
                                const SizedBox(height: 12),
                                const Text(
                                  'No activities found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Try selecting another category or clearing your search.',
                                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                          itemCount: montessoriState.filteredActivities.length,
                          itemBuilder: (context, index) {
                            final activity = montessoriState.filteredActivities[index];
                            return ActivityCard(activity: activity);
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: AskKuboFloatingButton(
        onPressed: onAskKuboTap,
        contextScreen: 'Activity Guide',
      ),
    );
  }

  Widget _buildCategoryChip({
    required BuildContext context,
    required String label,
    required String icon,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text('$icon $label ($count)'),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.surfaceVariant,
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
          ),
        ),
      ),
    );
  }
}
