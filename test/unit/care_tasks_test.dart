import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:elderly_mobile/core/network/api_client.dart';
import 'package:elderly_mobile/data/fixtures/resident_fixtures.dart';
import 'package:elderly_mobile/data/repositories/http_care_tasks_repository.dart';
import 'package:elderly_mobile/data/repositories/mock_care_tasks_repository.dart';
import 'package:elderly_mobile/domain/entities/care_task.dart';
import 'package:elderly_mobile/domain/entities/montessori_activity.dart';
import 'package:elderly_mobile/domain/entities/regimen_plan.dart';
import 'package:elderly_mobile/domain/entities/resident.dart';
import 'package:elderly_mobile/domain/entities/user_profile.dart';
import 'package:elderly_mobile/presentation/care_tasks/care_tasks_provider.dart';

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
