import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elderly_mobile/core/config/app_config.dart';

void main() {
  group('AppConfig Tests', () {
    test('Default configuration initializes with mock data enabled', () {
      final config = AppConfig.fromEnvironment();

      expect(config.useMockData, isTrue);
      expect(config.apiBaseUrl, isNotEmpty);
      expect(config.environment, equals('dev'));
    });

    test('copyWith properly overrides selected configuration fields', () {
      const initial = AppConfig(
        apiBaseUrl: 'http://localhost:8080/api/v1',
        authServiceUrl: 'http://localhost:8081',
        careServiceUrl: 'http://localhost:8082',
        aiServiceUrl: 'http://localhost:8083',
        geminiApiKey: '',
        useMockData: true,
        environment: 'dev',
      );

      final updated = initial.copyWith(
        apiBaseUrl: 'https://api.kubonorth.org',
        useMockData: false,
        environment: 'prod',
      );

      expect(updated.apiBaseUrl, equals('https://api.kubonorth.org'));
      expect(updated.useMockData, isFalse);
      expect(updated.environment, equals('prod'));
      expect(updated.authServiceUrl, equals('http://localhost:8081'));
    });

    test('appConfigProvider yields configured AppConfig instance', () {
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(
              apiBaseUrl: 'http://test-server:9000/api',
              authServiceUrl: 'http://test-server:9001',
              careServiceUrl: 'http://test-server:9002',
              aiServiceUrl: 'http://test-server:9003',
              geminiApiKey: 'test-key',
              useMockData: false,
              environment: 'test',
            ),
          ),
        ],
      );

      final config = container.read(appConfigProvider);
      expect(config.apiBaseUrl, equals('http://test-server:9000/api'));
      expect(config.useMockData, isFalse);
      expect(config.geminiApiKey, equals('test-key'));
    });
  });
}
