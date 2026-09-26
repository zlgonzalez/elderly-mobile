import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:elderly_mobile/presentation/mood_journal/mood_journal_screen.dart';
import 'package:elderly_mobile/presentation/family_portal/resident_provider.dart';
import 'package:elderly_mobile/data/fixtures/resident_fixtures.dart';
import '../platform/platform_harness.dart';

void main() {
  testWidgets('MoodJournalScreen displays trends, pre-loaded moods, and logs new mood', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      createPlatformTestWidget(
        child: const MoodJournalScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title and sections
    expect(find.text('Weekly Mood Trends'), findsOneWidget);
    expect(find.text('Mood History'), findsOneWidget);
    expect(find.text('Log Current Mood'), findsOneWidget);

    // Verify pre-loaded entries for Margaret
    expect(find.text('Happy'), findsWidgets);
    expect(find.text('Content'), findsWidgets);
    expect(find.text('Anxious'), findsWidgets);
    expect(find.text('Ask Kubo North AI'), findsOneWidget);

    // Open "Log Current Mood" sheet
    await tester.tap(find.text('Log Current Mood'));
    await tester.pumpAndSettle();

    // Verify modal title and fields
    expect(find.text('How is your loved one feeling right now?'), findsOneWidget);
    expect(find.text('Save Mood Entry'), findsOneWidget);

    // Enter notes
    final notesField = find.widgetWithText(TextFormField, 'Observational Context / Notes');
    expect(notesField, findsOneWidget);
    await tester.enterText(notesField, 'Enjoyed classical music on the porch');
    await tester.pump();

    // Submit form
    await tester.tap(find.text('Save Mood Entry'));
    await tester.pumpAndSettle();

    // Verify new note appears in list
    expect(find.text('"Enjoyed classical music on the porch"'), findsOneWidget);
  });

  testWidgets('MoodJournalScreen shows empty state for Robert Chen', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      createPlatformTestWidget(
        overrides: [
          residentProvider.overrideWith((ref) => ResidentNotifier(ResidentFixtures.robertChen)),
        ],
        child: const MoodJournalScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify empty state display
    expect(find.text('No mood entries yet'), findsOneWidget);
    expect(find.text('Tap "Log Current Mood" above to record emotional wellbeing.'), findsOneWidget);
  });
}
