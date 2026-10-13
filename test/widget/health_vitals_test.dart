import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:elderly_mobile/data/fixtures/resident_fixtures.dart';
import 'package:elderly_mobile/presentation/family_portal/resident_provider.dart';
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

  testWidgets('Switching patients updates RecordVitalsForm and Recent Vitals History immediately', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: HealthVitalsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Initially Margaret Thompson is selected (120/80, 72 BPM, 138 lbs)
    expect(find.text('Margaret Thompson'), findsOneWidget);
    expect(find.text('120/80'), findsWidgets);
    expect(find.text('72'), findsWidgets);
    expect(find.text('138'), findsWidgets);
    expect(find.textContaining('72 BPM', findRichText: true), findsWidgets);

    // Switch to Robert Chen (130/85, 68 BPM, 162 lbs)
    container.read(residentProvider.notifier).selectResident(ResidentFixtures.robertChen);
    await tester.pumpAndSettle();

    expect(find.text('Robert Chen'), findsOneWidget);
    expect(find.text('130/85'), findsWidgets);
    expect(find.text('68'), findsOneWidget);
    expect(find.text('162'), findsOneWidget);
    expect(find.textContaining('68 BPM', findRichText: true), findsWidgets);

    // Switch to Dorothy Williams (118/75, 74 BPM, 125 lbs)
    container.read(residentProvider.notifier).selectResident(ResidentFixtures.dorothyWilliams);
    await tester.pumpAndSettle();

    expect(find.text('Dorothy Williams'), findsOneWidget);
    expect(find.text('118/75'), findsWidgets);
    expect(find.text('74'), findsOneWidget);
    expect(find.text('125'), findsOneWidget);
    expect(find.textContaining('74 BPM', findRichText: true), findsWidgets);
  });
}
