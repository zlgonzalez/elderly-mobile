import 'package:flutter/foundation.dart';
import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/care_task.dart';
import '../../domain/entities/regimen_plan.dart';
import '../../domain/entities/resident.dart';
import '../fixtures/resident_fixtures.dart';
import 'care_tasks_repository.dart';
import 'mock_care_tasks_repository.dart';

class QueuedStatusRetry {
  final String residentId;
  final String taskId;
  final TaskStatus status;
  final String? note;
  final String? skipReason;

  const QueuedStatusRetry({
    required this.residentId,
    required this.taskId,
    required this.status,
    this.note,
    this.skipReason,
  });
}

class HttpCareTasksRepository implements CareTasksRepository {
  final ApiClient _apiClient;
  final MockCareTasksRepository _fallback = MockCareTasksRepository();
  final List<QueuedStatusRetry> _retryQueue = [];
  final Map<String, Future<CareTask>> _inFlightStatusUpdates = {};
  Future<void>? _flushInFlight;

  HttpCareTasksRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  List<QueuedStatusRetry> get pendingRetryQueue =>
      List.unmodifiable(_retryQueue);

  bool _isAuthError(Object error) =>
      error is ApiException &&
      (error.statusCode == 401 || error.statusCode == 403);

  void resetLocalCache({String? residentId}) {
    if (residentId != null) {
      final fixtureId = ResidentFixtures.toFixtureId(residentId);
      _retryQueue.removeWhere((q) => q.residentId == fixtureId);
      _fallback.resetToDemo(fixtureId);
      return;
    }
    _retryQueue.clear();
    _fallback.resetToDemo('res_margaret');
    _fallback.resetToDemo('res_robert');
    _fallback.resetToDemo('res_dorothy');
  }

  bool _isPermanentClientError(Object error) {
    if (error is ApiException) {
      return error.statusCode >= 400 &&
          error.statusCode < 500 &&
          error.statusCode != 408 &&
          error.statusCode != 429;
    }
    return false;
  }

  void _enqueueRetry(QueuedStatusRetry entry) {
    _retryQueue.removeWhere(
      (q) => q.residentId == entry.residentId && q.taskId == entry.taskId,
    );
    _retryQueue.add(entry);
  }

  Future<void> flushPendingStatusRetries() {
    if (_flushInFlight != null) {
      return _flushInFlight!;
    }
    if (_retryQueue.isEmpty) {
      return Future.value();
    }
    final future = _doFlushRetries();
    _flushInFlight = future;
    return future.whenComplete(() {
      if (identical(_flushInFlight, future)) {
        _flushInFlight = null;
      }
    });
  }

  Future<void> _doFlushRetries() async {
    while (_retryQueue.isNotEmpty) {
      final pending = List<QueuedStatusRetry>.from(_retryQueue);
      _retryQueue.clear();
      var failedCount = 0;
      for (final entry in pending) {
        try {
          await _sendPatchStatus(entry);
        } catch (e) {
          if (_isPermanentClientError(e)) {
            if (kDebugMode) {
              debugPrint(
                  '[HttpCareTasksRepository] dropping permanent 4xx status retry for ${entry.taskId}: $e');
            }
            continue;
          }
          // Preserve newer status queued while this flush was in flight.
          final hasNewer = _retryQueue.any(
            (q) => q.residentId == entry.residentId && q.taskId == entry.taskId,
          );
          if (!hasNewer) {
            _retryQueue.add(entry);
          }
          failedCount++;
        }
      }
      if (failedCount > 0) {
        break;
      }
    }
  }

