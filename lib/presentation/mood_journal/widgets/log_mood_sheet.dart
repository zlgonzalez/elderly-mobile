import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/mood_entry.dart';
import '../../auth/auth_provider.dart';
import '../../family_portal/resident_provider.dart';
import '../mood_journal_provider.dart';

class LogMoodSheet extends ConsumerStatefulWidget {
  const LogMoodSheet({super.key});

  @override
  ConsumerState<LogMoodSheet> createState() => _LogMoodSheetState();
}

class _LogMoodSheetState extends ConsumerState<LogMoodSheet> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  late final TextEditingController _recordedByController;
  MoodType _selectedMood = MoodType.happy;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _recordedByController = TextEditingController(text: user?.fullName ?? 'Family Member');
  }

  @override
  void dispose() {
    _notesController.dispose();
    _recordedByController.dispose();
    super.dispose();
  }

  void _saveMood() {
    if (!_formKey.currentState!.validate()) return;

    final resident = ref.read(residentProvider);
    final entry = MoodEntry(
      id: 'mood_${DateTime.now().millisecondsSinceEpoch}',
      residentId: resident.id,
      mood: _selectedMood,
      timestamp: DateTime.now(),
      recordedBy: _recordedByController.text.trim().isEmpty ? 'Family Member' : _recordedByController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    ref.read(moodJournalProvider.notifier).logMood(entry);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mood "${_selectedMood.label}" logged by ${entry.recordedBy}'),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Log Current Mood',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text(
                'How is your loved one feeling right now?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 12),

              // Mood Selector Grid
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.1,
                children: MoodType.values.map((mood) {
                  final isSelected = _selectedMood == mood;
                  return InkWell(
                    onTap: () => setState(() => _selectedMood = mood),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.surfaceVariant : AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.borderLight,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(mood.emoji, style: const TextStyle(fontSize: 28)),
                          const SizedBox(height: 4),
                          Text(
                            mood.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Recorded by
              TextFormField(
                controller: _recordedByController,
                decoration: const InputDecoration(
                  labelText: 'Recorded by *',
                  prefixIcon: Icon(Icons.person_outline, size: 18),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Required';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Observations / Context Notes
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Observational Context / Notes',
                  hintText: 'e.g. Margaret smiled during the walk, recognized Sarah...',
                ),
              ),
              const SizedBox(height: 20),

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
                      onPressed: _saveMood,
                      icon: const Icon(Icons.check),
                      label: const Text('Save Mood Entry'),
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
