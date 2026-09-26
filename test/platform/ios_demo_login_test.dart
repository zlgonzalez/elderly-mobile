import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:elderly_mobile/presentation/auth/demo_login_screen.dart';
import 'platform_harness.dart';

void main() {
  testWidgets('iOS: DemoLoginScreen renders properly on iOS platform', (tester) async {
    await tester.pumpWidget(
      createPlatformTestWidget(
        platform: TargetPlatform.iOS,
        child: const DemoLoginScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kubo North'), findsOneWidget);
    expect(find.text("Margaret's family"), findsOneWidget);
    expect(find.text("Robert's family"), findsOneWidget);
    expect(find.text("Dorothy's family"), findsOneWidget);
    expect(find.text('Sign in with Username & Password'), findsOneWidget);
  });
}
