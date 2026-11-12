import 'dart:async';
import 'dart:convert';

import 'package:elderly_mobile/core/config/app_config.dart';
import 'package:elderly_mobile/core/network/api_client.dart';
import 'package:elderly_mobile/data/fixtures/resident_fixtures.dart';
import 'package:elderly_mobile/data/repositories/http_auth_repository.dart';
import 'package:elderly_mobile/data/repositories/http_care_tasks_repository.dart';
import 'package:elderly_mobile/data/repositories/http_resident_repository.dart';
import 'package:elderly_mobile/data/repositories/mock_care_tasks_repository.dart';
import 'package:elderly_mobile/domain/entities/care_task.dart';
import 'package:elderly_mobile/domain/entities/regimen_plan.dart';
import 'package:elderly_mobile/domain/entities/resident.dart';
import 'package:elderly_mobile/presentation/care_tasks/care_tasks_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _DelayedFakeCareRepo extends MockCareTasksRepository {
  Completer<RegimenPlan>? firstGenGate;
  int generateCalls = 0;
  bool shouldThrowOnGet = false;

  @override
  Future<List<CareTask>> getTasks(String residentId) async {
    if (shouldThrowOnGet) {
      throw const ApiException(statusCode: 401, message: 'Unauthorized');
    }
    return super.getTasks(residentId);
  }

  @override
  Future<RegimenPlan> generateWeeklyRegimen({
    required Resident resident,
    DateTime? weekStartDate,
    String? refinementInstruction,
    bool autoApply = false,
    bool forceBaseline = false,
  }) async {
    generateCalls++;
    if (!forceBaseline && firstGenGate != null) {
      return firstGenGate!.future;
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

void main() {
  group('Security and Lifecycle Regression Tests', () {
    test('CareTasksNotifier completes superseded and disposed completers cleanly', () async {
      final repo = _DelayedFakeCareRepo()..firstGenGate = Completer<RegimenPlan>();
      final notifier = CareTasksNotifier(
        repository: repo,
        residentId: 'res_margaret',
      );
      final resident = ResidentFixtures.findById('res_margaret');

      // Start an in-flight generation, then switch to baseline
      final firstFuture = notifier.generateRegimen(resident: resident);
      final baselineFuture = notifier.cancelAndSwitchToBaseline(resident);

      final firstResult = await firstFuture.timeout(const Duration(seconds: 2));
      final baselineResult = await baselineFuture.timeout(const Duration(seconds: 2));

      expect(firstResult, isNotNull);
      expect(baselineResult, isNotNull);

      // Start another delayed generation and dispose mid-flight
      repo.firstGenGate = Completer<RegimenPlan>();
      final pendingBeforeDispose = notifier.generateRegimen(resident: resident);
      notifier.dispose();
      final disposedResult = await pendingBeforeDispose.timeout(const Duration(seconds: 2));
      expect(disposedResult, isNull);
    });

    test('CareTasksNotifier loadTasks clears isLoading on error', () async {
      final repo = _DelayedFakeCareRepo()..shouldThrowOnGet = true;
      final notifier = CareTasksNotifier(
        repository: repo,
        residentId: 'res_margaret',
      );
      await Future.delayed(const Duration(milliseconds: 50));
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.generationError, contains('401'));
      notifier.dispose();
    });

    test('HttpCareTasksRepository does not copy goal to completionNote, evicts retry queue, and never falls back on 401', () async {
      var failPatch = true;
      String? capturedProbeAuthHeader;
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/demo-accounts')) {
          capturedProbeAuthHeader = request.headers['Authorization'];
          return http.Response(jsonEncode([]), 200);
        }
        if (request.url.path.contains('/activities/agenda/today')) {
          return http.Response(
            jsonEncode([
              {
                'id': '11111111-1111-1111-1111-111111111111',
                'title': 'Botanical Matching',
                'description': 'Match dried leaves',
                'goal': 'Sensory memory stimulation',
                'status': 'pending',
                'montessori_area': 'Sensorial',
              }
            ]),
            200,
          );
        }
        if (request.method == 'PATCH' && request.url.path.contains('/status')) {
          if (failPatch) {
            return http.Response('{"error": "temporary"}', 503);
          }
          return http.Response(
            jsonEncode({
              'id': '11111111-1111-1111-1111-111111111111',
              'title': 'Botanical Matching',
              'goal': 'Sensory memory stimulation',
              'status': 'completed',
            }),
            200,
          );
        }
        if (request.url.path.contains('/patients')) {
          return http.Response('{"error": "unauthorized"}', 401);
        }
        if (request.url.path.endsWith('/auth/login')) {
          return http.Response('{"error": "invalid credentials"}', 401);
        }
        return http.Response('{}', 404);
      });

      final client = ApiClient(
        baseUrl: 'http://localhost:8080/api/v1',
        initialAuthToken: 'secret-bearer-token',
        httpClient: mockClient,
      );

      // 1. testConnection strips Authorization header
      final connRes = await client.testConnection('http://untrusted.example.com/api/v1');
      expect(connRes.isSuccess, isTrue);
      expect(capturedProbeAuthHeader, isNull);

      final careRepo = HttpCareTasksRepository(apiClient: client);
      final tasks = await careRepo.getTasks('res_margaret');
      expect(tasks, hasLength(1));
      // 2. completionNote must remain null rather than mirroring goal
      expect(tasks.first.completionNote, isNull);

      // 3. Transient failure queues retry, subsequent success evicts it
      await careRepo.updateTaskStatus(
        residentId: 'res_margaret',
        taskId: '11111111-1111-1111-1111-111111111111',
        status: TaskStatus.completed,
      );
      expect(careRepo.pendingRetryQueue, hasLength(1));

      failPatch = false;
      await careRepo.updateTaskStatus(
        residentId: 'res_margaret',
        taskId: '11111111-1111-1111-1111-111111111111',
        status: TaskStatus.completed,
      );
      expect(careRepo.pendingRetryQueue, isEmpty);

      // 4. 401/403 must not fall back to mock data
      final residentRepo = HttpResidentRepository(apiClient: client);
      await expectLater(
        () => residentRepo.getResident('res_margaret'),
        throwsA(isA<ApiException>()),
      );

      final authRepo = HttpAuthRepository(apiClient: client);
      final loginResult = await authRepo.loginWithCredentials('sarah', 'wrong');
      expect(loginResult, isNull);

      // 5. validateBaseUrl rejects cleartext http when requireHttps is true
      expect(AppConfig.validateBaseUrl('http://api.kubocare.com/api/v1', requireHttps: true), isNotNull);
      expect(AppConfig.validateBaseUrl('https://api.kubocare.com/api/v1', requireHttps: true), isNull);
    });
  });
}
