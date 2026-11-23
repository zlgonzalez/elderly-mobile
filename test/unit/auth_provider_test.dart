import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elderly_mobile/presentation/auth/auth_provider.dart';
import 'package:elderly_mobile/data/repositories/mock_auth_repository.dart';

void main() {
  group('AuthNotifier Tests', () {
    ProviderContainer createContainer() => ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(MockAuthRepository()),
          ],
        );

    test('Initial state is unauthenticated', () {
      final container = createContainer();
      final state = container.read(authProvider);

      expect(state.isAuthenticated, isFalse);
      expect(state.user, isNull);
    });

    test('selectDemoProfile successfully authenticates Sarah Thompson', () async {
      final container = createContainer();
      final notifier = container.read(authProvider.notifier);

      final success = await notifier.selectDemoProfile('user_sarah');

      expect(success, isTrue);
      final state = container.read(authProvider);
      expect(state.isAuthenticated, isTrue);
      expect(state.user?.username, equals('sarah.thompson'));
      expect(state.user?.relation, equals('Daughter'));
    });

    test('login with credentials succeeds for demo user', () async {
      final container = createContainer();
      final notifier = container.read(authProvider.notifier);

      final success = await notifier.login('lisa.chen', 'anypassword');

      expect(success, isTrue);
      final state = container.read(authProvider);
      expect(state.isAuthenticated, isTrue);
      expect(state.user?.username, equals('lisa.chen'));
    });

    test('logout clears user profile', () async {
      final container = createContainer();
      final notifier = container.read(authProvider.notifier);

      await notifier.selectDemoProfile('user_sarah');
      expect(container.read(authProvider).isAuthenticated, isTrue);

      await notifier.logout();
      expect(container.read(authProvider).isAuthenticated, isFalse);
      expect(container.read(authProvider).user, isNull);
    });

    test('caregiver sign-up initiation, resend, finalization, and subsequent username login succeed', () async {
      final container = createContainer();
      final notifier = container.read(authProvider.notifier);

      final initRes = await notifier.initiateCaregiverSignUp('jane.north@example.com');
      expect(initRes, isNotNull);
      expect(initRes!.email, equals('jane.north@example.com'));
      expect(initRes.finalizationLink, contains('/signup/finalize?email=jane.north%40example.com'));
      expect(container.read(authProvider).pendingSignUpEmail, equals('jane.north@example.com'));

      // Wrong 6-digit code fails
      final badFinal = await notifier.finalizeCaregiverSignUp(
        email: 'jane.north@example.com',
        code: '000000',
        username: 'nurse_jane_north',
        password: 'CaregiverPassword123!',
      );
      expect(badFinal, isFalse);
      expect(container.read(authProvider).isAuthenticated, isFalse);
      expect(container.read(authProvider).errorMessage, isNotNull);

      // Resend code succeeds
      final resendRes = await notifier.resendCaregiverSignUpCode('jane.north@example.com');
      expect(resendRes, isNotNull);
      expect(container.read(authProvider).infoMessage, contains('jane.north@example.com'));

      // Valid 6-digit code finalizes account and auto-logs in caregiver
      final finalized = await notifier.finalizeCaregiverSignUp(
        email: 'jane.north@example.com',
        code: '123456',
        username: 'nurse_jane_north',
        password: 'CaregiverPassword123!',
      );
      expect(finalized, isTrue);
      final state = container.read(authProvider);
      expect(state.isAuthenticated, isTrue);
      expect(state.user?.username, equals('nurse_jane_north'));
      expect(state.user?.relation, equals('Caregiver'));

      // Logout and sign back in with the newly established caregiver username + password
      await notifier.logout();
      final relogin = await notifier.login('nurse_jane_north', 'CaregiverPassword123!');
      expect(relogin, isTrue);
      expect(container.read(authProvider).user?.username, equals('nurse_jane_north'));
    });
  });
}
