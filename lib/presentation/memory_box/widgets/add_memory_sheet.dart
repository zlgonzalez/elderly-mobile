import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/memory_item.dart';
import '../../auth/auth_provider.dart';
import '../../family_portal/resident_provider.dart';
import '../memory_box_provider.dart';

class AddMemorySheet extends ConsumerStatefulWidget {
  const AddMemorySheet({super.key});

  @override
  ConsumerState<AddMemorySheet> createState() => _AddMemorySheetState();
}

class _AddMemorySheetState extends ConsumerState<AddMemorySheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _urlController = TextEditingController();
  final _tagsController = TextEditingController();
  late final TextEditingController _sharedByController;

  MemoryFormat _selectedFormat = MemoryFormat.photo;
  DateTime _selectedDate = DateTime.now();
  String? _selectedPresetImage;

  final List<Map<String, String>> _presetPhotos = [
    {
      'label': 'Wedding & Family',
      'url': '/api/v1/media/memories/wedding_1965.png',
    },
    {
      'label': 'Garden & Courtyard',
      'url': '/api/v1/media/memories/garden_bloom.png',
    },
    {
      'label': 'Teaching & Mentorship',
      'url': '/api/v1/media/memories/teaching_1968.png',
    },
    {
      'label': 'Autumn Nature Walk',
      'url': '/api/v1/media/memories/autumn_walk.png',
    },
    {
      'label': 'Letters & Keepsakes',
      'url': '/api/v1/media/memories/story_letter.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _sharedByController = TextEditingController(text: user?.fullName ?? 'Family Member');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _urlController.dispose();
    _tagsController.dispose();
    _sharedByController.dispose();
    super.dispose();
  }

  void _saveMemory() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final resident = ref.read(residentProvider);
    final rawTags = _tagsController.text.trim();
    final tags = rawTags.isEmpty
        ? <String>[]
        : rawTags
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .map((t) => t.startsWith('#') ? t : '#$t')
            .toList();

    String? mediaUrl = _urlController.text.trim();
    if (mediaUrl.isEmpty && _selectedPresetImage != null) {
      mediaUrl = _selectedPresetImage;
    }
    if (mediaUrl != null && mediaUrl.isEmpty) {
      mediaUrl = null;
    }

    final memory = MemoryItem(
      id: 'mem_${DateTime.now().millisecondsSinceEpoch}',
      residentId: resident.id,
      format: _selectedFormat,
      title: _titleController.text.trim(),
      content: _contentController.text.trim().isEmpty ? null : _contentController.text.trim(),
      mediaUrl: mediaUrl,
      date: _selectedDate,
      sharedBy: _sharedByController.text.trim().isEmpty ? 'Family Member' : _sharedByController.text.trim(),
      tags: tags,
    );

    ref.read(memoryBoxProvider.notifier).addMemory(memory);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Memory "${memory.title}" added to Memory Box'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add to Memory Box',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Format Selector Tabs
              Row(
                children: MemoryFormat.values.map((format) {
                  final isSelected = _selectedFormat == format;
                  IconData icon;
                  switch (format) {
                    case MemoryFormat.photo:
                      icon = Icons.photo_library_outlined;
                      break;
                    case MemoryFormat.story:
                      icon = Icons.auto_stories_outlined;
                      break;
                    case MemoryFormat.letter:
                      icon = Icons.mail_outline;
                      break;
                    case MemoryFormat.video:
                      icon = Icons.videocam_outlined;
                      break;
                  }

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () => setState(() => _selectedFormat = format),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.surfaceVariant : AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.borderLight,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                icon,
                                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                size: 22,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                format.displayName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  hintText: 'e.g. Summer at the lake, 1978',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a memory title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Media / Content based on format
              if (_selectedFormat == MemoryFormat.photo || _selectedFormat == MemoryFormat.video) ...[
                Text(
                  'Select or paste photo',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 64,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _presetPhotos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      final item = _presetPhotos[idx];
                      final isSelected = _selectedPresetImage == item['url'];
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedPresetImage = item['url'];
                            _urlController.text = item['url']!;
                          });
                        },
                        child: Container(
                          width: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.borderLight,
                              width: isSelected ? 2.5 : 1,
                            ),
                            color: AppColors.surfaceVariant,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  ref.read(apiClientProvider).resolveMediaUrl(item['url']!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.image, color: AppColors.primary),
                                ),
                                if (isSelected)
                                  Container(
                                    color: AppColors.primary.withOpacity(0.3),
                                    child: const Icon(Icons.check, color: Colors.white),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'Or paste a photo URL...',
                    prefixIcon: Icon(Icons.link),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Content / Story text
              TextFormField(
                controller: _contentController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: _selectedFormat == MemoryFormat.letter ? 'Letter text *' : 'Description / Story',
                  hintText: 'Share details, feelings, or memories associated with this...',
                ),
              ),
              const SizedBox(height: 16),

              // Date and Shared By
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(1920),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          prefixIcon: Icon(Icons.calendar_today, size: 18),
                        ),
                        child: Text(
                          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _sharedByController,
                      decoration: const InputDecoration(
                        labelText: 'Shared by',
                        prefixIcon: Icon(Icons.person_outline, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Tags
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags',
                  hintText: 'family, milestone, joy (comma-separated)',
                  prefixIcon: Icon(Icons.tag, size: 18),
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _saveMemory,
                      icon: const Icon(Icons.check),
                      label: const Text('Save Memory'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
