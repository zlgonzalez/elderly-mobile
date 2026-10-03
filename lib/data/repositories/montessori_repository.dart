import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/montessori_activity.dart';
import 'http_montessori_repository.dart';
import 'mock_montessori_repository.dart';

// [MICROSERVICE_INTEGRATION_POINT]: ActivityService & AssessmentService
// Endpoints:
// - GET /api/v1/assessments/templates/stock
abstract class MontessoriRepository {
  Future<List<MontessoriActivity>> getActivities({MontessoriCategory? category, String? query});
  Future<MontessoriActivity?> getActivityById(String id);
}

final montessoriRepositoryProvider = Provider<MontessoriRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMockData) {
    return MockMontessoriRepository();
  }
  return HttpMontessoriRepository(apiClient: ref.watch(apiClientProvider));
});
