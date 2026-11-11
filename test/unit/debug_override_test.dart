import 'package:flutter_test/flutter_test.dart';
import 'package:elderly_mobile/core/telemetry/config/telemetry_category.dart';
import 'package:elderly_mobile/core/telemetry/config/telemetry_config_manager.dart';

void main() {
  group('Telemetry Debug Override Tests', () {
    test('local debug override takes immediate precedence over remote config', () {
      final manager = TelemetryConfigManager();

      // Initially disabled by default
      expect(manager.currentConfig.isCategoryEnabled(TelemetryCategory.uiInteractions), isFalse);

      // Apply debug override: force UI interactions enabled at 1.0
      manager.applyDebugOverride(
        TelemetryCategory.uiInteractions,
        enabled: true,
        sampleRate: 1.0,
      );

      expect(manager.currentConfig.isCategoryEnabled(TelemetryCategory.uiInteractions), isTrue);
      expect(manager.currentConfig.getSampleRate(TelemetryCategory.uiInteractions), equals(1.0));
      expect(manager.shouldSample(TelemetryCategory.uiInteractions), isTrue);

      // Now simulate incoming remote config trying to disable UI interactions
      manager.updateRemoteConfig({
        'categories': {
          'UI_INTERACTIONS': {
            'enabled': false,
            'sample_rate': 0.0,
          },
        },
      });

      // The local debug override must still take precedence!
      expect(manager.currentConfig.isCategoryEnabled(TelemetryCategory.uiInteractions), isTrue);
      expect(manager.currentConfig.getSampleRate(TelemetryCategory.uiInteractions), equals(1.0));

      // Clear debug overrides
      manager.clearDebugOverrides();

      // Now the remote config takes over
      expect(manager.currentConfig.isCategoryEnabled(TelemetryCategory.uiInteractions), isFalse);
    });
  });
}
