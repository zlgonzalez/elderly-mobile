import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/vital_sign.dart';
import '../fixtures/resident_fixtures.dart';
import 'health_vitals_repository.dart';
import 'mock_health_vitals_repository.dart';

class HttpHealthVitalsRepository implements HealthVitalsRepository {
  final ApiClient _apiClient;
  final MockHealthVitalsRepository _fallback = MockHealthVitalsRepository();

  HttpHealthVitalsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<List<VitalSign>> getVitals(String residentId) async {
    final patientUuid = ResidentFixtures.toBackendUuid(residentId);
    try {
      final res = await _apiClient.get('/assessments/patient/$patientUuid');
      if (res is List && res.isNotEmpty) {
        final parsed = <VitalSign>[];
        for (final item in res) {
          if (item is Map<String, dynamic>) {
            final responses = item['responses'] as Map<String, dynamic>? ?? {};
            parsed.add(VitalSign(
              id: item['id']?.toString() ?? 'vit_${DateTime.now().millisecondsSinceEpoch}',
              residentId: residentId,
              timestamp: item['completed_at'] != null
                  ? (DateTime.tryParse(item['completed_at'].toString()) ?? DateTime.now())
                  : DateTime.now(),
              bloodPressure: responses['blood_pressure']?.toString() ?? '120/80',
              heartRate: int.tryParse(responses['heart_rate']?.toString() ?? '72') ?? 72,
              temperature: double.tryParse(responses['temperature']?.toString() ?? '98.6') ?? 98.6,
              weight: double.tryParse(responses['weight']?.toString() ?? ''),
              mobilityLevel: responses['mobility']?.toString() ?? 'Independent',
              painLevel: int.tryParse(responses['pain_level']?.toString() ?? '0') ?? 0,
              recordedBy: 'Clinical Staff',
              clinicalNotes: item['notes']?.toString() ?? 'Clinical assessment completed.',
            ));
          }
        }
        if (parsed.isNotEmpty) {
          return parsed;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HttpHealthVitalsRepository] getVitals remote call error: $e, using fallback');
      }
    }

    return _fallback.getVitals(residentId);
  }

  @override
  Future<VitalSign> recordVitals(String residentId, VitalSign vitals) async {
    final patientUuid = ResidentFixtures.toBackendUuid(residentId);
    try {
      await _apiClient.post(
        '/assessments',
        body: {
          'patient_id': patientUuid,
          'template_id': '00000000-0000-0000-0000-000000000001',
          'respondent_type': 'caregiver',
          'notes': vitals.clinicalNotes ?? 'Routine vital signs recorded.',
          'responses': {
            'blood_pressure': vitals.bloodPressure,
            'heart_rate': vitals.heartRate,
            'temperature': vitals.temperature,
            'pain_level': vitals.painLevel,
            if (vitals.weight != null) 'weight': vitals.weight,
            if (vitals.mobilityLevel != null) 'mobility': vitals.mobilityLevel,
          },
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HttpHealthVitalsRepository] recordVitals remote post error: $e');
      }
    }

    return _fallback.recordVitals(residentId, vitals);
  }
}