  @override
  Future<List<CareTask>> getTasks(String residentId) async {
    await flushPendingStatusRetries();
    final fixtureId = ResidentFixtures.toFixtureId(residentId);
    final patientUuid = ResidentFixtures.toBackendUuid(residentId);
    try {
      final agendaRes = await _apiClient.get(
        '/activities/agenda/today',
        queryParameters: {'patient_id': patientUuid},
      );

      if (agendaRes is List && agendaRes.isNotEmpty) {
        final tasks = agendaRes
            .map((json) =>
                _mapActivityItemToTask(json as Map<String, dynamic>, fixtureId))
            .toList();
        _fallback.setTasks(fixtureId, tasks);
        return tasks;
      }
    } catch (e) {
      if (_isAuthError(e)) rethrow;
      if (kDebugMode) {
        debugPrint(
            '[HttpCareTasksRepository] /activities/agenda/today failed ($e), trying family feed');
      }
    }

    try {
      final feedRes = await _apiClient.get(
        '/family/feed',
        queryParameters: {'patient_id': patientUuid},
      );

      if (feedRes is List && feedRes.isNotEmpty) {
        final tasks = feedRes
            .map((json) =>
                _mapActivityItemToTask(json as Map<String, dynamic>, fixtureId))
            .toList();
        _fallback.setTasks(fixtureId, tasks);
        return tasks;
      }
    } catch (e) {
      if (_isAuthError(e)) rethrow;
      if (kDebugMode) {
        debugPrint(
            '[HttpCareTasksRepository] /family/feed failed ($e), using local fallback');
      }
    }

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
                  ? 'Functional'
                  : 'Cognitive';
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
          generationSource: 'manual',
        );
        await _fallback.createTask(fixtureId, created);
        return created;
      }
    } catch (e) {
      if (_isAuthError(e)) rethrow;
      if (kDebugMode) {
        debugPrint(
            '[HttpCareTasksRepository] createTask failed ($e), using local fallback');
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
    String? skipReason,
  }) async {
    final fixtureId = ResidentFixtures.toFixtureId(residentId);
    final lockKey = '$fixtureId:$taskId';
    final previous = _inFlightStatusUpdates[lockKey];

    Future<CareTask> runUpdate() async {
      if (previous != null) {
        try {
          await previous;
        } catch (_) {}
      }
      final isUuid = taskId.contains('-');
      if (isUuid) {
        final req = QueuedStatusRetry(
          residentId: fixtureId,
          taskId: taskId,
          status: status,
          note: note,
          skipReason: skipReason,
        );
        try {
          await flushPendingStatusRetries();
          final res = await _sendPatchStatus(req);
          _retryQueue.removeWhere(
            (q) => q.residentId == fixtureId && q.taskId == taskId,
          );
          if (res is Map<String, dynamic>) {
            final mapped = _mapActivityItemToTask(res, fixtureId).copyWith(
              status: status,
              completedBy: completedBy,
              completionNote: note,
              skipReason: skipReason,
            );
            await _fallback.updateTaskStatus(
              residentId: fixtureId,
              taskId: taskId,
              status: status,
              completedBy: completedBy,
              note: note,
              skipReason: skipReason,
            );
            return mapped;
          }
        } on ApiException catch (e) {
          if (_isPermanentClientError(e)) {
            throw RegimenGateException(e.statusCode, e.message);
          }
          _enqueueRetry(req);
          if (kDebugMode) {
            debugPrint(
                '[HttpCareTasksRepository] updateStatus queued for retry: $e');
          }
        } catch (e) {
          _enqueueRetry(req);
          if (kDebugMode) {
            debugPrint(
                '[HttpCareTasksRepository] updateStatus queued for retry: $e');
          }
        }
      }

      return _fallback.updateTaskStatus(
        residentId: fixtureId,
        taskId: taskId,
        status: status,
        completedBy: completedBy,
        note: note,
        skipReason: skipReason,
      );
    }

    final future = runUpdate();
    _inFlightStatusUpdates[lockKey] = future;
    try {
      return await future;
    } finally {
      if (identical(_inFlightStatusUpdates[lockKey], future)) {
        _inFlightStatusUpdates.remove(lockKey);
      }
    }
  }

  Future<dynamic> _sendPatchStatus(QueuedStatusRetry entry) async {
    final statusStr = entry.status == TaskStatus.completed
        ? 'completed'
        : entry.status == TaskStatus.skipped
            ? 'skipped'
            : 'pending';
    return _apiClient.patch(
      '/activities/${entry.taskId}/status',
      body: {
        'status': statusStr,
        if (entry.note != null && entry.note!.isNotEmpty)
          'completion_note': entry.note,
        if (entry.skipReason != null && entry.skipReason!.isNotEmpty)
          'skip_reason': entry.skipReason,
      },
    );
  }

  @override
  Future<RegimenPlan> generateWeeklyRegimen({
    required Resident resident,
    DateTime? weekStartDate,
    String? refinementInstruction,
    bool autoApply = false,
    bool forceBaseline = false,
  }) async {
    final fixtureId = ResidentFixtures.toFixtureId(resident.id);
    final patientUuid = ResidentFixtures.toBackendUuid(resident.id);
    final start = (weekStartDate ?? DateTime.now().toUtc())
        .toIso8601String()
        .substring(0, 10);

    try {
      final res = await _apiClient.post(
        '/activities/plan/generate',
        timeout: AppConfig.regimenRequestTimeout,
        body: {
          'patient_id': patientUuid,
          'week_start_date': start,
          if (resident.cognitiveCapability != null)
            'cognitive_capability': resident.cognitiveCapability,
          if (resident.physicalCapability != null)
            'physical_capability': resident.physicalCapability,
          if (resident.cognitiveStage != null)
            'cognitive_stage': resident.cognitiveStage,
          if (resident.motorLimitations.isNotEmpty)
            'motor_limitations': resident.motorLimitations,
          if (refinementInstruction != null && refinementInstruction.isNotEmpty)
            'refinement_instruction': refinementInstruction,
          'auto_apply': autoApply,
          'force_baseline': forceBaseline,
        },
      );
      if (res is Map<String, dynamic>) {
        return _mapPlanResponse(res, fixtureId);
      }
      throw const RegimenGateException(
        502,
        'Unexpected response generating regimen.',
      );
    } on ApiException catch (e) {
      throw RegimenGateException(e.statusCode, e.message);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HttpCareTasksRepository] generateWeeklyRegimen error: $e');
      }
      throw const RegimenGateException(
        503,
        'Unable to reach care service to generate regimen. Please try again.',
      );
    }
  }

  @override
  Future<RegimenPlan> refineRegimen({
    required String residentId,
    required String planId,
    required String instruction,
    DateTime? weekStartDate,
  }) async {
    final fixtureId = ResidentFixtures.toFixtureId(residentId);
    if (!planId.contains('-')) {
      return _fallback.refineRegimen(
        residentId: fixtureId,
        planId: planId,
        instruction: instruction,
        weekStartDate: weekStartDate,
      );
    }
    try {
      final res = await _apiClient.post(
        '/activities/plan/$planId/refine',
        timeout: AppConfig.regimenRequestTimeout,
        body: {
          'refinement_instruction': instruction,
          if (weekStartDate != null)
            'week_start_date':
                weekStartDate.toIso8601String().substring(0, 10),
        },
      );
      if (res is Map<String, dynamic>) {
        return _mapPlanResponse(res, fixtureId);
      }
      throw const RegimenGateException(502, 'Unexpected response refining regimen.');
    } on ApiException catch (e) {
      throw RegimenGateException(e.statusCode, e.message);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HttpCareTasksRepository] refineRegimen error: $e');
      }
      throw const RegimenGateException(
        503,
        'Unable to reach care service to refine regimen. Please try again.',
      );
    }
  }

  @override
  Future<RegimenPlan> applyRegimen({
    required String residentId,
    required String planId,
    DateTime? weekStartDate,
    bool acknowledgeLowScore = false,
  }) async {
    final fixtureId = ResidentFixtures.toFixtureId(residentId);
    if (!planId.contains('-')) {
      return _fallback.applyRegimen(
        residentId: fixtureId,
        planId: planId,
        weekStartDate: weekStartDate,
        acknowledgeLowScore: acknowledgeLowScore,
      );
    }
    try {
      final res = await _apiClient.post(
        '/activities/plan/$planId/apply',
        body: {
          if (weekStartDate != null)
            'week_start_date':
                weekStartDate.toIso8601String().substring(0, 10),
          'acknowledge_low_score': acknowledgeLowScore,
        },
      );
      if (res is Map<String, dynamic>) {
        return _mapPlanResponse(res, fixtureId);
      }
      throw const RegimenGateException(502, 'Unexpected response applying regimen.');
    } on ApiException catch (e) {
      throw RegimenGateException(e.statusCode, e.message);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HttpCareTasksRepository] applyRegimen error: $e');
      }
      throw const RegimenGateException(
        503,
        'Unable to reach care service to apply regimen. Please try again.',
      );
    }
  }

  RegimenPlan _mapPlanResponse(Map<String, dynamic> json, String fixtureId) {
    final rawItems = (json['items'] as List<dynamic>?) ?? const [];
    final mappedItems = rawItems
        .map((it) => _mapActivityItemToTask(it as Map<String, dynamic>, fixtureId))
        .toList();
    return RegimenPlan.fromJson(
      json,
      residentId: fixtureId,
      mappedItems: mappedItems,
    );
  }

  CareTask _mapActivityItemToTask(
      Map<String, dynamic> json, String residentId) {
    final id = json['id']?.toString() ??
        'task_${DateTime.now().millisecondsSinceEpoch}';
    final title = json['title']?.toString() ?? 'Care Task';
    final description =
        json['description']?.toString() ?? json['goal']?.toString() ?? '';
    final statusStr = (json['status']?.toString() ?? 'pending').toLowerCase();

    TaskStatus status;
    if (statusStr == 'completed') {
      status = TaskStatus.completed;
    } else if (statusStr == 'missed' || statusStr == 'skipped') {
      status = TaskStatus.skipped;
    } else {
      status = TaskStatus.pending;
    }

    final domainOrArea = json['montessori_domain']?.toString().isNotEmpty == true
        ? json['montessori_domain']?.toString()
        : json['montessori_area']?.toString();
    final category = MontessoriTaxonomyMapper.toTaskCategory(domainOrArea);

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

    final dayOffset = (json['day_offset'] as num?)?.toInt();

    return CareTask(
      id: id,
      residentId: residentId,
      planId: json['plan_id']?.toString(),
      dayNumber: dayOffset != null ? dayOffset + 1 : null,
      title: title,
      description: description,
      time: timeStr,
      category: category,
      status: status,
      completedBy: json['completed_by']?.toString(),
      completionNote: json['completion_note']?.toString(),
      skipReason: json['skip_reason']?.toString(),
      materials: (json['materials'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      materialsTraySetup: json['materials_tray_setup']?.toString(),
      steps: (json['steps'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      scriptPrompt: json['script_prompt']?.toString(),
      dignityTip: json['dignity_tip']?.toString(),
      historicalConnection: json['historical_connection']?.toString(),
      safetyComfort: json['safety_comfort']?.toString(),
      montessoriDomain: domainOrArea,
      generationSource: json['generation_source']?.toString(),
    );
  }
}
