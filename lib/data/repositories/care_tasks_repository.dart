import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/care_task.dart';
import '../../domain/entities/regimen_plan.dart';
import '../../domain/entities/resident.dart';
import 'http_care_tasks_repository.dart';
import 'mock_care_tasks_repository.dart';

// [MICROSERVICE_INTEGRATION_POINT]: ActivityService - Activities & Tasks API
// Contract: GET /api/v1/activities/agenda/today?patient_id={uuid}
// Contract: GET /api/v1/family/feed?patient_id={uuid}
// Contract: POST /api/v1/activities/plan/generate
// Contract: POST /api/v1/activities/plan/{planId}/refine
// Contract: POST /api/v1/activities/plan/{planId}/apply
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
    String? skipReason,
  });
  Future<RegimenPlan> generateWeeklyRegimen({
    required Resident resident,
    DateTime? weekStartDate,
    String? refinementInstruction,
    bool autoApply = false,
    bool forceBaseline = false,
  });
  Future<RegimenPlan> refineRegimen({
    required String residentId,
    required String planId,
    required String instruction,
    DateTime? weekStartDate,
  });
  Future<RegimenPlan> applyRegimen({
    required String residentId,
    required String planId,
    DateTime? weekStartDate,
    bool acknowledgeLowScore = false,
  });
}

final careTasksRepositoryProvider = Provider<CareTasksRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMockData) {
    return MockCareTasksRepository();
  }
  return HttpCareTasksRepository(apiClient: ref.watch(apiClientProvider));
});
