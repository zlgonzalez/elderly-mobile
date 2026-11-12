import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:elderly_mobile/data/repositories/mock_auth_repository.dart';
import 'package:elderly_mobile/domain/entities/care_task.dart';
import 'package:elderly_mobile/domain/entities/resident.dart';
import 'package:elderly_mobile/domain/entities/user_profile.dart';
import 'package:elderly_mobile/presentation/auth/auth_provider.dart';
import 'package:elderly_mobile/presentation/care_tasks/care_tasks_screen.dart';
import '../platform/platform_harness.dart';

void main() {
  group('007-regimen-mobile-integration Spec Tests', () {
    test('US1 / FR-002 / FR-003: Resident serializes cognitive and physical capabilities', () {
      const resident = Resident(
        id: 'res_margaret',
        name: 'Margaret Holloway',
        age: 82,
        avatarUrl: '',
        biography: 'Botany teacher',
        quote: 'Nature teaches patience',
        education: 'MS Botany',
        interests: ['gardening'],
        milestones: [],
        conditions: ['Mild arthritis'],
        allergies: [],
        contacts: [],
      );

      final json = resident.toJson();
      expect(json.containsKey('cognitiveCapability'), isTrue,
          reason: 'Resident must carry cognitiveCapability for regimen generation intake checks');
      expect(json.containsKey('physicalCapability'), isTrue,
          reason: 'Resident must carry physicalCapability for regimen generation intake checks');
    });

    test('US3 / FR-009: CareTask preserves skipReason and Montessori materials/steps', () {
      const task = CareTask(
        id: 'task_1',
        residentId: 'res_margaret',
        title: 'Herb Sorting Tray',
        description: 'Sort fresh herbs by scent',
        time: '09:00 AM',
        category: TaskCategory.purposeful,
        status: TaskStatus.skipped,
      );

      final json = task.toJson();
      expect(json.containsKey('skipReason'), isTrue,
          reason: 'CareTask must expose skipReason for skipped regimen activities');
      expect(json.containsKey('materials'), isTrue,
          reason: 'CareTask must expose materials tray items from generated regimens');
      expect(json.containsKey('steps'), isTrue,
          reason: 'CareTask must expose facilitation steps from generated regimens');
    });

    testWidgets('US1 / FR-001: CareTasksScreen surfaces personalized 7-day regimen generator action for caregivers only', (tester) async {
      await tester.pumpWidget(
        createPlatformTestWidget(
          child: const CareTasksScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Generate 7-Day Regimen'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      const caregiverUser = UserProfile(
        id: 'cg_spec',
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

      expect(find.textContaining('Generate 7-Day Regimen'), findsOneWidget);
    });
  });
}
