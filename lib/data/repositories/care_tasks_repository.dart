import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/care_task.dart';
import 'mock_care_tasks_repository.dart';

// [MICROSERVICE_INTEGRATION_POINT]: CareService - Tasks API
// Contract: GET /api/v1/residents/{residentId}/tasks
// Contract: POST /api/v1/residents/{residentId}/tasks
// Contract: PATCH /api/v1/residents/{residentId}/tasks/{taskId}/status
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
  // In production, when USE_MOCK_DATA is false, connect to real microservice
  return MockCareTasksRepository();
});
