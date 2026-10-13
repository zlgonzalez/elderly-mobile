import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:elderly_mobile/core/config/app_config.dart';
import 'package:elderly_mobile/core/network/api_client.dart';
import 'package:elderly_mobile/presentation/auth/demo_login_screen.dart';
import 'package:elderly_mobile/presentation/family_portal/family_portal_screen.dart';
import 'package:elderly_mobile/presentation/shared/server_settings_modal.dart';
import '../platform/platform_harness.dart';

void main() {
  setUp(() {
    AppConfigStorage.clearForTesting();
  });

  group('ServerSettingsModal Widget Tests', () {
    testWidgets(
        'Opens from DemoLoginScreen, normalizes shorthand Wi-Fi IP, saves, and updates AppConfig',
        (tester) async {
      await tester.pumpWidget(
        createPlatformTestWidget(
          child: const DemoLoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final settingsBtn = find.byKey(const Key('demo_login_settings_button'));
      expect(settingsBtn, findsOneWidget);

      await tester.tap(settingsBtn);
      await tester.pumpAndSettle();

      expect(find.text('Server Connection Settings'), findsOneWidget);

      final urlInput = find.byKey(const Key('server_url_input'));
      expect(urlInput, findsOneWidget);

      // Enter MacBook local Wi-Fi IP shorthand
      await tester.enterText(urlInput, '192.168.1.42');
      await tester.pump();

      expect(
        find.text('Normalized URL: http://192.168.1.42:8080/api/v1'),
        findsOneWidget,
      );

      // Tap Save & Apply
      await tester.tap(find.byKey(const Key('save_base_url_button')));
      await tester.pumpAndSettle();

      // Modal should close and DemoLoginScreen button should reflect Custom state
      expect(find.text('Server Connection Settings'), findsNothing);
      expect(find.text('Server (Custom)'), findsOneWidget);
      expect(
        AppConfigStorage.getCustomBaseUrl(),
        equals('http://192.168.1.42:8080/api/v1'),
      );
    });

    testWidgets(
        'Displays validation error on invalid URL and supports Test Connection & Reset to Default',
        (tester) async {
      await tester.pumpWidget(
        createPlatformTestWidget(
          child: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => ServerSettingsModal.show(
                  context,
                  onTestConnection: (url) async => ConnectionTestResult(
                    isSuccess: true,
                    normalizedUrl: AppConfig.normalizeBaseUrl(url),
                    latencyMs: 12,
                    message: 'Connected to microservices gateway (12 ms)',
                  ),
                ),
                child: const Text('Open Settings'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      final urlInput = find.byKey(const Key('server_url_input'));

      // Enter invalid URL with spaces
      await tester.enterText(urlInput, 'http://bad host name');
      await tester.tap(find.byKey(const Key('save_base_url_button')));
      await tester.pump();

      expect(find.text('Server URL cannot contain spaces'), findsOneWidget);

      // Enter valid IP and tap Test Connection
      await tester.enterText(urlInput, '192.168.1.100');
      await tester.pump();
      await tester.tap(find.byKey(const Key('test_connection_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('connection_test_banner')), findsOneWidget);
      expect(
        find.text('Connected to microservices gateway (12 ms)'),
        findsOneWidget,
      );

      // Tap Reset to Default
      await tester.tap(find.byKey(const Key('reset_base_url_button')));
      await tester.pumpAndSettle();

      expect(AppConfigStorage.getCustomBaseUrl(), isNull);
    });

    testWidgets('Opens ServerSettingsModal from ResidentHeader in main portal',
        (tester) async {
      await tester.pumpWidget(
        createPlatformTestWidget(
          child: const FamilyPortalScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final headerSettingsBtn = find.byKey(const Key('header_settings_button'));
      expect(headerSettingsBtn, findsOneWidget);

      await tester.tap(headerSettingsBtn);
      await tester.pumpAndSettle();

      expect(find.text('Server Connection Settings'), findsOneWidget);
    });
  });
}
