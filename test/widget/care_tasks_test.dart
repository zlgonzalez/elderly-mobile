import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:elderly_mobile/presentation/care_tasks/care_tasks_screen.dart';
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
}
