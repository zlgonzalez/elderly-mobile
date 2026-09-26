import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/vital_sign.dart';
import 'mock_health_vitals_repository.dart';

// [MICROSERVICE_INTEGRATION_POINT]: HealthService - Vitals API
// Contract: GET /api/v1/residents/{residentId}/vitals
// Contract: POST /api/v1/residents/{residentId}/vitals
abstract class HealthVitalsRepository {
  Future<List<VitalSign>> getVitals(String residentId);
  Future<VitalSign> recordVitals(String residentId, VitalSign vitals);
}

final healthVitalsRepositoryProvider = Provider<HealthVitalsRepository>((ref) {
  // In production, when USE_MOCK_DATA is false, connect to real microservice
  return MockHealthVitalsRepository();
});
