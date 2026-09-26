import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:elderly_mobile/presentation/auth/demo_login_screen.dart';
import 'platform_harness.dart';

void main() {
  testWidgets('Android: DemoLoginScreen renders properly on Android platform', (tester) async {
    await tester.pumpWidget(
      createPlatformTestWidget(
        platform: TargetPlatform.android,
        child: const DemoLoginScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kubo North'), findsOneWidget);
    expect(find.text('Family care for your loved one'), findsOneWidget);
    expect(find.text("Margaret's family"), findsOneWidget);
    expect(find.text("Robert's family"), findsOneWidget);
    expect(find.text("Dorothy's family"), findsOneWidget);
  });
}
