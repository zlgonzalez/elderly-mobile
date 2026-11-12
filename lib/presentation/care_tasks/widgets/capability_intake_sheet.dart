import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/resident.dart';

class CapabilityIntakeResult {
  final String cognitiveCapability;
  final String physicalCapability;
  final String cognitiveStage;
  final List<String> motorLimitations;

  const CapabilityIntakeResult({
    required this.cognitiveCapability,
    required this.physicalCapability,
    required this.cognitiveStage,
    required this.motorLimitations,
  });
}

class CapabilityIntakeSheet extends StatefulWidget {
  final Resident resident;

  const CapabilityIntakeSheet({super.key, required this.resident});

  @override
  State<CapabilityIntakeSheet> createState() => _CapabilityIntakeSheetState();
}

class _CapabilityIntakeSheetState extends State<CapabilityIntakeSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _cognitiveCtrl;
  late final TextEditingController _physicalCtrl;
  late String _cognitiveStage;
  late Set<String> _selectedMotorLimits;

  static const _stages = ['mild', 'moderate', 'severe'];
  static const _commonMotorOptions = [
    'hand tremors',
    'mild arthritis',
    'wheelchair user',
    'limited fine motor',
  ];

  @override
  void initState() {
    super.initState();
    _cognitiveCtrl = TextEditingController(
      text: widget.resident.cognitiveCapability ?? '',
    );
    _physicalCtrl = TextEditingController(
      text: widget.resident.physicalCapability ?? '',
    );
    _cognitiveStage = widget.resident.cognitiveStage ?? 'moderate';
    _selectedMotorLimits = Set<String>.from(widget.resident.motorLimitations);
  }

  @override
  void dispose() {
    _cognitiveCtrl.dispose();
    _physicalCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      CapabilityIntakeResult(
        cognitiveCapability: _cognitiveCtrl.text.trim(),
        physicalCapability: _physicalCtrl.text.trim(),
        cognitiveStage: _cognitiveStage,
        motorLimitations: _selectedMotorLimits.toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Resident Capability Intake',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Before generating a tailored Montessori regimen for ${widget.resident.name}, please confirm their current cognitive and physical capabilities. These are saved permanently to their care profile.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cognitiveCtrl,
                decoration: const InputDecoration(
                  labelText: 'Cognitive Capability *',
                  hintText: 'e.g. Follows 1-2 step visual or verbal prompts',
                ),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'Cognitive capability is required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _physicalCtrl,
                decoration: const InputDecoration(
                  labelText: 'Physical Capability *',
                  hintText: 'e.g. Seated stability; mild hand tremors',
                ),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'Physical capability is required'
                    : null,
              ),
              const SizedBox(height: 16),
              const Text(
                'Cognitive Stage',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _stages.map((stage) {
                  final selected = _cognitiveStage == stage;
                  return ChoiceChip(
                    label: Text(stage[0].toUpperCase() + stage.substring(1)),
                    selected: selected,
                    onSelected: (_) => setState(() => _cognitiveStage = stage),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text(
                'Motor Precautions (Optional)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _commonMotorOptions.map((opt) {
                  final selected = _selectedMotorLimits.contains(opt);
                  return FilterChip(
                    label: Text(opt),
                    selected: selected,
                    onSelected: (checked) {
                      setState(() {
                        if (checked) {
                          _selectedMotorLimits.add(opt);
                        } else {
                          _selectedMotorLimits.remove(opt);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
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
                      onPressed: _submit,
                      icon: const Icon(Icons.save_outlined, size: 18),
                      label: const Text('Save & Generate Plan'),
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
