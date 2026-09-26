import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/montessori_activity.dart';
import 'mock_montessori_repository.dart';

// [MICROSERVICE_INTEGRATION_POINT]: ActivityService - Montessori Library API
// Endpoints:
// - GET /api/v1/activities/montessori?category={category}&search={search}
// - GET /api/v1/activities/montessori/{id}
// Contract:
// Response format is a JSON array of Montessori activity items containing category, steps, and dignity tips.
abstract class MontessoriRepository {
  Future<List<MontessoriActivity>> getActivities({MontessoriCategory? category, String? query});
  Future<MontessoriActivity?> getActivityById(String id);
}

final montessoriRepositoryProvider = Provider<MontessoriRepository>((ref) {
  return MockMontessoriRepository();
});
