import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:elderly_mobile/presentation/their_story/their_story_screen.dart';
import 'platform_harness.dart';

void main() {
  testWidgets('iOS: TheirStoryScreen renders modal sheet presentation with iOS target platform', (tester) async {
    await tester.pumpWidget(
      createPlatformTestWidget(
        platform: TargetPlatform.iOS,
        child: const TheirStoryScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify iOS environment displays header, milestone timeline, and touch targets
    expect(find.text("Margaret Thompson's Story"), findsOneWidget);
    expect(find.text('Vermont Educator of the Year'), findsOneWidget);

    // Verify minimum touch targets for elderly iOS experience
    final buttonFinder = find.widgetWithText(ElevatedButton, 'Add to Memory Box');
    expect(buttonFinder, findsOneWidget);
    final buttonSize = tester.getSize(buttonFinder);
    expect(buttonSize.height, greaterThanOrEqualTo(48.0));
  });
}
