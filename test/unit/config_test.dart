import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elderly_mobile/core/config/app_config.dart';
import 'package:elderly_mobile/core/network/api_client.dart';
import 'package:elderly_mobile/presentation/auth/auth_provider.dart';
import 'package:elderly_mobile/data/repositories/resident_repository.dart';
import 'package:elderly_mobile/data/repositories/care_tasks_repository.dart';
import 'package:elderly_mobile/data/repositories/health_vitals_repository.dart';
import 'package:elderly_mobile/data/repositories/meal_repository.dart';
import 'package:elderly_mobile/data/repositories/mood_repository.dart';
import 'package:elderly_mobile/data/repositories/memory_repository.dart';
import 'package:elderly_mobile/data/repositories/montessori_repository.dart';
import 'package:elderly_mobile/data/repositories/ai_assistant_repository.dart';

void main() {
  setUp(() {
    AppConfigStorage.clearForTesting();
  });

  group('AppConfig Tests', () {
    test('Default configuration initializes with environment and base URL', () {
      final config = AppConfig.fromEnvironment();

      expect(config.apiBaseUrl, isNotEmpty);
      expect(config.environment, equals(AppEnvironment.local));
      expect(config.isCustomUrlActive, isFalse);
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
      expect(AppEnvironment.fromString('prod'),
          equals(AppEnvironment.production));
      expect(AppEnvironment.fromString('production'),
          equals(AppEnvironment.production));
    });

    test('appConfigProvider yields configured AppConfig instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final config = container.read(appConfigProvider);
      expect(config.apiBaseUrl, isNotEmpty);
      expect(config.environment, equals(AppEnvironment.local));
    });

    test('normalizeBaseUrl expands shorthand IP/host and trims trailing slashes',
        () {
      expect(
        AppConfig.normalizeBaseUrl('192.168.1.50'),
        equals('http://192.168.1.50:8080/api/v1'),
      );
      expect(
        AppConfig.normalizeBaseUrl('192.168.1.50:9090'),
        equals('http://192.168.1.50:9090/api/v1'),
      );
      expect(
        AppConfig.normalizeBaseUrl('http://192.168.1.50:8080/api/v1/'),
        equals('http://192.168.1.50:8080/api/v1'),
      );
      expect(
        AppConfig.normalizeBaseUrl('http://192.168.1.50:8080'),
        equals('http://192.168.1.50:8080/api/v1'),
      );
      expect(
        AppConfig.normalizeBaseUrl('https://uat-api.kubocare.com/api/v1/'),
        equals('https://uat-api.kubocare.com/api/v1'),
      );
    });

    test('validateBaseUrl accepts valid URLs/IPs and rejects malformed inputs',
        () {
      expect(AppConfig.validateBaseUrl('192.168.1.50'), isNull);
      expect(AppConfig.validateBaseUrl('192.168.1.50:8080'), isNull);
      expect(
          AppConfig.validateBaseUrl('http://192.168.1.50:8080/api/v1'), isNull);
      expect(AppConfig.validateBaseUrl('macbook-pro.local'), isNull);

      expect(AppConfig.validateBaseUrl(''), isNotNull);
      expect(AppConfig.validateBaseUrl('   '), isNotNull);
      expect(AppConfig.validateBaseUrl('http://bad host'), isNotNull);
      expect(AppConfig.validateBaseUrl('ftp://192.168.1.50'), isNotNull);
      expect(AppConfig.validateBaseUrl('192.168.1'), isNotNull);
      expect(AppConfig.validateBaseUrl('192.168.1.999'), isNotNull);
    });

    test(
        'setCustomBaseUrl persists, synchronizes all service URLs, preserves auth token, and propagates to all 9 microservice repositories',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Set an auth token on the initial ApiClient
      container.read(apiClientProvider).setAuthToken('jwt-test-token');
      addTearDown(() => container.read(apiClientProvider).clearAuthToken());

      // Capture initial repository instances
      final initialAuthRepo = container.read(authRepositoryProvider);
      final initialResidentRepo = container.read(residentRepositoryProvider);
      final initialCareRepo = container.read(careTasksRepositoryProvider);
      final initialVitalsRepo = container.read(healthVitalsRepositoryProvider);
      final initialMealRepo = container.read(mealRepositoryProvider);
      final initialMoodRepo = container.read(moodRepositoryProvider);
      final initialMemoryRepo = container.read(memoryRepositoryProvider);
      final initialMontessoriRepo =
          container.read(montessoriRepositoryProvider);
      final initialAiRepo = container.read(aiAssistantRepositoryProvider);

      // Update base URL using shorthand MacBook Wi-Fi IP
      await container
          .read(appConfigProvider.notifier)
          .setCustomBaseUrl('192.168.1.77');

      final updatedConfig = container.read(appConfigProvider);
      const expectedUrl = 'http://192.168.1.77:8080/api/v1';

      expect(updatedConfig.isCustomUrlActive, isTrue);
      expect(updatedConfig.apiBaseUrl, equals(expectedUrl));
      expect(updatedConfig.authServiceUrl, equals(expectedUrl));
      expect(updatedConfig.careServiceUrl, equals(expectedUrl));
      expect(updatedConfig.aiServiceUrl, equals(expectedUrl));
      expect(AppConfigStorage.getCustomBaseUrl(), equals(expectedUrl));

      // Verify new container restores persisted URL on startup
      final restartedContainer = ProviderContainer();
      addTearDown(restartedContainer.dispose);
      expect(restartedContainer.read(appConfigProvider).apiBaseUrl,
          equals(expectedUrl));

      // Verify ApiClient updated baseUrl, media resolution, and preserved auth token
      final updatedClient = container.read(apiClientProvider);
      expect(updatedClient.baseUrl, equals(expectedUrl));
      expect(updatedClient.authToken, equals('jwt-test-token'));
      expect(
        updatedClient.resolveMediaUrl('/uploads/avatar.png'),
        equals('http://192.168.1.77:8080/uploads/avatar.png'),
      );

      // Verify all 9 microservice repositories rebuilt with the new ApiClient
      expect(
          identical(container.read(authRepositoryProvider), initialAuthRepo),
          isFalse);
      expect(
          identical(
              container.read(residentRepositoryProvider), initialResidentRepo),
          isFalse);
      expect(
          identical(
              container.read(careTasksRepositoryProvider), initialCareRepo),
          isFalse);
      expect(
          identical(container.read(healthVitalsRepositoryProvider),
              initialVitalsRepo),
          isFalse);
      expect(identical(container.read(mealRepositoryProvider), initialMealRepo),
          isFalse);
      expect(identical(container.read(moodRepositoryProvider), initialMoodRepo),
          isFalse);
      expect(
          identical(
              container.read(memoryRepositoryProvider), initialMemoryRepo),
          isFalse);
      expect(
          identical(container.read(montessoriRepositoryProvider),
              initialMontessoriRepo),
          isFalse);
      expect(
          identical(
              container.read(aiAssistantRepositoryProvider), initialAiRepo),
          isFalse);

      // Verify resetBaseUrl restores default URL and clears custom override
      await container.read(appConfigProvider.notifier).resetBaseUrl();
      final resetConfig = container.read(appConfigProvider);
      expect(resetConfig.isCustomUrlActive, isFalse);
      expect(resetConfig.apiBaseUrl, equals(resetConfig.defaultBaseUrl));
      expect(AppConfigStorage.getCustomBaseUrl(), isNull);
    });
  });
}
