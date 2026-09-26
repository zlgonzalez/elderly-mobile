import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:elderly_mobile/presentation/health_vitals/health_vitals_screen.dart';
import '../platform/platform_harness.dart';

void main() {
  testWidgets('HealthVitalsScreen displays medical profile, form, and records vital signs', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      createPlatformTestWidget(
        child: const HealthVitalsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Medical Profile & Conditions
    expect(find.text('Medical Profile & Warnings'), findsOneWidget);
    expect(find.text('Mild Dementia'), findsOneWidget);
    expect(find.text('Arthritis'), findsOneWidget);
    expect(find.text('Hypertension'), findsOneWidget);
    expect(find.text('⚠ Penicillin'), findsOneWidget);

    // Verify Record Vitals Form
    expect(find.text('Record Health Vitals'), findsOneWidget);
    expect(find.text('Blood Pressure *'), findsOneWidget);
    expect(find.text('Heart Rate *'), findsOneWidget);
    expect(find.text('Temperature *'), findsOneWidget);
    expect(find.textContaining('Pain Level:'), findsOneWidget);

    // Verify Submit button
    final submitBtn = find.text('Record Vital Signs');
    expect(submitBtn, findsOneWidget);

    // Enter custom heart rate and submit
    final hrField = find.widgetWithText(TextFormField, 'Heart Rate *');
    await tester.enterText(hrField, '78');
    await tester.pump();

    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    // Verify SnackBar or records list updated with 78 BPM
    expect(find.textContaining('78 BPM'), findsWidgets);
  });
}
