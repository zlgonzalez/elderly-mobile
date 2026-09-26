import '../../domain/entities/vital_sign.dart';
import 'health_vitals_repository.dart';

// [MICROSERVICE_INTEGRATION_POINT]: HealthService - Mock Implementation
// Simulates /api/v1/residents/{residentId}/vitals endpoints
class MockHealthVitalsRepository implements HealthVitalsRepository {
  final Map<String, List<VitalSign>> _store = {};

  MockHealthVitalsRepository() {
    _initDefaultVitals();
  }

  void _initDefaultVitals() {
    _store['res_margaret'] = [
      VitalSign(
        id: 'vit_1',
        residentId: 'res_margaret',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        bloodPressure: '120/80',
        heartRate: 72,
        temperature: 98.6,
        weight: 138.0,
        mobilityLevel: 'Independent',
        painLevel: 2,
        recordedBy: 'Nurse Jane',
        clinicalNotes: 'Vitals stable. Alert and responsive after morning tea.',
      ),
      VitalSign(
        id: 'vit_2',
        residentId: 'res_margaret',
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
        bloodPressure: '122/82',
        heartRate: 75,
        temperature: 98.4,
        weight: 138.5,
        mobilityLevel: 'Independent',
        painLevel: 1,
        recordedBy: 'Nurse Jane',
        clinicalNotes: 'Mild joint stiffness noted in left wrist.',
      ),
    ];

    _store['res_robert'] = [
      VitalSign(
        id: 'vit_rob_1',
        residentId: 'res_robert',
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        bloodPressure: '130/85',
        heartRate: 68,
        temperature: 98.4,
        weight: 162.0,
        mobilityLevel: 'Assisted Walk',
        painLevel: 1,
        recordedBy: 'Visiting Nurse',
        clinicalNotes: 'Good mobility during assisted walk.',
      ),
    ];

    _store['res_dorothy'] = [
      VitalSign(
        id: 'vit_dor_1',
        residentId: 'res_dorothy',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        bloodPressure: '118/75',
        heartRate: 74,
        temperature: 98.2,
        weight: 125.0,
        mobilityLevel: 'Independent',
        painLevel: 0,
        recordedBy: 'Nurse Jane',
        clinicalNotes: 'Normal resting vitals.',
      ),
    ];
  }

  void resetToDemo(String residentId) {
    _initDefaultVitals();
  }

  @override
  Future<List<VitalSign>> getVitals(String residentId) async {
    return List.from(_store[residentId] ?? []);
  }

  @override
  Future<VitalSign> recordVitals(String residentId, VitalSign vitals) async {
    final list = _store.putIfAbsent(residentId, () => []);
    final newVital = vitals.copyWith(
      id: vitals.id.isEmpty ? 'vit_${DateTime.now().millisecondsSinceEpoch}' : vitals.id,
      residentId: residentId,
    );
    list.insert(0, newVital);
    return newVital;
  }
}
