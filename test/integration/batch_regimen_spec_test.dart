import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:elderly_mobile/data/repositories/mock_auth_repository.dart';
import 'package:elderly_mobile/domain/entities/user_profile.dart';
import 'package:elderly_mobile/presentation/auth/auth_provider.dart';
import 'package:elderly_mobile/presentation/care_tasks/care_tasks_screen.dart';
import '../platform/platform_harness.dart';

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
  });
}
