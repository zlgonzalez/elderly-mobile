import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../family_portal/resident_provider.dart';
import 'widgets/life_portrait_card.dart';
import 'widgets/milestone_timeline.dart';

class TheirStoryScreen extends ConsumerWidget {
  final VoidCallback? onAddMemoryTap;

  const TheirStoryScreen({super.key, this.onAddMemoryTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resident = ref.watch(residentProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${resident.name}\'s Story'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LifePortraitCard(resident: resident),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: MilestoneTimeline(milestones: resident.milestones),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primaryLight),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.favorite, color: AppColors.primary, size: 28),
                    const SizedBox(height: 8),
                    const Text(
                      'Preserve a Family Memory',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Contribute a story, photograph, or letter to enrich their life story.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: onAddMemoryTap ?? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Open Add Memory sheet from Memory Box.')),
                        );
                      },
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: const Text('Add to Memory Box'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
