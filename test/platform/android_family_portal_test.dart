import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:elderly_mobile/presentation/family_portal/family_portal_screen.dart';
import 'platform_harness.dart';

void main() {
  testWidgets('Android: FamilyPortalScreen renders Material layout with wellbeing alerts', (tester) async {
    await tester.pumpWidget(
      createPlatformTestWidget(
        platform: TargetPlatform.android,
        child: const FamilyPortalScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kubo North'), findsOneWidget);
    expect(find.text('Lunch Intake Alert (50% Eaten)'), findsOneWidget);
    expect(find.text('Montessori Activity Guide'), findsOneWidget);
  });
}
