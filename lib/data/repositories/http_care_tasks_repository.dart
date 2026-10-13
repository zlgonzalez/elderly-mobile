import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/care_task.dart';
import '../fixtures/resident_fixtures.dart';
import 'care_tasks_repository.dart';
import 'mock_care_tasks_repository.dart';

class HttpCareTasksRepository implements CareTasksRepository {
  final ApiClient _apiClient;
  final MockCareTasksRepository _fallback = MockCareTasksRepository();

  HttpCareTasksRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<List<CareTask>> getTasks(String residentId) async {
    final fixtureId = ResidentFixtures.toFixtureId(residentId);
    final patientUuid = ResidentFixtures.toBackendUuid(residentId);
    try {
      // 1. First try caregiver agenda today endpoint
      final agendaRes = await _apiClient.get(
        '/activities/agenda/today',
        queryParameters: {'patient_id': patientUuid},
      );

      if (agendaRes is List && agendaRes.isNotEmpty) {
        final tasks = agendaRes
            .map((json) => _mapActivityItemToTask(json as Map<String, dynamic>, fixtureId))
            .toList();
        _fallback.setTasks(fixtureId, tasks);
        return tasks;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HttpCareTasksRepository] /activities/agenda/today failed ($e), trying family feed');
      }
    }

    try {
      // 2. Try family feed endpoint if agenda returned empty or failed (e.g. family role)
      final feedRes = await _apiClient.get(
        '/family/feed',
        queryParameters: {'patient_id': patientUuid},
      );

      if (feedRes is List && feedRes.isNotEmpty) {
        final tasks = feedRes
            .map((json) => _mapActivityItemToTask(json as Map<String, dynamic>, fixtureId))
            .toList();
        _fallback.setTasks(fixtureId, tasks);
        return tasks;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HttpCareTasksRepository] /family/feed failed ($e), using local fallback');
      }
    }

    // 3. Graceful fallback
    return _fallback.getTasks(fixtureId);
  }

  @override
  Future<CareTask> createTask(String residentId, CareTask task) async {
    final fixtureId = ResidentFixtures.toFixtureId(residentId);
    final patientUuid = ResidentFixtures.toBackendUuid(residentId);
    try {
      final area = task.category == TaskCategory.physical
          ? 'Physical'
          : task.category == TaskCategory.social
              ? 'Social'
              : task.category == TaskCategory.purposeful
                  ? 'Cognitive'
                  : 'Functional';
      final res = await _apiClient.post(
        '/activities/items',
        body: {
          'patient_id': patientUuid,
          'title': task.title,
          'description': task.description,
          'montessori_area': area,
          'goal': task.completionNote ?? task.description,
        },
      );
      if (res is Map<String, dynamic>) {
        final created = _mapActivityItemToTask(res, fixtureId).copyWith(
          time: task.time,
          category: task.category,
        );
        await _fallback.createTask(fixtureId, created);
        return created;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HttpCareTasksRepository] createTask failed ($e), using local fallback');
      }
    }
    return _fallback.createTask(fixtureId, task);
  }

  @override
  Future<CareTask> updateTaskStatus({
    required String residentId,
    required String taskId,
    required TaskStatus status,
    String? completedBy,
    String? note,
  }) async {
    final fixtureId = ResidentFixtures.toFixtureId(residentId);
    // If taskId is a UUID, attempt updating backend activity item status
    final isUuid = taskId.contains('-');
    if (isUuid) {
      try {
        final statusStr = status == TaskStatus.completed
            ? 'completed'
            : status == TaskStatus.skipped
                ? 'missed'
                : 'pending';

        final res = await _apiClient.patch(
          '/activities/$taskId/status',
          body: {'status': statusStr},
        );
        if (res is Map<String, dynamic>) {
          final mapped = _mapActivityItemToTask(res, fixtureId).copyWith(
            status: status,
            completedBy: completedBy,
            completionNote: note,
          );
          await _fallback.updateTaskStatus(
            residentId: fixtureId,
            taskId: taskId,
            status: status,
            completedBy: completedBy,
            note: note,
          );
          return mapped;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[HttpCareTasksRepository] updateStatus on backend failed: $e');
        }
      }
    }

    return _fallback.updateTaskStatus(
      residentId: fixtureId,
      taskId: taskId,
      status: status,
      completedBy: completedBy,
      note: note,
    );
  }

  CareTask _mapActivityItemToTask(Map<String, dynamic> json, String residentId) {
    final id = json['id']?.toString() ?? 'task_${DateTime.now().millisecondsSinceEpoch}';
    final title = json['title']?.toString() ?? 'Care Task';
    final description = json['description']?.toString() ?? json['goal']?.toString() ?? '';
    final statusStr = (json['status']?.toString() ?? 'pending').toLowerCase();

    TaskStatus status;
    if (statusStr == 'completed') {
      status = TaskStatus.completed;
    } else if (statusStr == 'missed' || statusStr == 'skipped') {
      status = TaskStatus.skipped;
    } else {
      status = TaskStatus.pending;
    }

    final area = (json['montessori_area']?.toString() ?? '').toLowerCase();
    TaskCategory category;
    if (area.contains('physical')) {
      category = TaskCategory.physical;
    } else if (area.contains('social')) {
      category = TaskCategory.social;
    } else if (area.contains('functional')) {
      category = TaskCategory.activity;
    } else if (area.contains('cognitive')) {
      category = TaskCategory.purposeful;
    } else {
      category = TaskCategory.activity;
    }

    String timeStr = '10:00 AM';
    if (json['scheduled_time'] != null) {
      final dt = DateTime.tryParse(json['scheduled_time'].toString());
      if (dt != null) {
        final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
        final minute = dt.minute.toString().padLeft(2, '0');
        final ampm = dt.hour >= 12 ? 'PM' : 'AM';
        timeStr = '$hour:$minute $ampm';
      }
    }

    return CareTask(
      id: id,
      residentId: residentId,
      title: title,
      description: description,
      time: timeStr,
      category: category,
      status: status,
      completedBy: json['completed_by']?.toString(),
      completionNote: json['goal']?.toString(),
    );
  }
}
