import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:elderly_mobile/data/fixtures/resident_fixtures.dart';
import 'package:elderly_mobile/data/repositories/care_tasks_repository.dart';
import 'package:elderly_mobile/data/repositories/mock_auth_repository.dart';
import 'package:elderly_mobile/data/repositories/mock_care_tasks_repository.dart';
import 'package:elderly_mobile/domain/entities/care_task.dart';
import 'package:elderly_mobile/domain/entities/regimen_plan.dart';
import 'package:elderly_mobile/domain/entities/resident.dart';
import 'package:elderly_mobile/domain/entities/user_profile.dart';
import 'package:elderly_mobile/presentation/auth/auth_provider.dart';
import 'package:elderly_mobile/presentation/care_tasks/care_tasks_screen.dart';
import 'package:elderly_mobile/presentation/family_portal/resident_provider.dart';
import '../platform/platform_harness.dart';

void main() {
  testWidgets('CareTasksScreen displays schedule, progress, and supports complete action and add task', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      createPlatformTestWidget(
        child: const CareTasksScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title and progress summary
    expect(find.text("Today's Schedule"), findsOneWidget);
    expect(find.text('1/3 completed today'), findsOneWidget);

    // Verify pre-loaded tasks
    expect(find.text('Morning Garden Walk'), findsOneWidget);
    expect(find.text('Folding Laundry'), findsOneWidget);
    expect(find.text('Music Reminiscence Session'), findsOneWidget);

    // Verify Category badges
    expect(find.text('Physical'), findsWidgets);
    expect(find.text('Purposeful'), findsWidgets);
    expect(find.text('Social'), findsWidgets);

    // Complete the "Folding Laundry" task
    final completeBtn = find.widgetWithText(ElevatedButton, 'Complete').first;
    expect(completeBtn, findsOneWidget);
    await tester.tap(completeBtn);
    await tester.pumpAndSettle();

    // Verify confirmation dialog
    expect(find.textContaining('Complete "Folding Laundry"'), findsOneWidget);
    await tester.tap(find.text('Mark Complete'));
    await tester.pumpAndSettle();

    // Verify progress updated to 2/3
    expect(find.text('2/3 completed today'), findsOneWidget);

    // Open Add Task modal
    final addTaskBtn = find.widgetWithText(ElevatedButton, 'Add Task');
    expect(addTaskBtn, findsOneWidget);
    await tester.tap(addTaskBtn);
    await tester.pumpAndSettle();

    // Verify Schedule New Activity modal
    expect(find.text('Schedule New Activity'), findsOneWidget);
    expect(find.text('Activity Title *'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Activity Title *'), 'Afternoon Garden Walk');
    await tester.pump();

    await tester.tap(find.text('Schedule Activity'));
    await tester.pumpAndSettle();

    // Verify new task in schedule
    expect(find.text('Afternoon Garden Walk'), findsOneWidget);
  });

  testWidgets('Role guard hides regimen generation for family members and intake prompts when capabilities missing', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const familyUser = UserProfile(
      id: 'fam_1',
      username: 'family',
      fullName: 'Sarah Thompson',
      role: UserRole.familyMember,
      relation: 'Daughter',
      phone: '555-0101',
      linkedResidentId: 'res_margaret',
    );

    await tester.pumpWidget(
      createPlatformTestWidget(
        overrides: [
          authProvider.overrideWith(
            (ref) => AuthNotifier(
              MockAuthRepository(),
              const AuthState(user: familyUser),
            ),
          ),
        ],
        child: const CareTasksScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Generate 7-Day Regimen'), findsNothing);

    // Unmount first ProviderScope cleanly before mounting a second one with different overrides.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    // Caregiver on resident missing capabilities sees intake prompt
    const caregiverUser = UserProfile(
      id: 'cg_1',
      username: 'caregiver',
      fullName: 'Nurse Jane',
      role: UserRole.visitingCaregiver,
      relation: 'Caregiver',
      phone: '555-0102',
      linkedResidentId: 'res_dorothy',
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
          residentProvider.overrideWith(
            (ref) => ResidentNotifier(ResidentFixtures.dorothyWilliams),
          ),
        ],
        child: const CareTasksScreen(),
      ),
    );
    await tester.pumpAndSettle();

    final genBtn = find.text('Generate 7-Day Regimen');
    expect(genBtn, findsOneWidget);
    await tester.tap(genBtn);
    await tester.pumpAndSettle();

    expect(find.text('Resident Capability Intake'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Cognitive Capability *'),
      'Mild dementia; enjoys clear visual cues',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Physical Capability *'),
      'Independent mobility; seated comfort',
    );
    await tester.tap(find.text('Save & Generate Plan'));
    await tester.pumpAndSettle();

    expect(find.text('7-Day Montessori Regimen Preview'), findsOneWidget);
    expect(find.text('Apply 7-Day Plan'), findsOneWidget);
    expect(find.text('Change Start Date'), findsOneWidget);
    expect(find.textContaining('Cognitive:'), findsOneWidget);
    expect(find.textContaining('Balance:'), findsOneWidget);
  });

  testWidgets('RegimenPreviewSheet displays FR-004 detail fields and prompts confirmation dialog when composite score < 70', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final lowScoreRepo = _LowScorePreviewRepository();
    const adminUser = UserProfile(
      id: 'adm_1',
      username: 'admin',
      fullName: 'Director',
      role: UserRole.admin,
      relation: 'Administrator',
      phone: '555-0199',
      linkedResidentId: 'res_margaret',
    );

    await tester.pumpWidget(
      createPlatformTestWidget(
        overrides: [
          authProvider.overrideWith(
            (ref) => AuthNotifier(
              MockAuthRepository(),
              const AuthState(user: adminUser),
            ),
          ),
          careTasksRepositoryProvider.overrideWithValue(lowScoreRepo),
        ],
        child: const CareTasksScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Generate 7-Day Regimen'));
    await tester.pumpAndSettle();

    expect(find.text('7-Day Montessori Regimen Preview'), findsOneWidget);
    expect(find.textContaining('Tray setup: Weighted oak tray'), findsOneWidget);
    expect(find.textContaining('Prompt: "Shall we match these cards?"'), findsOneWidget);
    expect(find.textContaining('Dignity tip: Offer choice cleanly'), findsOneWidget);
    expect(find.textContaining('Safety & comfort: Keep tray centered'), findsOneWidget);
    expect(find.text('Cognitive: 14'), findsOneWidget);
    expect(find.text('Balance: 12'), findsOneWidget);

    await tester.tap(find.text('Apply 7-Day Plan'));
    await tester.pumpAndSettle();

    expect(find.text('Low Clinical Score Confirmation'), findsOneWidget);
    await tester.tap(find.text('Confirm & Apply'));
    await tester.pumpAndSettle();

    expect(lowScoreRepo.appliedWithAck, isTrue);
  });
}

class _LowScorePreviewRepository extends MockCareTasksRepository {
  bool appliedWithAck = false;

  @override
  Future<RegimenPlan> generateWeeklyRegimen({
    required Resident resident,
    DateTime? weekStartDate,
    String? refinementInstruction,
    bool autoApply = false,
    bool forceBaseline = false,
  }) async {
    return RegimenPlan(
      id: 'plan_low_score',
      residentId: resident.id,
      weekStartDate: DateTime.utc(2026, 11, 12),
      generationSource: RegimenGenerationSource.kuboAgent,
      planStatus: 'preview',
      scorecard: const ClinicalScorecard(
        compositeScore: 62,
        cognitiveAlignmentScore: 14,
        physicalAccessibilityScore: 12,
        purposefulEngagementScore: 12,
        safetyControlOfErrorScore: 12,
        modalityBalanceScore: 12,
        feedback: 'Needs extra caregiver supervision.',
      ),
      generatedAt: DateTime.utc(2026, 11, 11),
      items: [
        CareTask(
          id: 'low_1',
          residentId: resident.id,
          planId: 'plan_low_score',
          dayNumber: 1,
          title: 'Calm Botanical Matching',
          description: 'Seated card matching',
          time: '10:00 AM',
          category: TaskCategory.activity,
          materials: const ['Large botanical cards'],
          materialsTraySetup: 'Weighted oak tray',
          steps: const ['Set cards face up', 'Match pairs together'],
          scriptPrompt: 'Shall we match these cards?',
          dignityTip: 'Offer choice cleanly',
          safetyComfort: 'Keep tray centered',
          historicalConnection: 'Loves botanical gardens',
        ),
      ],
    );
  }

  @override
  Future<RegimenPlan> applyRegimen({
    required String residentId,
    required String planId,
    DateTime? weekStartDate,
    bool acknowledgeLowScore = false,
  }) async {
    appliedWithAck = acknowledgeLowScore;
    return RegimenPlan(
      id: planId,
      residentId: residentId,
      weekStartDate: weekStartDate ?? DateTime.utc(2026, 11, 12),
      generationSource: RegimenGenerationSource.kuboAgent,
      planStatus: 'applied',
      generatedAt: DateTime.utc(2026, 11, 11),
    );
  }
}
