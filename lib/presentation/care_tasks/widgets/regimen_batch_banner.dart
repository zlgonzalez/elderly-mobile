import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/care_tasks_repository.dart';
import '../../../domain/entities/regimen_plan.dart';
import '../../family_portal/resident_provider.dart';
import '../care_tasks_provider.dart';
import '../regimen_batch_provider.dart';
import 'regimen_preview_sheet.dart';

class RegimenBatchBanner extends ConsumerWidget {
  const RegimenBatchBanner({super.key});

  Future<void> _openPreview(
    BuildContext context,
    WidgetRef ref,
    RegimenBatchJob job,
  ) async {
    var plan = job.plan;
    if (plan == null) {
      await ref
          .read(regimenBatchProvider.notifier)
          .refreshActiveJob(job.residentId);
      plan = ref.read(regimenBatchProvider).jobForResident(job.residentId)?.plan;
    }
    if (plan == null) {
      try {
        final hydrated = await ref
            .read(careTasksRepositoryProvider)
            .getBatchJob(job.residentId, job.id);
        plan = hydrated.plan;
      } catch (_) {}
    }
    if (plan != null) {
      ref.read(careTasksProvider.notifier).setPreviewPlanFromBatch(plan);
    }
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const RegimenPreviewSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resident = ref.watch(residentProvider);
    final batchState = ref.watch(regimenBatchProvider);
    final job = batchState.jobForResident(resident.id);
    if (job == null || job.status == BatchJobStatus.canceled) {
      return const SizedBox.shrink();
    }

    final notifier = ref.read(regimenBatchProvider.notifier);

    Color borderColor = AppColors.primary.withOpacity(0.25);
    Color bgColor = AppColors.surfaceVariant;
    IconData icon = Icons.auto_awesome;
    Color iconColor = AppColors.primary;

    if (job.isFailed) {
      borderColor = AppColors.statusRed.withOpacity(0.35);
      bgColor = AppColors.statusRed.withOpacity(0.08);
      icon = Icons.error_outline;
      iconColor = AppColors.statusRed;
    } else if (job.isCompleted) {
      borderColor = AppColors.statusGreen.withOpacity(0.35);
      bgColor = AppColors.statusGreen.withOpacity(0.08);
      icon = Icons.check_circle_outline;
      iconColor = AppColors.statusGreen;
    }

    String title;
    String subtitle;
    if (job.status == BatchJobStatus.queued) {
      title = job.jobType == BatchJobType.refinement
          ? 'Regimen refinement queued'
          : '7-day regimen queued';
      subtitle = 'Waiting for background worker... You can continue using the app.';
    } else if (job.status == BatchJobStatus.inProgress) {
      title = '${job.phase.title} in progress';
      subtitle = job.phase.description;
    } else if (job.isCompleted) {
      title = '7-day Montessori regimen ready for review';
      subtitle = 'Tap Review Plan to inspect the schedule and clinical scorecard.';
    } else {
      title = 'Regimen generation did not complete';
      subtitle = job.errorMessage?.isNotEmpty == true
          ? job.errorMessage!
          : 'You can retry AI generation or apply the clinical baseline schedule.';
    }

    return Container(
      key: const Key('regimen_batch_banner'),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (job.isActive)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              else
                Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!job.isActive)
                IconButton(
                  tooltip: 'Dismiss',
                  icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                  onPressed: () => notifier.dismissJob(resident.id),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (job.isActive) ...[
                OutlinedButton(
                  onPressed: batchState.isSubmitting
                      ? null
                      : () => notifier.cancelActiveJob(resident.id),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Cancel'),
                ),
                FilledButton.tonal(
                  onPressed: batchState.isSubmitting
                      ? null
                      : () async {
                          await notifier.applyImmediateBaseline(resident);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Applied deterministic 7-day clinical baseline schedule.',
                                ),
                              ),
                            );
                          }
                        },
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Use Clinical Baseline Schedule'),
                ),
              ] else if (job.isCompleted) ...[
                ElevatedButton.icon(
                  onPressed: () => _openPreview(context, ref, job),
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('Review Plan'),
                  style: ElevatedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ] else if (job.isFailed) ...[
                ElevatedButton.icon(
                  onPressed: batchState.isSubmitting
                      ? null
                      : () => notifier.retryFailedJob(resident),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                FilledButton.tonal(
                  onPressed: batchState.isSubmitting
                      ? null
                      : () => notifier.applyImmediateBaseline(resident),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Use Clinical Baseline Schedule'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
