import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elderly_mobile/presentation/auth/auth_provider.dart';

void main() {
  group('AuthNotifier Tests', () {
    test('Initial state is unauthenticated', () {
      final container = ProviderContainer();
      final state = container.read(authProvider);

      expect(state.isAuthenticated, isFalse);
      expect(state.user, isNull);
    });

    test('selectDemoProfile successfully authenticates Sarah Thompson', () async {
      final container = ProviderContainer();
      final notifier = container.read(authProvider.notifier);

      final success = await notifier.selectDemoProfile('user_sarah');

      expect(success, isTrue);
      final state = container.read(authProvider);
      expect(state.isAuthenticated, isTrue);
      expect(state.user?.username, equals('sarah.thompson'));
      expect(state.user?.relation, equals('Daughter'));
    });

    test('login with credentials succeeds for demo user', () async {
      final container = ProviderContainer();
      final notifier = container.read(authProvider.notifier);

      final success = await notifier.login('lisa.chen', 'anypassword');

      expect(success, isTrue);
      final state = container.read(authProvider);
      expect(state.isAuthenticated, isTrue);
      expect(state.user?.username, equals('lisa.chen'));
    });

    test('logout clears user profile', () async {
      final container = ProviderContainer();
      final notifier = container.read(authProvider.notifier);

      await notifier.selectDemoProfile('user_sarah');
      expect(container.read(authProvider).isAuthenticated, isTrue);

      await notifier.logout();
      expect(container.read(authProvider).isAuthenticated, isFalse);
      expect(container.read(authProvider).user, isNull);
    });
  });
}
