import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:elderly_mobile/presentation/family_portal/family_portal_screen.dart';
import 'platform_harness.dart';

void main() {
  testWidgets('iOS: FamilyPortalScreen renders with Cupertino styling and touch targets', (tester) async {
    await tester.pumpWidget(
      createPlatformTestWidget(
        platform: TargetPlatform.iOS,
        child: const FamilyPortalScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kubo North'), findsOneWidget);
    expect(find.text('Margaret Thompson'), findsOneWidget);
    expect(find.text('Their Full Story & Milestones'), findsOneWidget);
  });
}
