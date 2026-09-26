import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:elderly_mobile/presentation/activity_guide/activity_guide_screen.dart';
import '../platform/platform_harness.dart';

void main() {
  testWidgets('ActivityGuideScreen renders dignity banner, category filters, and card expansion', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      createPlatformTestWidget(
        child: const ActivityGuideScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Montessori Principles Dignity Banner
    expect(find.textContaining('Montessori Principles: Support independence'), findsOneWidget);

    // Verify Category Filter Chips
    expect(find.textContaining('All'), findsWidgets);
    expect(find.textContaining('Practical Life'), findsWidgets);
    expect(find.textContaining('Cognitive'), findsWidgets);
    expect(find.textContaining('Creative'), findsWidgets);
    expect(find.textContaining('Sensory'), findsWidgets);
    expect(find.textContaining('Social'), findsWidgets);

    // Verify initial activities displayed
    expect(find.text('Folding Warm Linens & Towels'), findsOneWidget);
    expect(find.textContaining('Why this matters'), findsWidgets);

    // Tap to filter by "Sensory"
    final sensoryChip = find.textContaining('Sensory').first;
    await tester.ensureVisible(sensoryChip);
    await tester.pumpAndSettle();
    await tester.tap(sensoryChip);
    await tester.pumpAndSettle();

    // Verify sensory items are visible and practical life items are filtered out
    expect(find.text('Lavender Scent Bags & Aromatherapy'), findsOneWidget);
    expect(find.text('Folding Warm Linens & Towels'), findsNothing);

    // Expand facilitation steps on the Lavender Scent Bags card
    final expandBtn = find.textContaining('How to do this activity').first;
    await tester.tap(expandBtn);
    await tester.pumpAndSettle();

    // Verify facilitation steps and dignity note appear
    expect(find.text('Hide facilitation steps'), findsOneWidget);
    expect(find.textContaining('Rub a few lavender buds between palms'), findsOneWidget);
    expect(find.textContaining('Dignity Note:'), findsOneWidget);

    // Schedule to Care Tasks
    final scheduleBtn = find.widgetWithText(OutlinedButton, 'Schedule to Care Tasks').first;
    await tester.tap(scheduleBtn);
    await tester.pumpAndSettle();

    // Verify SnackBar confirmation
    expect(find.textContaining('Scheduled "Lavender Scent Bags & Aromatherapy" to Care Tasks!'), findsOneWidget);
  });
}
