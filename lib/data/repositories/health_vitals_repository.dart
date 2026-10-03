import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/vital_sign.dart';
import 'http_health_vitals_repository.dart';
import 'mock_health_vitals_repository.dart';

// [MICROSERVICE_INTEGRATION_POINT]: AssessmentService - Assessments & Vitals API
// Contract: GET /api/v1/assessments/patient/{patientId}
// Contract: POST /api/v1/assessments
abstract class HealthVitalsRepository {
  Future<List<VitalSign>> getVitals(String residentId);
  Future<VitalSign> recordVitals(String residentId, VitalSign vitals);
}

final healthVitalsRepositoryProvider = Provider<HealthVitalsRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMockData) {
    return MockHealthVitalsRepository();
  }
  return HttpHealthVitalsRepository(apiClient: ref.watch(apiClientProvider));
});
