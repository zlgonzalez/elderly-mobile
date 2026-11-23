import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:elderly_mobile/core/network/api_client.dart';
import 'package:elderly_mobile/data/fixtures/resident_fixtures.dart';
import 'package:elderly_mobile/data/repositories/care_tasks_repository.dart';
import 'package:elderly_mobile/data/repositories/http_care_tasks_repository.dart';
import 'package:elderly_mobile/data/repositories/mock_care_tasks_repository.dart';
import 'package:elderly_mobile/domain/entities/care_task.dart';
import 'package:elderly_mobile/domain/entities/montessori_activity.dart';
import 'package:elderly_mobile/domain/entities/regimen_plan.dart';
import 'package:elderly_mobile/domain/entities/resident.dart';
import 'package:elderly_mobile/domain/entities/user_profile.dart';
import 'package:elderly_mobile/presentation/care_tasks/care_tasks_provider.dart';
import 'package:elderly_mobile/presentation/care_tasks/regimen_batch_provider.dart';

void main() {
  group('MockCareTasksRepository Tests', () {
    late MockCareTasksRepository repository;

    setUp(() {
      repository = MockCareTasksRepository();
    });

    test('getTasks returns initial tasks for Margaret', () async {
      final tasks = await repository.getTasks('res_margaret');
      expect(tasks.length, 3);

      final morningWalk = tasks.firstWhere((t) => t.title == 'Morning Garden Walk');
      expect(morningWalk.status, TaskStatus.completed);
      expect(morningWalk.completedBy, 'Nurse Jane');
      expect(morningWalk.category, TaskCategory.physical);

      final foldingLaundry = tasks.firstWhere((t) => t.title == 'Folding Laundry');
      expect(foldingLaundry.status, TaskStatus.pending);
      expect(foldingLaundry.category, TaskCategory.purposeful);
    });

    test('updateTaskStatus marks task completed with attribution and notes', () async {
      final updated = await repository.updateTaskStatus(
        residentId: 'res_margaret',
        taskId: 'task_2',
        status: TaskStatus.completed,
        completedBy: 'Sarah Thompson',
        note: 'Folded 8 towels together happily',
      );

      expect(updated.status, TaskStatus.completed);
      expect(updated.completedBy, 'Sarah Thompson');
      expect(updated.completionNote, 'Folded 8 towels together happily');

      final tasks = await repository.getTasks('res_margaret');
      final saved = tasks.firstWhere((t) => t.id == 'task_2');
      expect(saved.status, TaskStatus.completed);
      expect(saved.completedBy, 'Sarah Thompson');
    });

    test('createTask adds new activity to the schedule', () async {
      const newTask = CareTask(
        id: 'task_new',
        residentId: 'res_margaret',
        title: 'Afternoon Tea & Poetry',
        description: 'Reading Emily Dickinson poems while enjoying herbal tea.',
        time: '03:30 PM',
        category: TaskCategory.activity,
      );

      final created = await repository.createTask('res_margaret', newTask);
      expect(created.title, 'Afternoon Tea & Poetry');

      final tasks = await repository.getTasks('res_margaret');
      expect(tasks.length, 4);
      expect(tasks.any((t) => t.title == 'Afternoon Tea & Poetry'), isTrue);
    });

    test('MontessoriTaxonomyMapper maps all 5 Montessori areas cleanly', () {
      expect(
        MontessoriTaxonomyMapper.toMontessoriCategory('Practical Life'),
        MontessoriCategory.practicalLife,
      );
      expect(
        MontessoriTaxonomyMapper.toMontessoriCategory('Sensorial'),
        MontessoriCategory.sensory,
      );
      expect(
        MontessoriTaxonomyMapper.toMontessoriCategory('Language'),
        MontessoriCategory.cognitive,
      );
      expect(
        MontessoriTaxonomyMapper.toMontessoriCategory('Math'),
        MontessoriCategory.cognitive,
      );
      expect(
        MontessoriTaxonomyMapper.toMontessoriCategory('Cultural'),
        MontessoriCategory.social,
      );
    });

    test('generateWeeklyRegimen, refineRegimen, and applyRegimen preserve completed & manual items', () async {
      await repository.createTask(
        'res_margaret',
        const CareTask(
          id: 'manual_1',
          residentId: 'res_margaret',
          title: 'Manual Family Call',
          description: 'Scheduled call with daughter',
          time: '05:00 PM',
          category: TaskCategory.social,
        ),
      );

      final preview = await repository.generateWeeklyRegimen(
        resident: ResidentFixtures.margaretThompson,
        autoApply: false,
      );
      expect(preview.planStatus, 'preview');
      expect(preview.items.length, 21);
      expect(preview.scorecard?.compositeScore, 88);
      final daySignatures = <String>{};
      for (int day = 1; day <= 7; day++) {
        final dayItems = preview.items.where((t) => t.dayNumber == day).toList();
        expect(dayItems.length, 3);
        daySignatures.add(dayItems.map((t) => t.title).join('|'));
      }
      expect(daySignatures.length, 7);

      final refined = await repository.refineRegimen(
        residentId: 'res_margaret',
        planId: preview.id,
        instruction: 'Adjust for mild tremors',
      );
      expect(refined.refinementInstruction, 'Adjust for mild tremors');

      final applied = await repository.applyRegimen(
        residentId: 'res_margaret',
        planId: refined.id,
      );
      expect(applied.planStatus, 'applied');

      final updatedTasks = await repository.getTasks('res_margaret');
      // Preserves completed Morning Garden Walk & Manual Family Call, replaces pending Folding Laundry
      expect(updatedTasks.any((t) => t.title == 'Morning Garden Walk'), isTrue);
      expect(updatedTasks.any((t) => t.title == 'Manual Family Call'), isTrue);
      expect(updatedTasks.any((t) => t.title == 'Folding Laundry'), isFalse);
      expect(updatedTasks.any((t) => t.materials.isNotEmpty), isTrue);
    });

    test('updateTaskStatus records skipReason', () async {
      final skipped = await repository.updateTaskStatus(
        residentId: 'res_margaret',
        taskId: 'task_2',
        status: TaskStatus.skipped,
        skipReason: 'Resident felt tired',
      );
      expect(skipped.status, TaskStatus.skipped);
      expect(skipped.skipReason, 'Resident felt tired');
    });

    test('RegimenPlan.hasCriticalSafetyBlock detects ESCALAT flags and UserProfile parses admin', () {
      final plan = RegimenPlan(
        id: 'plan-1',
        residentId: 'res_margaret',
        weekStartDate: DateTime.utc(2026, 11, 11),
        generationSource: RegimenGenerationSource.kuboAgent,
        safetyFlags: const ['Requires clinical escalation before activity'],
        generatedAt: DateTime.utc(2026, 11, 11),
      );
      expect(plan.hasCriticalSafetyBlock, isTrue);

      final admin = UserProfile.fromJson({
        'id': 'u1',
        'username': 'director',
        'fullName': 'Clinic Director',
        'role': 'admin',
      });
      expect(admin.role, UserRole.admin);
    });

    test('HttpCareTasksRepository deduplicates retry queue, drops permanent 4xx, and avoids mock fallback for UUID plan ops', () async {
      var patchStatusCode = 503;
      final patchPayloads = <String>[];
      final mockClient = MockClient((request) async {
        if (request.method == 'PATCH' && request.url.path.contains('/status')) {
          patchPayloads.add(request.body);
          if (patchStatusCode >= 400) {
            return http.Response(
              jsonEncode({'error': 'err'}),
              patchStatusCode,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response(
            jsonEncode({'id': '00000000-0000-0000-0000-000000000099', 'title': 'Task', 'status': 'completed'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({'error': 'forbidden'}),
          403,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = HttpCareTasksRepository(
        apiClient: ApiClient(
          baseUrl: 'http://localhost:8080/api/v1',
          httpClient: mockClient,
        ),
      );

      // Two offline/503 updates for same task deduplicate to latest status.
      await repo.updateTaskStatus(
        residentId: 'res_margaret',
        taskId: '00000000-0000-0000-0000-000000000099',
        status: TaskStatus.skipped,
        skipReason: 'First reason',
      );
      await repo.updateTaskStatus(
        residentId: 'res_margaret',
        taskId: '00000000-0000-0000-0000-000000000099',
        status: TaskStatus.completed,
        note: 'Completed later',
      );
      expect(repo.pendingRetryQueue.length, 1);
      expect(repo.pendingRetryQueue.single.status, TaskStatus.completed);

      // Permanent 4xx during flush drops queued item instead of looping forever.
      patchStatusCode = 403;
      await repo.flushPendingStatusRetries();
      expect(repo.pendingRetryQueue, isEmpty);

      // generateWeeklyRegimen, refineRegimen, and applyRegimen throw RegimenGateException on backend failure instead of falling back to un-applyable mock.
      expect(
        () => repo.generateWeeklyRegimen(
          resident: ResidentFixtures.margaretThompson,
        ),
        throwsA(isA<RegimenGateException>()),
      );
      expect(
        () => repo.refineRegimen(
          residentId: 'res_margaret',
          planId: '11111111-1111-1111-1111-111111111111',
          instruction: 'Make gentler',
        ),
        throwsA(isA<RegimenGateException>()),
      );
      expect(
        () => repo.applyRegimen(
          residentId: 'res_margaret',
          planId: '11111111-1111-1111-1111-111111111111',
        ),
        throwsA(isA<RegimenGateException>()),
      );
    });

    test('CareTasksNotifier.cancelAndSwitchToBaseline resolves active generateRegimen waiter with baseline preview', () async {
      final repo = _SlowGenerateMockRepo();
      final notifier = CareTasksNotifier(
        repository: repo,
        residentId: 'res_margaret',
      );
      addTearDown(notifier.dispose);

      final pendingFuture = notifier.generateRegimen(
        resident: ResidentFixtures.margaretThompson,
        autoApply: false,
      );
      await Future.delayed(const Duration(milliseconds: 20));
      final baselinePlan = await notifier.cancelAndSwitchToBaseline(
        ResidentFixtures.margaretThompson,
      );
      final awaitedOriginal = await pendingFuture;

      expect(baselinePlan, isNotNull);
      expect(awaitedOriginal?.id, baselinePlan?.id);
      expect(notifier.state.activePreviewPlan?.id, baselinePlan?.id);
      expect(notifier.state.isGenerating, isFalse);
    });
  });

  group('Batch Regimen Generation Unit Tests (T012 / T013 / T022)', () {
    test('HttpCareTasksRepository enqueues 202 batch job, throws 409 conflict, polls, cancels, dismisses, and applies baseline', () async {
      final dorothyUuid = ResidentFixtures.toBackendUuid(ResidentFixtures.dorothyWilliams.id);
      final mockClient = MockClient((request) async {
        if (request.method == 'POST' && request.url.path == '/activities/plan/jobs') {
          if (request.body.contains(dorothyUuid)) {
            return http.Response(
              jsonEncode({
                'error': 'active job already exists',
                'active_job': {
                  'id': 'job_existing',
                  'patient_id': dorothyUuid,
                  'job_type': 'generation',
                  'status': 'in_progress',
                  'phase': 'synthesis',
                  'created_at': '2026-11-15T10:00:00Z',
                  'updated_at': '2026-11-15T10:00:00Z',
                },
              }),
              409,
            );
          }
          return http.Response(
            jsonEncode({
              'id': 'job_123',
              'patient_id': ResidentFixtures.toBackendUuid('res_margaret'),
              'requested_by': 'cg_1',
              'job_type': 'generation',
              'status': 'queued',
              'phase': 'retrieval',
              'created_at': '2026-11-15T10:00:00Z',
              'updated_at': '2026-11-15T10:00:00Z',
            }),
            202,
          );
        }
        if (request.method == 'GET' && request.url.path == '/activities/plan/jobs/active') {
          return http.Response(
            jsonEncode({
              'job': {
                'id': 'job_123',
                'patient_id': ResidentFixtures.toBackendUuid('res_margaret'),
                'job_type': 'generation',
                'status': 'in_progress',
                'phase': 'synthesis',
                'created_at': '2026-11-15T10:00:00Z',
                'updated_at': '2026-11-15T10:00:05Z',
              },
            }),
            200,
          );
        }
        if (request.method == 'POST' && request.url.path == '/activities/plan/jobs/job_123/cancel') {
          return http.Response(
            jsonEncode({
              'id': 'job_123',
              'patient_id': ResidentFixtures.toBackendUuid('res_margaret'),
              'job_type': 'generation',
              'status': 'canceled',
              'phase': 'synthesis',
              'created_at': '2026-11-15T10:00:00Z',
              'updated_at': '2026-11-15T10:00:10Z',
            }),
            200,
          );
        }
        if (request.method == 'POST' && request.url.path == '/activities/plan/jobs/job_123/dismiss') {
          return http.Response(
            jsonEncode({
              'id': 'job_123',
              'patient_id': ResidentFixtures.toBackendUuid('res_margaret'),
              'job_type': 'generation',
              'status': 'completed',
              'phase': 'completed',
              'dismissed_at': '2026-11-15T10:01:00Z',
              'created_at': '2026-11-15T10:00:00Z',
              'updated_at': '2026-11-15T10:01:00Z',
            }),
            200,
          );
        }
        if (request.method == 'POST' && request.url.path == '/activities/plan/baseline') {
          return http.Response(
            jsonEncode({
              'id': 'plan_baseline',
              'patient_id': ResidentFixtures.toBackendUuid('res_margaret'),
              'week_start_date': '2026-11-16',
              'generation_source': 'baseline_fallback',
              'plan_status': 'applied',
              'generated_at': '2026-11-15T10:02:00Z',
              'items': [],
            }),
            201,
          );
        }
        return http.Response('not found', 404);
      });

      final apiClient = ApiClient(baseUrl: 'http://localhost:8080', httpClient: mockClient);
      final repo = HttpCareTasksRepository(apiClient: apiClient);

      final job = await repo.enqueueWeeklyRegimen(resident: ResidentFixtures.margaretThompson);
      expect(job.id, 'job_123');
      expect(job.status, BatchJobStatus.queued);

      expect(
        () => repo.enqueueWeeklyRegimen(
          resident: ResidentFixtures.dorothyWilliams,
        ),
        throwsA(isA<RegimenBatchConflictException>()),
      );

      final active = await repo.getActiveBatchJob('res_margaret');
      expect(active?.status, BatchJobStatus.inProgress);
      expect(active?.phase, RegimenGenerationPhase.synthesis);

      final canceled = await repo.cancelBatchJob('res_margaret', 'job_123');
      expect(canceled.status, BatchJobStatus.canceled);

      final dismissed = await repo.dismissBatchJob('res_margaret', 'job_123');
      expect(dismissed.dismissedAt, isNotNull);

      final baseline = await repo.applyImmediateBaseline(resident: ResidentFixtures.margaretThompson);
      expect(baseline.generationSource, RegimenGenerationSource.baselineFallback);
      expect(baseline.planStatus, 'applied');
    });

    test('RegimenBatchNotifier polls until completion, preserves state on transient poll error, and handles retry/baseline', () async {
      final repo = MockCareTasksRepository(batchStepDelay: const Duration(milliseconds: 20));
      final container = ProviderContainer(
        overrides: [
          careTasksRepositoryProvider.overrideWithValue(repo),
          regimenBatchProvider.overrideWith(
            (ref) => RegimenBatchNotifier(
              repo,
              ref,
              pollInterval: const Duration(milliseconds: 40),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(regimenBatchProvider.notifier);

      final queued = await notifier.enqueueGeneration(ResidentFixtures.margaretThompson);
      expect(queued, isNotNull);
      expect(notifier.state.hasActiveJobFor('res_margaret'), isTrue);

      await Future.delayed(const Duration(milliseconds: 180));
      final completed = notifier.state.jobForResident('res_margaret');
      expect(completed?.status, BatchJobStatus.completed);
      expect(notifier.state.lastCompletionEvent?.residentId, 'res_margaret');

      // Test failure + retry + baseline
      repo.simulateNextBatchFailure = true;
      await notifier.dismissJob('res_margaret');
      await notifier.enqueueGeneration(ResidentFixtures.margaretThompson);
      await Future.delayed(const Duration(milliseconds: 180));
      expect(notifier.state.jobForResident('res_margaret')?.status, BatchJobStatus.failed);

      await notifier.applyImmediateBaseline(ResidentFixtures.margaretThompson);
      expect(notifier.state.jobForResident('res_margaret'), isNull);
    });

    test('RegimenBatchNotifier preserves last known active job on transient refresh error', () async {
      final repo = _FlakyPollMockRepo(batchStepDelay: const Duration(milliseconds: 80));
      final container = ProviderContainer(
        overrides: [
          careTasksRepositoryProvider.overrideWithValue(repo),
          regimenBatchProvider.overrideWith(
            (ref) => RegimenBatchNotifier(
              repo,
              ref,
              pollInterval: const Duration(milliseconds: 30),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(regimenBatchProvider.notifier);

      await notifier.enqueueGeneration(ResidentFixtures.margaretThompson);
      repo.throwOnGetActive = true;
      await notifier.refreshActiveJob('res_margaret');

      // Must preserve active job despite transient network error
      expect(notifier.state.jobForResident('res_margaret')?.isActive, isTrue);
      repo.throwOnGetActive = false;
      await Future.delayed(const Duration(milliseconds: 250));
    });

    test('T013: refreshActiveJob falls back to getBatchJob when getActiveBatchJob returns null for an active job', () async {
      final repo = _NullActiveFallbackMockRepo();
      final container = ProviderContainer(
        overrides: [
          careTasksRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(regimenBatchProvider.notifier);
      final enqueued = await notifier.enqueueGeneration(ResidentFixtures.margaretThompson);
      expect(enqueued, isNotNull);
      expect(enqueued!.isActive, isTrue);

      repo.returnNullFromGetActive = true;
      await notifier.refreshActiveJob(ResidentFixtures.margaretThompson.id);

      final updated = container
          .read(regimenBatchProvider)
          .jobForResident(ResidentFixtures.margaretThompson.id);
      expect(repo.getBatchJobCalls, greaterThanOrEqualTo(1));
      expect(updated, isNotNull);
      expect(updated!.isCompleted, isTrue);
      expect(updated.plan, isNotNull);
      expect(container.read(regimenBatchProvider).lastCompletionEvent?.job.id, enqueued.id);
      expect(container.read(careTasksProvider).activePreviewPlan?.id, updated.plan!.id);
    });
  });
}

class _NullActiveFallbackMockRepo extends MockCareTasksRepository {
  bool returnNullFromGetActive = false;
  int getBatchJobCalls = 0;

  @override
  Future<RegimenBatchJob?> getActiveBatchJob(String residentId) async {
    if (returnNullFromGetActive) {
      return null;
    }
    return super.getActiveBatchJob(residentId);
  }

  @override
  Future<RegimenBatchJob> getBatchJob(String residentId, String jobId) async {
    getBatchJobCalls++;
    final now = DateTime.now().toUtc();
    final plan = await generateWeeklyRegimen(
      resident: ResidentFixtures.margaretThompson,
      weekStartDate: now,
      autoApply: false,
    );
    return RegimenBatchJob(
      id: jobId,
      residentId: residentId,
      requestedBy: 'cg_test',
      jobType: BatchJobType.generation,
      status: BatchJobStatus.completed,
      phase: RegimenGenerationPhase.completed,
      weekStartDate: now,
      planId: plan.id,
      plan: plan,
      createdAt: now.subtract(const Duration(minutes: 4)),
      completedAt: now,
      updatedAt: now,
    );
  }
}

class _FlakyPollMockRepo extends MockCareTasksRepository {
  bool throwOnGetActive = false;

  _FlakyPollMockRepo({super.batchStepDelay});

  @override
  Future<RegimenBatchJob?> getActiveBatchJob(String residentId) async {
    if (throwOnGetActive) {
      throw Exception('Transient network timeout');
    }
    return super.getActiveBatchJob(residentId);
  }
}

class _SlowGenerateMockRepo extends MockCareTasksRepository {
  @override
  Future<RegimenPlan> generateWeeklyRegimen({
    required Resident resident,
    DateTime? weekStartDate,
    String? refinementInstruction,
    bool autoApply = false,
    bool forceBaseline = false,
  }) async {
    if (!forceBaseline) {
      await Future.delayed(const Duration(milliseconds: 250));
    }
    return super.generateWeeklyRegimen(
      resident: resident,
      weekStartDate: weekStartDate,
      refinementInstruction: refinementInstruction,
      autoApply: autoApply,
      forceBaseline: forceBaseline,
    );
  }
}
