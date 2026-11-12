import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/care_task.dart';
import '../../domain/entities/regimen_plan.dart';
import '../auth/auth_provider.dart';
import '../shared/resident_header.dart';
import '../shared/ask_kubo_floating_button.dart';
import 'care_tasks_provider.dart';
import 'regimen_flow_helper.dart';
import 'widgets/add_task_sheet.dart';

class CareTasksScreen extends ConsumerWidget {
  final VoidCallback? onAskKuboTap;

  const CareTasksScreen({super.key, this.onAskKuboTap});

  void _openAddTaskSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AddTaskSheet(),
    );
  }

  Future<void> _startGenerateRegimen(
    BuildContext context,
    WidgetRef ref, {
    bool openRefine = false,
  }) {
    return startGenerateRegimenFlow(context, ref, openRefine: openRefine);
  }

  void _handleCompleteTask(BuildContext context, WidgetRef ref, CareTask task) {
    final user = ref.read(authProvider).user;
    final completedBy = user?.fullName ?? 'Family Member';
    showDialog<void>(
      context: context,
      builder: (_) => _CompleteTaskDialog(
        task: task,
        completedBy: completedBy,
        hostContext: context,
      ),
    );
  }

  void _handleSkipTask(BuildContext context, WidgetRef ref, CareTask task) {
    showDialog<void>(
      context: context,
      builder: (_) => _SkipTaskDialog(
        task: task,
        hostContext: context,
      ),
    );
  }

  void _openTaskDetailSheet(BuildContext context, CareTask task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: Theme.of(ctx)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  task.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (task.materialsTraySetup != null &&
                    task.materialsTraySetup!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text('Tray Setup',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(task.materialsTraySetup!,
                      style: const TextStyle(fontSize: 13)),
                ],
                if (task.materials.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Materials',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: task.materials
                        .map((m) => Chip(
                              label:
                                  Text(m, style: const TextStyle(fontSize: 12)),
                            ))
                        .toList(),
                  ),
                ],
                if (task.steps.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Facilitation Steps',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  ...task.steps.asMap().entries.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            '${e.key + 1}. ${e.value}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                ],
                if (task.scriptPrompt != null &&
                    task.scriptPrompt!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Invitation Script: ${task.scriptPrompt}',
                    style: const TextStyle(
                        fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
                if (task.historicalConnection != null &&
                    task.historicalConnection!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Historical Connection: ${task.historicalConnection}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.primary),
                  ),
                ],
                if (task.dignityTip != null && task.dignityTip!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Dignity & Safety Tip: ${task.dignityTip}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Color _categoryBg(TaskCategory category) {
    switch (category) {
      case TaskCategory.physical:
        return AppColors.badgePhysical;
      case TaskCategory.activity:
        return AppColors.badgeActivity;
      case TaskCategory.social:
        return AppColors.badgeSocial;
      case TaskCategory.purposeful:
        return AppColors.surfaceVariant;
    }
  }

  Color _categoryText(TaskCategory category) {
    switch (category) {
      case TaskCategory.physical:
        return AppColors.badgePhysicalText;
      case TaskCategory.activity:
        return AppColors.badgeActivityText;
      case TaskCategory.social:
        return AppColors.badgeSocialText;
      case TaskCategory.purposeful:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskState = ref.watch(careTasksProvider);
    final notifier = ref.read(careTasksProvider.notifier);
    final user = ref.watch(authProvider).user;
    final canManageRegimen = canManageRegimenFor(user);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Resident Header
            const ResidentHeader(activeTabIndex: 3),

            // Screen Header & Progress Summary
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Today's Schedule",
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${taskState.completedCount}/${taskState.totalCount} completed today',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _openAddTaskSheet(context),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Task'),
                          style: ElevatedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: taskState.progress,
                        minHeight: 6,
                        backgroundColor: AppColors.surfaceVariant,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary),
                      ),
                    ),
                    if (canManageRegimen) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          OutlinedButton.icon(
                            onPressed: taskState.isGenerating
                                ? null
                                : () => _startGenerateRegimen(context, ref),
                            icon: const Icon(Icons.auto_awesome, size: 15),
                            label: const Text('Generate 7-Day Regimen',
                                style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                            ),
                          ),
                          if (taskState.latestAppliedPlan != null)
                            OutlinedButton.icon(
                              onPressed: taskState.isGenerating
                                  ? null
                                  : () => _startGenerateRegimen(
                                        context,
                                        ref,
                                        openRefine: true,
                                      ),
                              icon: const Icon(Icons.tune, size: 15),
                              label: const Text('Refine with Kubo',
                                  style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Category Filter Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: taskState.selectedCategory == null,
                    onSelected: (_) => notifier.setCategoryFilter(null),
                    selectedColor: AppColors.surfaceVariant,
                    labelStyle: TextStyle(
                      fontWeight: taskState.selectedCategory == null
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: taskState.selectedCategory == null
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ...TaskCategory.values.map((cat) {
                    final isSelected = taskState.selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(cat.displayName),
                        selected: isSelected,
                        onSelected: (_) => notifier.setCategoryFilter(cat),
                        selectedColor: AppColors.surfaceVariant,
                        labelStyle: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Tasks List
            Expanded(
              child: taskState.isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary))
                  : taskState.filteredTasks.isEmpty
                      ? const Center(
                          child: Text(
                            'No care tasks found for this filter.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: taskState.filteredTasks.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final task = taskState.filteredTasks[index];
                            return _buildTaskCard(context, ref, task);
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: AskKuboFloatingButton(
        onPressed: onAskKuboTap,
        contextScreen: 'Care Tasks',
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, WidgetRef ref, CareTask task) {
    final isCompleted = task.status == TaskStatus.completed;
    final isSkipped = task.status == TaskStatus.skipped;
    final hasRichMontessori = task.materials.isNotEmpty ||
        task.steps.isNotEmpty ||
        (task.historicalConnection?.isNotEmpty ?? false);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isCompleted ? AppColors.primaryLight : AppColors.borderLight,
        ),
      ),
      color: isCompleted ? AppColors.surfaceContainerLow : AppColors.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: hasRichMontessori
            ? () => _openTaskDetailSheet(context, task)
            : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time & Category Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Icon(
                          isCompleted
                              ? Icons.check_circle
                              : isSkipped
                                  ? Icons.fast_forward
                                  : Icons.access_time,
                          size: 16,
                          color: isCompleted
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        Text(
                          task.time,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isCompleted
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                        if (task.completedBy != null)
                          Text(
                            '· ✓ ${task.completedBy}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (task.generationSource != null &&
                      task.generationSource != 'manual') ...[
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        RegimenGenerationSource.fromString(
                                task.generationSource)
                            .displayName,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _categoryBg(task.category),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      task.category.displayName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _categoryText(task.category),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                task.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),

              // Description
              Text(
                task.description,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),

              if (hasRichMontessori) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (task.materials.isNotEmpty)
                      Text(
                        'Tray: ${task.materials.take(2).join(', ')}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    const Text(
                      '· Tap for Montessori steps',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],

              if (isSkipped &&
                  task.skipReason != null &&
                  task.skipReason!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Skipped: ${task.skipReason}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
              ],

              // Completion Note if present
              if (task.completionNote != null &&
                  task.completionNote!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.format_quote,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '"${task.completionNote}"',
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Action Buttons for pending tasks
              if (!isCompleted && !isSkipped) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _handleCompleteTask(context, ref, task),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Complete'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => _handleSkipTask(context, ref, task),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                      ),
                      child: const Text('Skip'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CompleteTaskDialog extends ConsumerStatefulWidget {
  final CareTask task;
  final String completedBy;
  final BuildContext hostContext;

  const _CompleteTaskDialog({
    required this.task,
    required this.completedBy,
    required this.hostContext,
  });

  @override
  ConsumerState<_CompleteTaskDialog> createState() =>
      _CompleteTaskDialogState();
}

class _CompleteTaskDialogState extends ConsumerState<_CompleteTaskDialog> {
  final _noteController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    final note =
        _noteController.text.trim().isEmpty ? null : _noteController.text.trim();
    try {
      await ref.read(careTasksProvider.notifier).updateStatus(
            taskId: widget.task.id,
            status: TaskStatus.completed,
            completedBy: widget.completedBy,
            note: note,
          );
      if (mounted) Navigator.of(context).pop();
      if (widget.hostContext.mounted) {
        ScaffoldMessenger.of(widget.hostContext).showSnackBar(
          SnackBar(
            content: Text(
              'Task "${widget.task.title}" marked completed by ${widget.completedBy}',
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      if (widget.hostContext.mounted) {
        ScaffoldMessenger.of(widget.hostContext).showSnackBar(
          SnackBar(content: Text('Could not update task: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Complete "${widget.task.title}"'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sign-off as: ${widget.completedBy}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Care Notes (Optional)',
              hintText: 'e.g. Margaret participated with joy and energy...',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: const Text('Mark Complete'),
        ),
      ],
    );
  }
}

class _SkipTaskDialog extends ConsumerStatefulWidget {
  final CareTask task;
  final BuildContext hostContext;

  const _SkipTaskDialog({
    required this.task,
    required this.hostContext,
  });

  @override
  ConsumerState<_SkipTaskDialog> createState() => _SkipTaskDialogState();
}

class _SkipTaskDialogState extends ConsumerState<_SkipTaskDialog> {
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  static const _quickReasons = [
    'Resident felt tired',
    'Refused gently',
    'Visiting family',
    'Physical discomfort',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    final reason = _reasonController.text.trim().isEmpty
        ? null
        : _reasonController.text.trim();
    try {
      await ref.read(careTasksProvider.notifier).updateStatus(
            taskId: widget.task.id,
            status: TaskStatus.skipped,
            skipReason: reason,
          );
      if (mounted) Navigator.of(context).pop();
      if (widget.hostContext.mounted) {
        ScaffoldMessenger.of(widget.hostContext).showSnackBar(
          SnackBar(content: Text('Task "${widget.task.title}" skipped')),
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      if (widget.hostContext.mounted) {
        ScaffoldMessenger.of(widget.hostContext).showSnackBar(
          SnackBar(content: Text('Could not skip task: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Skip "${widget.task.title}"'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Share why this activity was skipped so Kubo adapts upcoming suggestions:',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _quickReasons.map((r) {
                return ActionChip(
                  label: Text(r, style: const TextStyle(fontSize: 11)),
                  onPressed: () => _reasonController.text = r,
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Skip Reason (Optional)',
                hintText: 'e.g. Tired after breakfast',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: const Text('Confirm Skip'),
        ),
      ],
    );
  }
}
