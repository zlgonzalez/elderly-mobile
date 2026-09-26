import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/memory_item.dart';
import '../shared/resident_header.dart';
import '../shared/ask_kubo_floating_button.dart';
import 'memory_box_provider.dart';
import 'widgets/add_memory_sheet.dart';

class MemoryBoxScreen extends ConsumerWidget {
  final VoidCallback? onAskKuboTap;

  const MemoryBoxScreen({super.key, this.onAskKuboTap});

  void _openAddMemorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AddMemorySheet(),
    );
  }

  void _openMemoryDetail(BuildContext context, MemoryItem memory) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              _formatIcon(memory.format),
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                memory.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (memory.mediaUrl != null && memory.mediaUrl!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    memory.mediaUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 120,
                      color: AppColors.surfaceVariant,
                      child: const Center(
                        child: Icon(Icons.broken_image, color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                '${memory.date.year}-${memory.date.month.toString().padLeft(2, '0')}-${memory.date.day.toString().padLeft(2, '0')} • Shared by ${memory.sharedBy}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              if (memory.content != null && memory.content!.isNotEmpty) ...[
                Text(
                  memory.content!,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 12),
              ],
              if (memory.tags.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: memory.tags.map((tag) {
                    return Chip(
                      label: Text(tag, style: const TextStyle(fontSize: 11, color: AppColors.primary)),
                      backgroundColor: AppColors.surfaceVariant,
                      padding: EdgeInsets.zero,
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  IconData _formatIcon(MemoryFormat format) {
    switch (format) {
      case MemoryFormat.photo:
        return Icons.photo_outlined;
      case MemoryFormat.story:
        return Icons.auto_stories_outlined;
      case MemoryFormat.letter:
        return Icons.mail_outline;
      case MemoryFormat.video:
        return Icons.videocam_outlined;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memoryState = ref.watch(memoryBoxProvider);
    final notifier = ref.read(memoryBoxProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Resident Switch Header
            const ResidentHeader(activeTabIndex: 1),

            // Screen Title & Action Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Memory Box',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          '${memoryState.memories.length} family memories preserved',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _openAddMemorySheet(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Memory'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),

            // Format Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: memoryState.selectedFormat == null,
                    onSelected: (_) => notifier.setFormatFilter(null),
                    selectedColor: AppColors.surfaceVariant,
                    labelStyle: TextStyle(
                      fontWeight: memoryState.selectedFormat == null ? FontWeight.bold : FontWeight.normal,
                      color: memoryState.selectedFormat == null ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ...MemoryFormat.values.map((format) {
                    final isSelected = memoryState.selectedFormat == format;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        avatar: Icon(_formatIcon(format), size: 16, color: isSelected ? AppColors.primary : AppColors.textSecondary),
                        label: Text(format.displayName),
                        selected: isSelected,
                        onSelected: (_) => notifier.setFormatFilter(format),
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

            // Memories List
            Expanded(
              child: memoryState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : memoryState.filteredMemories.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.photo_album_outlined, size: 48, color: AppColors.textMuted),
                              const SizedBox(height: 12),
                              const Text('No memories found'),
                              const SizedBox(height: 8),
                              OutlinedButton(
                                onPressed: () => _openAddMemorySheet(context),
                                child: const Text('Contribute first memory'),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                          itemCount: memoryState.filteredMemories.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final memory = memoryState.filteredMemories[index];
                            return _buildMemoryCard(context, memory, notifier);
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: AskKuboFloatingButton(
        onPressed: onAskKuboTap,
        contextScreen: 'Memory Box',
      ),
    );
  }

  Widget _buildMemoryCard(BuildContext context, MemoryItem memory, MemoryBoxNotifier notifier) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      color: AppColors.surface,
      child: InkWell(
        onTap: () => _openMemoryDetail(context, memory),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (memory.mediaUrl != null && memory.mediaUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  memory.mediaUrl!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 100,
                    color: AppColors.surfaceVariant,
                    child: const Center(
                      child: Icon(Icons.image_outlined, color: AppColors.primary),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_formatIcon(memory.format), size: 12, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              memory.format.displayName,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${memory.date.year}-${memory.date.month.toString().padLeft(2, '0')}-${memory.date.day.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    memory.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (memory.content != null && memory.content!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      memory.content!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        'Shared by ${memory.sharedBy}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      if (memory.tags.isNotEmpty)
                        Wrap(
                          spacing: 4,
                          children: memory.tags.take(2).map((t) {
                            return Text(
                              t,
                              style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
