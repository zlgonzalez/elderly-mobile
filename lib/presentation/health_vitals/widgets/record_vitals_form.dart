import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/fixtures/resident_fixtures.dart';
import '../../../domain/entities/resident.dart';
import '../../../domain/entities/vital_sign.dart';
import '../../auth/auth_provider.dart';
import '../../family_portal/resident_provider.dart';
import '../health_vitals_provider.dart';

class RecordVitalsForm extends ConsumerStatefulWidget {
  const RecordVitalsForm({super.key});

  @override
  ConsumerState<RecordVitalsForm> createState() => _RecordVitalsFormState();
}

class _RecordVitalsFormState extends ConsumerState<RecordVitalsForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _bpController;
  late final TextEditingController _hrController;
  late final TextEditingController _tempController;
  late final TextEditingController _weightController;
  final _notesController = TextEditingController();
  late final TextEditingController _recordedByController;

  String _mobilityLevel = 'Independent';
  double _painLevel = 0.0;
  String? _populatedForResidentId;
  String? _populatedVitalId;

  final List<String> _mobilityOptions = [
    'Independent',
    'Assisted Walk',
    'Wheelchair',
    'Bedbound',
  ];

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _recordedByController = TextEditingController(text: user?.fullName ?? 'Nurse Jane');
    _bpController = TextEditingController();
    _hrController = TextEditingController();
    _tempController = TextEditingController();
    _weightController = TextEditingController();

    final resident = ref.read(residentProvider);
    final vitalsState = ref.read(healthVitalsProvider);
    _applyVitalsToForm(resident.id, vitalsState.latest);
  }

  void _applyVitalsToForm(String residentId, VitalSign? latest) {
    final fixtureId = ResidentFixtures.toFixtureId(residentId);
    _populatedForResidentId = fixtureId;
    _populatedVitalId = latest?.id;

    if (latest != null && ResidentFixtures.toFixtureId(latest.residentId) == fixtureId) {
      _bpController.text = latest.bloodPressure;
      _hrController.text = latest.heartRate.toString();
      _tempController.text = latest.temperature.toString();
      if (latest.weight != null) {
        final w = latest.weight!;
        _weightController.text = w == w.roundToDouble() ? w.toInt().toString() : w.toString();
      } else {
        _weightController.text = '';
      }
      _mobilityLevel = (latest.mobilityLevel != null && _mobilityOptions.contains(latest.mobilityLevel))
          ? latest.mobilityLevel!
          : 'Independent';
      _painLevel = latest.painLevel.toDouble().clamp(0.0, 10.0);
      return;
    }

    switch (fixtureId) {
      case 'res_robert':
        _bpController.text = '130/85';
        _hrController.text = '68';
        _tempController.text = '98.4';
        _weightController.text = '162';
        _mobilityLevel = 'Assisted Walk';
        _painLevel = 1.0;
        break;
      case 'res_dorothy':
        _bpController.text = '118/75';
        _hrController.text = '74';
        _tempController.text = '98.2';
        _weightController.text = '125';
        _mobilityLevel = 'Independent';
        _painLevel = 0.0;
        break;
      case 'res_margaret':
      default:
        _bpController.text = '120/80';
        _hrController.text = '72';
        _tempController.text = '98.6';
        _weightController.text = '138';
        _mobilityLevel = 'Independent';
        _painLevel = 2.0;
        break;
    }
  }

  @override
  void dispose() {
    _bpController.dispose();
    _hrController.dispose();
    _tempController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    _recordedByController.dispose();
    super.dispose();
  }

  Future<void> _submitVitals() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final resident = ref.read(residentProvider);
    final vital = VitalSign(
      id: 'vit_${DateTime.now().millisecondsSinceEpoch}',
      residentId: resident.id,
      timestamp: DateTime.now(),
      bloodPressure: _bpController.text.trim(),
      heartRate: int.tryParse(_hrController.text.trim()) ?? 72,
      temperature: double.tryParse(_tempController.text.trim()) ?? 98.6,
      weight: double.tryParse(_weightController.text.trim()),
      mobilityLevel: _mobilityLevel,
      painLevel: _painLevel.round(),
      recordedBy: _recordedByController.text.trim(),
      clinicalNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    await ref.read(healthVitalsProvider.notifier).recordVitals(vital);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Vital signs recorded (${vital.bloodPressure}, ${vital.heartRate} BPM) by ${vital.recordedBy}'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resident = ref.watch(residentProvider);
    ref.listen<Resident>(residentProvider, (previous, next) {
      final nextId = ResidentFixtures.toFixtureId(next.id);
      if (_populatedForResidentId != nextId) {
        _notesController.clear();
        final latest = ref.read(healthVitalsProvider).latest;
        setState(() {
          _applyVitalsToForm(nextId, latest);
        });
      }
    });

    ref.listen<HealthVitalsState>(healthVitalsProvider, (previous, next) {
      final latest = next.latest;
      if (latest != null && latest.id != _populatedVitalId) {
        setState(() {
          _applyVitalsToForm(resident.id, latest);
        });
      }
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.favorite_outline, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Record Health Vitals',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // BP & Heart Rate Grid
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _bpController,
                    decoration: const InputDecoration(
                      labelText: 'Blood Pressure *',
                      hintText: 'e.g. 120/80',
                      suffixText: 'mmHg',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Required';
                      }
                      if (!RegExp(r'^\d{2,3}/\d{2,3}$').hasMatch(val.trim())) {
                        return 'Use 120/80 format';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _hrController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Heart Rate *',
                      hintText: '72',
                      suffixText: 'BPM',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Required';
                      }
                      final hr = int.tryParse(val.trim());
                      if (hr == null || hr < 30 || hr > 250) {
                        return '30-250 BPM';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Temperature & Weight
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _tempController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Temperature *',
                      hintText: '98.6',
                      suffixText: '°F',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Required';
                      }
                      final t = double.tryParse(val.trim());
                      if (t == null || t < 90.0 || t > 110.0) {
                        return '90-110 °F';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Weight',
                      hintText: '138',
                      suffixText: 'lbs',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Mobility Level & Recorded By
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _mobilityLevel,
                    decoration: const InputDecoration(
                      labelText: 'Mobility Level',
                    ),
                    items: _mobilityOptions.map((opt) {
                      return DropdownMenuItem(
                        value: opt,
                        child: Text(opt, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _mobilityLevel = val);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _recordedByController,
                    decoration: const InputDecoration(
                      labelText: 'Recorded by *',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Pain Level Slider
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pain Level: ${_painLevel.round()} / 10',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        _painLevel == 0
                            ? 'No pain'
                            : _painLevel < 4
                                ? 'Mild'
                                : _painLevel < 7
                                    ? 'Moderate'
                                    : 'Severe',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _painLevel >= 7 ? AppColors.statusRed : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _painLevel,
                    min: 0,
                    max: 10,
                    divisions: 10,
                    activeColor: _painLevel >= 7 ? AppColors.statusRed : AppColors.primary,
                    label: _painLevel.round().toString(),
                    onChanged: (val) => setState(() => _painLevel = val),
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('0 None', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      Text('5 Moderate', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      Text('10 Severe', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Clinical Notes
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Clinical Observations / Notes',
                hintText: 'e.g. Skin color good, resting comfortably...',
              ),
            ),
            const SizedBox(height: 16),

            // Submit Button
            ElevatedButton.icon(
              onPressed: _submitVitals,
              icon: const Icon(Icons.check),
              label: const Text('Record Vital Signs'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
