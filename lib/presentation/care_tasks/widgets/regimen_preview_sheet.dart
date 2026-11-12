import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/mock_care_tasks_repository.dart';
import '../../../domain/entities/regimen_plan.dart';
import '../care_tasks_provider.dart';

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
      await ref.read(careTasksProvider.notifier).refineRegimen(
            plan.id,
            text,
            weekStartDate: _selectedWeekStartDate ?? plan.weekStartDate,
          );
      if (mounted) {
        setState(() {
          _acknowledgeLowScore = false;
          _showRefineBox = false;
          _refineCtrl.clear();
        });
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

    final groupedDays = plan.itemsGroupedByDay;
    final dayKeys = groupedDays.keys.toList()..sort();
    final isBlocked = plan.hasCriticalSafetyBlock;
    final needsAck = plan.requiresLowScoreConfirmation;
    final canApply = !isBlocked && !taskState.isGenerating;
    final effectiveStartDate = _selectedWeekStartDate ?? plan.weekStartDate;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.96,
      minChildSize: 0.55,
      expand: false,
      builder: (context, scrollCtrl) {
        return Material(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 16, 8),
                child: Row(
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
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
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
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        ref.read(careTasksProvider.notifier).clearPreview();
                        Navigator.of(context).pop(false);
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (plan.safetyFlags.isNotEmpty || isBlocked) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isBlocked
                              ? Colors.red.shade50
                              : Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isBlocked
                                ? Colors.red.shade300
                                : Colors.amber.shade300,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isBlocked
                                  ? 'Clinical Safety Hold: Escalation Required'
                                  : 'Safety & Comfort Guidelines',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isBlocked
                                    ? Colors.red.shade900
                                    : Colors.amber.shade900,
                              ),
                            ),
                            ...plan.safetyFlags.map(
                              (f) => Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '• $f',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (plan.scorecard != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _scorePill(
                                  'Cognitive: ${plan.scorecard!.cognitiveAlignmentScore}',
                                ),
                                _scorePill(
                                  'Physical: ${plan.scorecard!.physicalAccessibilityScore}',
                                ),
                                _scorePill(
                                  'Engagement: ${plan.scorecard!.purposefulEngagementScore}',
                                ),
                                _scorePill(
                                  'Safety: ${plan.scorecard!.safetyControlOfErrorScore}',
                                ),
                                _scorePill(
                                  'Balance: ${plan.scorecard!.modalityBalanceScore}',
                                ),
                              ],
                            ),
                            if (plan.scorecard!.feedback.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                plan.scorecard!.feedback,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
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
                      CheckboxListTile(
                        value: _acknowledgeLowScore,
                        onChanged: (v) =>
                            setState(() => _acknowledgeLowScore = v ?? false),
                        title: const Text(
                          'Clinical score is below 70. Acknowledge and apply with heightened supervision.',
                          style: TextStyle(fontSize: 12),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                    if (_showRefineBox) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Refine with Kubo',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
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
                            const SizedBox(height: 8),
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
                    ...dayKeys.map((dayNum) {
                      final dayTasks = groupedDays[dayNum] ?? const [];
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: AppColors.borderLight),
                        ),
                        child: ExpansionTile(
                          initiallyExpanded: dayNum == dayKeys.first,
                          title: Text(
                            'Day $dayNum (${dayTasks.length} activities)',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          children: dayTasks.map((t) {
                            return ListTile(
                              title: Text(
                                '${t.time} • ${t.title}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 2),
                                  Text(
                                    t.montessoriDomain ??
                                        t.category.displayName,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  if (t.materialsTraySetup != null &&
                                      t.materialsTraySetup!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'Tray setup: ${t.materialsTraySetup}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  if (t.materials.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'Tray materials: ${t.materials.join(', ')}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  if (t.steps.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Steps:',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          ...t.steps.asMap().entries.map(
                                                (e) => Text(
                                                  '${e.key + 1}. ${e.value}',
                                                  style: const TextStyle(
                                                      fontSize: 11),
                                                ),
                                              ),
                                        ],
                                      ),
                                    ),
                                  if (t.scriptPrompt != null &&
                                      t.scriptPrompt!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 3),
                                      child: Text(
                                        'Prompt: "${t.scriptPrompt}"',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ),
                                  if (t.dignityTip != null &&
                                      t.dignityTip!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 3),
                                      child: Text(
                                        'Dignity tip: ${t.dignityTip}',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ),
                                  if (t.safetyComfort != null &&
                                      t.safetyComfort!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 3),
                                      child: Text(
                                        'Safety & comfort: ${t.safetyComfort}',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ),
                                  if (t.historicalConnection != null &&
                                      t.historicalConnection!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        'Memory link: ${t.historicalConnection}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                child: Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: taskState.isGenerating
                          ? null
                          : () => setState(() => _showRefineBox = true),
                      icon: const Icon(Icons.auto_fix_high, size: 18),
                      label: const Text('Refine with Kubo'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: canApply ? () => _applyPlan(plan) : null,
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Apply 7-Day Plan'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _scorePill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
