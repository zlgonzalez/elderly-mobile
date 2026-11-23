import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:elderly_mobile/data/repositories/care_tasks_repository.dart';
import 'package:elderly_mobile/data/repositories/mock_auth_repository.dart';
import 'package:elderly_mobile/data/repositories/mock_care_tasks_repository.dart';
import 'package:elderly_mobile/domain/entities/regimen_plan.dart';
import 'package:elderly_mobile/domain/entities/resident.dart';
import 'package:elderly_mobile/domain/entities/user_profile.dart';
import 'package:elderly_mobile/presentation/auth/auth_provider.dart';
import 'package:elderly_mobile/presentation/care_tasks/care_tasks_screen.dart';
import 'package:elderly_mobile/presentation/care_tasks/regimen_batch_provider.dart';
import '../platform/platform_harness.dart';

class _ActiveNullFallbackCareTasksRepository extends MockCareTasksRepository {
  RegimenBatchJob? _completedJob;
  int getBatchJobCalls = 0;

  @override
  Future<RegimenBatchJob> enqueueWeeklyRegimen({
    required Resident resident,
    DateTime? weekStartDate,
    String? refinementInstruction,
    bool autoApply = false,
  }) async {
    final now = DateTime.now().toUtc();
    final plan = await generateWeeklyRegimen(
      resident: resident,
      weekStartDate: weekStartDate,
    );
    _completedJob = RegimenBatchJob(
      id: 'job_013_fallback',
      residentId: resident.id,
      requestedBy: 'cg_batch_spec_013',
      jobType: BatchJobType.generation,
      status: BatchJobStatus.completed,
      phase: RegimenGenerationPhase.completed,
      weekStartDate: now,
      planId: plan.id,
      plan: plan,
      createdAt: now,
      updatedAt: now,
      completedAt: now,
    );
    return RegimenBatchJob(
      id: 'job_013_fallback',
      residentId: resident.id,
      requestedBy: 'cg_batch_spec_013',
      jobType: BatchJobType.generation,
      status: BatchJobStatus.inProgress,
      phase: RegimenGenerationPhase.synthesis,
      weekStartDate: now,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<RegimenBatchJob?> getActiveBatchJob(String residentId) async {
    // Simulate /activities/plan/jobs/active returning null right as job completes
    return null;
  }

  @override
  Future<RegimenBatchJob> getBatchJob(String residentId, String jobId) async {
    getBatchJobCalls++;
    return _completedJob!;
  }
}

void main() {
  group('012-batch-regimen-generation Spec Integration Tests', () {
    testWidgets(
      'US1 / US2 / FR-004 / FR-006: Submitting generation returns immediately without blocking modal and displays non-blocking batch banner',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        const caregiverUser = UserProfile(
          id: 'cg_batch_spec',
          username: 'caregiver',
          fullName: 'Nurse Jane',
          role: UserRole.visitingCaregiver,
          relation: 'Caregiver',
          phone: '555-0102',
          linkedResidentId: 'res_margaret',
        );

        await tester.pumpWidget(
          createPlatformTestWidget(
            overrides: [
              authProvider.overrideWith(
                (ref) => AuthNotifier(
                  MockAuthRepository(),
                  const AuthState(user: caregiverUser),
                ),
              ),
            ],
            child: const CareTasksScreen(),
          ),
        );
        await tester.pumpAndSettle();

        final generateBtn = find.text('Generate 7-Day Regimen');
        expect(generateBtn, findsOneWidget);
        await tester.tap(generateBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // FR-004: No blocking GenerationProgressSheet dialog should trap the user
        expect(
          find.text('Kubo is building a 7-day regimen'),
          findsNothing,
          reason: 'Batch submission must not open blocking GenerationProgressSheet',
        );

        // FR-006: Non-blocking batch status banner must appear on CareTasksScreen
        expect(
          find.byKey(const Key('regimen_batch_banner')),
          findsOneWidget,
          reason: 'CareTasksScreen must display the persistent RegimenBatchBanner after submission',
        );

        // Allow mock batch job and 3s poll timer to finish cleanly before test teardown
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();
        expect(find.text('Review Plan'), findsOneWidget);
      },
    );

    testWidgets(
      '013 US2 / FR-005 / FR-006 / FR-010: Falls back to getBatchJob by ID when getActiveBatchJob returns null and delivers completed plan without blocking UI',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fallbackRepo = _ActiveNullFallbackCareTasksRepository();
        const caregiverUser = UserProfile(
          id: 'cg_batch_spec_013',
          username: 'caregiver',
          fullName: 'Nurse Jane',
          role: UserRole.visitingCaregiver,
          relation: 'Caregiver',
          phone: '555-0102',
          linkedResidentId: 'res_margaret',
        );

        await tester.pumpWidget(
          createPlatformTestWidget(
            overrides: [
              careTasksRepositoryProvider.overrideWithValue(fallbackRepo),
              regimenBatchProvider.overrideWith(
                (ref) => RegimenBatchNotifier(
                  fallbackRepo,
                  ref,
                  pollInterval: const Duration(milliseconds: 100),
                ),
              ),
              authProvider.overrideWith(
                (ref) => AuthNotifier(
                  MockAuthRepository(),
                  const AuthState(user: caregiverUser),
                ),
              ),
            ],
            child: const CareTasksScreen(),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Generate 7-Day Regimen'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
        await tester.pumpAndSettle();

        expect(
          fallbackRepo.getBatchJobCalls,
          greaterThan(0),
          reason: 'FR-005: Must fall back to getBatchJob(residentId, previous.id) when active lookup returns null',
        );
        expect(
          find.text('Review Plan'),
          findsOneWidget,
          reason: 'FR-006: Completed banner with Review Plan must appear after fallback hydration',
        );
      },
    );
  });
}
