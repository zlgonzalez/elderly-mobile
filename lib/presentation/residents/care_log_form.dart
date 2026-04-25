import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/care_log_entity.dart';
import 'residents_provider.dart';
import '../auth/auth_provider.dart';

class CareLogForm extends ConsumerStatefulWidget {
  final String residentId;

  const CareLogForm({
    super.key,
    required this.residentId,
  });

  @override
  ConsumerState<CareLogForm> createState() => _CareLogFormState();
}

class _CareLogFormState extends ConsumerState<CareLogForm> {
  final _notesController = TextEditingController();
  String _selectedCategory = 'Meaningful Work';
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Meaningful Work',
    'Self-Care',
    'Grace & Courtesy',
    'Social Interaction',
    'Medical/Health',
    'Nutrition',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final notes = _notesController.text.trim();
    if (notes.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final repo = await ref.read(careLogRepositoryProvider.future);
      final currentUser = ref.read(authProvider).user;

      final log = CareLogEntity()
        ..residentId = widget.residentId
        ..caregiverId = currentUser?.remoteId ?? 'anonymous'
        ..timestamp = DateTime.now()
        ..category = _selectedCategory
        ..notes = notes
        ..isSynced = false;

      await repo.saveCareLog(log);
      
      if (mounted) {
        // Refresh logs list
        ref.invalidate(residentLogsProvider(widget.residentId));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving log: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Log Activity',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categories.map((c) => DropdownMenuItem(
                value: c,
                child: Text(c),
              )).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategory = val);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Engagement Notes',
                hintText: 'Describe the activity and engagement level...',
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              enabled: !_isSubmitting,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save Log'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
