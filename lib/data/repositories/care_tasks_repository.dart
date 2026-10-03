import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/care_task.dart';
import 'http_care_tasks_repository.dart';
import 'mock_care_tasks_repository.dart';

// [MICROSERVICE_INTEGRATION_POINT]: ActivityService - Activities & Tasks API
// Contract: GET /api/v1/activities/agenda/today?patient_id={uuid}
// Contract: GET /api/v1/family/feed?patient_id={uuid}
// Contract: PATCH /api/v1/activities/{taskId}/status
abstract class CareTasksRepository {
  Future<List<CareTask>> getTasks(String residentId);
  Future<CareTask> createTask(String residentId, CareTask task);
  Future<CareTask> updateTaskStatus({
    required String residentId,
    required String taskId,
    required TaskStatus status,
    String? completedBy,
    String? note,
  });
}

final careTasksRepositoryProvider = Provider<CareTasksRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMockData) {
    return MockCareTasksRepository();
  }
  return HttpCareTasksRepository(apiClient: ref.watch(apiClientProvider));
});
