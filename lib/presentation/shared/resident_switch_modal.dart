import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/fixtures/resident_fixtures.dart';
import '../../data/local/profile_storage_manager.dart';
import '../family_portal/resident_provider.dart';

class ResidentSwitchModal extends ConsumerWidget {
  const ResidentSwitchModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const ResidentSwitchModal(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentResident = ref.watch(residentProvider);
    final allResidents = ResidentFixtures.allResidents;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Switch Managed Resident',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Select a loved one to view their personalized care dashboard:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ...allResidents.map((res) {
            final isSelected = res.id == currentResident.id;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.surfaceVariant : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.borderLight,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: (res.avatarUrl.isNotEmpty && res.avatarUrl.startsWith('http'))
                      ? NetworkImage(res.avatarUrl)
                      : null,
                  child: (res.avatarUrl.isEmpty || !res.avatarUrl.startsWith('http'))
                      ? Text(
                          res.name.substring(0, 1),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                title: Text(
                  res.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text('Age ${res.age} · ${res.contacts.first.relation}'),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: () {
                  ref.read(residentProvider.notifier).selectResident(res);
                  Navigator.of(context).pop();
                },
              ),
            );
          }),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              ref.read(profileStorageManagerProvider).resetAllToDemo();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All resident profiles and data reset to demo defaults.'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            icon: const Icon(Icons.restart_alt, size: 20),
            label: const Text('Reset to Demo Defaults'),
          ),
        ],
      ),
    );
  }
}
