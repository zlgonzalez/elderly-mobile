import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/care_task.dart';
import '../auth/auth_provider.dart';
import '../shared/resident_header.dart';
import '../shared/ask_kubo_floating_button.dart';
import 'care_tasks_provider.dart';
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

  void _handleCompleteTask(BuildContext context, WidgetRef ref, CareTask task) {
    final user = ref.read(authProvider).user;
    final completedBy = user?.fullName ?? 'Family Member';

    showDialog(
      context: context,
      builder: (ctx) {
        final noteController = TextEditingController();
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Complete "${task.title}"'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sign-off as: $completedBy', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Care Notes (Optional)',
                  hintText: 'e.g. Margaret participated with joy and energy...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(careTasksProvider.notifier).updateStatus(
                      taskId: task.id,
                      status: TaskStatus.completed,
                      completedBy: completedBy,
                      note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                    );
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Task "${task.title}" marked completed by $completedBy'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              child: const Text('Mark Complete'),
            ),
          ],
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Resident Header
            const ResidentHeader(activeTabIndex: 3),

            // Screen Header & Progress Summary
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(16),
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
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
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
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: taskState.progress,
                        minHeight: 8,
                        backgroundColor: AppColors.surfaceVariant,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
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
                      fontWeight: taskState.selectedCategory == null ? FontWeight.bold : FontWeight.normal,
                      color: taskState.selectedCategory == null ? AppColors.primary : AppColors.textPrimary,
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
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Task List
            Expanded(
              child: taskState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : taskState.filteredTasks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_outline, size: 48, color: AppColors.textMuted),
                              const SizedBox(height: 12),
                              const Text('No care activities for this category'),
                              const SizedBox(height: 8),
                              OutlinedButton(
                                onPressed: () => _openAddTaskSheet(context),
                                child: const Text('Schedule an activity'),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: taskState.filteredTasks.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
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

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isCompleted ? AppColors.primaryLight : AppColors.borderLight,
        ),
      ),
      color: isCompleted ? AppColors.surfaceContainerLow : AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                        isCompleted ? Icons.check_circle : Icons.access_time,
                        size: 16,
                        color: isCompleted ? AppColors.primary : AppColors.textSecondary,
                      ),
                      Text(
                        task.time,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isCompleted ? AppColors.primary : AppColors.textSecondary,
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isCompleted ? AppColors.textPrimary : AppColors.textPrimary,
                decoration: isCompleted ? TextDecoration.none : null,
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

            // Completion Note if present
            if (task.completionNote != null && task.completionNote!.isNotEmpty) ...[
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
                    const Icon(Icons.format_quote, size: 16, color: AppColors.primary),
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
            if (!isCompleted) ...[
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
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      ref.read(careTasksProvider.notifier).updateStatus(
                            taskId: task.id,
                            status: TaskStatus.skipped,
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Task "${task.title}" skipped')),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
