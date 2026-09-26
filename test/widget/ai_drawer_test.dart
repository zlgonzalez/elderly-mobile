import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:elderly_mobile/presentation/ai_assistant/ai_assistant_drawer.dart';
import '../platform/platform_harness.dart';

void main() {
  testWidgets('AiAssistantDrawer displays header, prompt chips, and streams assistant replies', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      createPlatformTestWidget(
        child: const Scaffold(
          body: AiAssistantDrawer(contextScreen: 'Family Portal'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title and Subtitle
    expect(find.text('Ask Kubo AI'), findsOneWidget);
    expect(find.textContaining('Assisting with Margaret Thompson'), findsOneWidget);

    // Verify Welcome message
    expect(find.textContaining('Hello! I am your Kubo Care Companion'), findsOneWidget);

    // Verify Quick Suggestion Chips
    expect(find.text('What should I bring on visits?'), findsOneWidget);
    expect(find.text('How to soothe agitation during sundowning?'), findsOneWidget);

    // Tap quick suggestion chip
    await tester.tap(find.text('What should I bring on visits?'));
    await tester.pump();
    await tester.pumpAndSettle();

    // Verify user bubble appeared
    expect(find.text('What should I bring on visits?'), findsWidgets);

    // Verify assistant answer appeared
    expect(find.textContaining('Familiar Sensory Anchors'), findsOneWidget);

    // Test text input field
    final textField = find.byType(TextField);
    expect(textField, findsOneWidget);
    await tester.enterText(textField, 'Tell me about Margaret');
    await tester.pump();

    // Tap Send button
    final sendBtn = find.byIcon(Icons.arrow_upward);
    expect(sendBtn, findsOneWidget);
    await tester.tap(sendBtn);
    await tester.pump();
    await tester.pumpAndSettle();

    // Verify custom query response
    expect(find.textContaining('Gardening'), findsOneWidget);
  });
}
