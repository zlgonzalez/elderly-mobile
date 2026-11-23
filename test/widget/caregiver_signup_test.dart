import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:elderly_mobile/data/repositories/mock_auth_repository.dart';
import 'package:elderly_mobile/presentation/auth/auth_provider.dart';
import 'package:elderly_mobile/presentation/auth/caregiver_finalize_signup_screen.dart';
import 'package:elderly_mobile/presentation/auth/caregiver_signup_screen.dart';
import 'package:elderly_mobile/presentation/auth/login_screen.dart';

void main() {
  Widget buildTestApp({
    required MockAuthRepository authRepo,
    String initialLocation = '/login',
  }) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const CaregiverSignUpScreen(),
        ),
        GoRoute(
          path: '/signup/finalize',
          builder: (context, state) => CaregiverFinalizeSignUpScreen(
            initialEmail: state.uri.queryParameters['email'],
          ),
        ),
        GoRoute(
          path: '/portal',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Kubo Portal Reached')),
          ),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepo),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  testWidgets('US1 + US2: Caregiver navigates from Login to Sign Up, initiates email, finalizes with pre-filled editable username and password, and lands in /portal',
      (WidgetTester tester) async {
    final mockRepo = MockAuthRepository();
    await tester.pumpWidget(buildTestApp(authRepo: mockRepo));
    await tester.pumpAndSettle();

    // 1. Tap "Sign Up as Caregiver" on LoginScreen
    final signUpBtn = find.byKey(const Key('login_signup_button'));
    expect(signUpBtn, findsOneWidget);
    await tester.ensureVisible(signUpBtn);
    await tester.tap(signUpBtn);
    await tester.pumpAndSettle();

    // 2. Enter email and submit Step 1
    expect(find.byKey(const Key('signup_email_field')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('signup_email_field')),
      'clara.nurse@example.com',
    );
    await tester.tap(find.byKey(const Key('signup_submit_email_button')));
    await tester.pumpAndSettle();

    // Confirmation card appears with proceed button
    expect(find.byKey(const Key('signup_confirmation_card')), findsOneWidget);
    final proceedBtn = find.byKey(const Key('signup_proceed_to_finalize_button'));
    await tester.ensureVisible(proceedBtn);
    await tester.tap(proceedBtn);
    await tester.pumpAndSettle();

    // 3. Finalization screen has email pre-populated and editable username pre-filled with email prefix
    final emailField = tester.widget<TextFormField>(
      find.byKey(const Key('finalize_email_field')),
    );
    final usernameField = tester.widget<TextFormField>(
      find.byKey(const Key('finalize_username_field')),
    );
    expect(emailField.controller?.text, equals('clara.nurse@example.com'));
    expect(usernameField.controller?.text, equals('clara.nurse'));

    // Customize username, enter 6-digit code and matching password
    await tester.enterText(
      find.byKey(const Key('finalize_code_field')),
      '123456',
    );
    await tester.enterText(
      find.byKey(const Key('finalize_username_field')),
      'nurse_clara',
    );
    await tester.enterText(
      find.byKey(const Key('finalize_password_field')),
      'StrongPass123!',
    );
    await tester.enterText(
      find.byKey(const Key('finalize_confirm_password_field')),
      'StrongPass123!',
    );

    final submitBtn = find.byKey(const Key('finalize_submit_button'));
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    // 4. Auto-logged in and routed directly to /portal
    expect(find.text('Kubo Portal Reached'), findsOneWidget);
  });

  testWidgets('US3: Finalization screen shows error on invalid 6-digit code and supports resending verification email',
      (WidgetTester tester) async {
    final mockRepo = MockAuthRepository();
    await tester.runAsync(
      () => mockRepo.initiateCaregiverSignUp('retry.caregiver@example.com'),
    );

    await tester.pumpWidget(buildTestApp(
      authRepo: mockRepo,
      initialLocation: '/signup/finalize?email=retry.caregiver%40example.com',
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('finalize_code_field')), '999999');
    await tester.enterText(find.byKey(const Key('finalize_password_field')), 'StrongPass123!');
    await tester.enterText(find.byKey(const Key('finalize_confirm_password_field')), 'StrongPass123!');

    final submitBtn = find.byKey(const Key('finalize_submit_button'));
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('finalize_error_banner')), findsOneWidget);

    final resendBtn = find.byKey(const Key('finalize_resend_code_button'));
    await tester.ensureVisible(resendBtn);
    await tester.tap(resendBtn);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('finalize_info_banner')), findsOneWidget);
  });
}
