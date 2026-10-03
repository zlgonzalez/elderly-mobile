import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elderly_mobile/core/config/app_config.dart';

void main() {
  group('AppConfig Tests', () {
    test('Default configuration initializes with environment and base URL', () {
      final config = AppConfig.fromEnvironment();

      expect(config.apiBaseUrl, isNotEmpty);
      expect(config.environment, equals(AppEnvironment.local));
    });

    test('copyWith properly overrides selected configuration fields', () {
      const initial = AppConfig(
        apiBaseUrl: 'http://localhost:8080/api/v1',
        authServiceUrl: 'http://localhost:8080/api/v1',
        careServiceUrl: 'http://localhost:8080/api/v1',
        aiServiceUrl: 'http://localhost:8080/api/v1',
        geminiApiKey: '',
        useMockData: true,
        environment: AppEnvironment.local,
      );

      final updated = initial.copyWith(
        apiBaseUrl: 'https://api.kubocare.com/api/v1',
        useMockData: false,
        environment: AppEnvironment.production,
      );

      expect(updated.apiBaseUrl, equals('https://api.kubocare.com/api/v1'));
      expect(updated.useMockData, isFalse);
      expect(updated.environment, equals(AppEnvironment.production));
    });

    test('AppEnvironment fromString resolves known environments', () {
      expect(AppEnvironment.fromString('local'), equals(AppEnvironment.local));
      expect(AppEnvironment.fromString('dev'), equals(AppEnvironment.local));
      expect(AppEnvironment.fromString('uat'), equals(AppEnvironment.uat));
      expect(AppEnvironment.fromString('staging'), equals(AppEnvironment.uat));
      expect(AppEnvironment.fromString('prod'), equals(AppEnvironment.production));
      expect(AppEnvironment.fromString('production'), equals(AppEnvironment.production));
    });

    test('appConfigProvider yields configured AppConfig instance', () {
      final container = ProviderContainer();
      final config = container.read(appConfigProvider);
      expect(config.apiBaseUrl, isNotEmpty);
      expect(config.environment, equals(AppEnvironment.local));
    });
  });
}
