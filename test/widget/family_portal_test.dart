import 'package:flutter_test/flutter_test.dart';
import 'package:elderly_mobile/presentation/family_portal/family_portal_screen.dart';
import '../platform/platform_harness.dart';

void main() {
  testWidgets('FamilyPortalScreen renders status card, Their Story, and Montessori guide', (tester) async {
    await tester.pumpWidget(
      createPlatformTestWidget(
        child: const FamilyPortalScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kubo North'), findsOneWidget);
    expect(find.text('Margaret Thompson'), findsOneWidget);
    expect(find.text('Their Story'), findsOneWidget);
    expect(find.text('Montessori Activity Guide'), findsOneWidget);
    expect(find.text('Ask Kubo North AI'), findsOneWidget);
    expect(find.text('Lunch Intake Alert (50% Eaten)'), findsOneWidget);
  });
}
