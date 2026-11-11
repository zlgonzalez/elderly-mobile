import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:elderly_mobile/core/telemetry/config/telemetry_category.dart';
import 'package:elderly_mobile/core/telemetry/config/telemetry_config.dart';
import 'package:elderly_mobile/core/telemetry/config/telemetry_config_manager.dart';

void main() {
  group('TelemetryConfigManager Unit Tests', () {
    test('default config initializes with Crash and Business events enabled at 1.0', () {
      final manager = TelemetryConfigManager();
      final config = manager.currentConfig;

      expect(config.isCategoryEnabled(TelemetryCategory.crashAndExceptions), isTrue);
      expect(config.getSampleRate(TelemetryCategory.crashAndExceptions), equals(1.0));
      expect(config.isCategoryEnabled(TelemetryCategory.businessEvents), isTrue);
      expect(config.getSampleRate(TelemetryCategory.businessEvents), equals(1.0));

      // Network tracing enabled at 0.2
      expect(config.isCategoryEnabled(TelemetryCategory.networkTracing), isTrue);
      expect(config.getSampleRate(TelemetryCategory.networkTracing), equals(0.2));

      // UI and Local Data disabled by default and wifi_only
      expect(config.isCategoryEnabled(TelemetryCategory.uiInteractions), isFalse);
      expect(config.isWifiOnly(TelemetryCategory.uiInteractions), isTrue);
      expect(config.isCategoryEnabled(TelemetryCategory.localDataOps), isFalse);
      expect(config.isWifiOnly(TelemetryCategory.localDataOps), isTrue);
    });

    test('dynamic remote config updates notify stream and update values', () async {
      final manager = TelemetryConfigManager();
      final streamUpdates = <TelemetryConfig>[];
      final subscription = manager.onConfigChanged.listen(streamUpdates.add);

      manager.updateRemoteConfig({
        'batch_size': 75,
        'flush_interval_seconds': 45,
        'categories': {
          'UI_INTERACTIONS': {
            'enabled': true,
            'sample_rate': 0.5,
            'wifi_only': false,
          },
          'NETWORK_TRACING': {
            'enabled': false,
            'sample_rate': 0.0,
            'wifi_only': false,
          },
        },
      });

      await pumpEventQueue();

      expect(streamUpdates.length, equals(1));
      final updated = manager.currentConfig;
      expect(updated.batchSize, equals(75));
      expect(updated.flushInterval, equals(const Duration(seconds: 45)));
      expect(updated.isCategoryEnabled(TelemetryCategory.uiInteractions), isTrue);
      expect(updated.getSampleRate(TelemetryCategory.uiInteractions), equals(0.5));
      expect(updated.isCategoryEnabled(TelemetryCategory.networkTracing), isFalse);

      await subscription.cancel();
      manager.dispose();
    });

    test('sampling rate statistical distribution behaves within expected boundaries', () {
      final random = Random(42); // Seeded for reproducibility
      final manager = TelemetryConfigManager(random: random);

      // 1. When category is disabled -> shouldSample is always false
      expect(manager.shouldSample(TelemetryCategory.uiInteractions), isFalse);

      // 2. When sample rate is 1.0 -> shouldSample is always true
      for (int i = 0; i < 100; i++) {
        expect(manager.shouldSample(TelemetryCategory.crashAndExceptions), isTrue);
      }

      // 3. Enable UI interactions at 25% sampling rate
      manager.updateRemoteConfig({
        'categories': {
          'UI_INTERACTIONS': {
            'enabled': true,
            'sample_rate': 0.25,
          },
        },
      });

      int sampledCount = 0;
      const totalTrials = 10000;
      for (int i = 0; i < totalTrials; i++) {
        if (manager.shouldSample(TelemetryCategory.uiInteractions)) {
          sampledCount++;
        }
      }

      final sampledRatio = sampledCount / totalTrials;
      // Expect 0.25 +/- 0.02 (2% error tolerance as per SC-004)
      expect(sampledRatio, greaterThanOrEqualTo(0.23));
      expect(sampledRatio, lessThanOrEqualTo(0.27));
    });
  });
}
