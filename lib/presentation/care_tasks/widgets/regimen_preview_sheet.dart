import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/mock_care_tasks_repository.dart';
import '../../../domain/entities/regimen_plan.dart';
import '../../a2ui/regimen_a2ui_surface.dart';
import '../care_tasks_provider.dart';
import '../regimen_batch_provider.dart';

class RegimenPreviewSheet extends ConsumerStatefulWidget {
  final bool showRefinementInitially;

  const RegimenPreviewSheet({
    super.key,
    this.showRefinementInitially = false,
  });

  @override
  ConsumerState<RegimenPreviewSheet> createState() =>
      _RegimenPreviewSheetState();
}

class _RegimenPreviewSheetState extends ConsumerState<RegimenPreviewSheet> {
  final _refineCtrl = TextEditingController();
  bool _acknowledgeLowScore = false;
  late bool _showRefineBox;
  DateTime? _selectedWeekStartDate;

  @override
  void initState() {
    super.initState();
    _showRefineBox = widget.showRefinementInitially;
  }

  @override
  void dispose() {
    _refineCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _pickStartDate(DateTime initialDate) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(initialDate.year, initialDate.month, initialDate.day),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null && mounted) {
      setState(
        () => _selectedWeekStartDate =
            DateTime.utc(picked.year, picked.month, picked.day),
      );
    }
  }

  Future<void> _submitRefinement(RegimenPlan plan) async {
    final text = _refineCtrl.text.trim();
    if (text.length < 3) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter at least 3 characters for refinement.'),
          ),
        );
      }
      return;
    }
    try {
      await ref.read(regimenBatchProvider.notifier).enqueueRefinement(
            residentId: plan.residentId,
            planId: plan.id,
            instruction: text,
            weekStartDate: _selectedWeekStartDate ?? plan.weekStartDate,
          );
      if (mounted) {
        setState(() {
          _acknowledgeLowScore = false;
          _showRefineBox = false;
          _refineCtrl.clear();
        });
        Navigator.of(context).pop(false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Refinement started in the background. You can keep using the app.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Refinement failed: $e')),
        );
      }
    }
  }

  Future<void> _applyPlan(RegimenPlan plan) async {
    var acknowledged = _acknowledgeLowScore;
    if (plan.requiresLowScoreConfirmation) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Low Clinical Score Confirmation'),
          content: Text(
            'This regimen has a clinical score of ${plan.scorecard?.compositeScore ?? 0}/100 (below 70). '
            'Confirm applying with heightened caregiver supervision?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Confirm & Apply'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      acknowledged = true;
      setState(() => _acknowledgeLowScore = true);
    }

    try {
      await ref.read(careTasksProvider.notifier).applyRegimen(
            plan.id,
            weekStartDate: _selectedWeekStartDate ?? plan.weekStartDate,
            acknowledgeLowScore: acknowledged,
          );
      ref
          .read(regimenBatchProvider.notifier)
          .clearResidentBannerLocally(plan.residentId);
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Applied 7-day ${plan.generationSource.displayName} schedule',
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } on RegimenGateException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to apply regimen: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(careTasksProvider);
    final plan = taskState.activePreviewPlan;
    if (plan == null) {
      return const SizedBox.shrink();
    }

    final isBlocked = plan.hasCriticalSafetyBlock;
    final needsAck = plan.requiresLowScoreConfirmation;
    final canApply = !isBlocked && !taskState.isGenerating;
    final effectiveStartDate = _selectedWeekStartDate ?? plan.weekStartDate;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.96,
      minChildSize: 0.55,
      expand: false,
      builder: (context, scrollCtrl) {
        return Material(
          color: AppColors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Drag handle + Sheet Header
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.fromLTRB(20, 10, 12, 12),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '7-Day Montessori Regimen Preview',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceVariant,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      plan.generationSource.displayName,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  if (plan.scorecard != null)
                                    Text(
                                      'Clinical Score: ${plan.scorecard!.compositeScore}/100',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: plan.scorecard!.isLowScore
                                            ? Colors.orange.shade800
                                            : AppColors.primary,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close preview',
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            ref.read(careTasksProvider.notifier).clearPreview();
                            Navigator.of(context).pop(false);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.borderLight),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                  children: [
                    // Start Date Selector Card
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Week starting: ${_formatDate(effectiveStartDate)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: taskState.isGenerating
                                ? null
                                : () => _pickStartDate(effectiveStartDate),
                            child: const Text('Change Start Date'),
                          ),
                        ],
                      ),
                    ),
                    if (needsAck) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: const Color(0xFFFFF8E6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(color: Color(0xFFF3CF7A)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: CheckboxListTile(
                            value: _acknowledgeLowScore,
                            onChanged: (v) => setState(
                                () => _acknowledgeLowScore = v ?? false),
                            title: const Text(
                              'Clinical score is below 70. Acknowledge and apply with heightened supervision.',
                              style: TextStyle(fontSize: 12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (_showRefineBox) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Refine with Kubo',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _refineCtrl,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                hintText:
                                    'e.g. Replace fine-motor tasks due to hand tremors',
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () =>
                                      setState(() => _showRefineBox = false),
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: taskState.isGenerating
                                      ? null
                                      : () => _submitRefinement(plan),
                                  child: Text(
                                    taskState.isGenerating
                                        ? 'Refining...'
                                        : 'Regenerate Preview',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    // Official Dart A2UI Surface rendering Scorecard + 7-Day Schedule + Activity Cards
                    RegimenA2uiSurface.forPlan(plan: plan),
                  ],
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    top: BorderSide(color: AppColors.borderLight),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: taskState.isGenerating
                            ? null
                            : () => setState(() => _showRefineBox = true),
                        icon: const Icon(Icons.auto_fix_high, size: 18),
                        label: const Text('Refine with Kubo'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: canApply ? () => _applyPlan(plan) : null,
                          icon:
                              const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text('Apply 7-Day Plan'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
