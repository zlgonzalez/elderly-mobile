import 'dart:async';
import 'dart:math';
import 'telemetry_category.dart';
import 'telemetry_config.dart';

abstract class ITelemetryConfigManager {
  TelemetryConfig get currentConfig;
  Stream<TelemetryConfig> get onConfigChanged;
  void updateRemoteConfig(Map<String, dynamic> remoteJson);
  void applyDebugOverride(
    TelemetryCategory category, {
    bool? enabled,
    double? sampleRate,
    bool? wifiOnly,
  });
  void clearDebugOverrides();
  bool shouldSample(TelemetryCategory category);
}

class TelemetryConfigManager implements ITelemetryConfigManager {
  TelemetryConfig _baseConfig;
  final Map<TelemetryCategory, CategoryConfig> _debugOverrides = {};
  final StreamController<TelemetryConfig> _configStreamController =
      StreamController<TelemetryConfig>.broadcast();
  final Random _random;

  TelemetryConfigManager({
    TelemetryConfig? initialConfig,
    Random? random,
  })  : _baseConfig = initialConfig ?? TelemetryConfig.defaultConfig(),
        _random = random ?? Random();

  @override
  TelemetryConfig get currentConfig {
    if (_debugOverrides.isEmpty) {
      return _baseConfig;
    }

    final mergedCategories = Map<TelemetryCategory, CategoryConfig>.from(
      _baseConfig.categories,
    );

    for (final entry in _debugOverrides.entries) {
      mergedCategories[entry.key] = entry.value;
    }

    return TelemetryConfig(
      categories: mergedCategories,
      batchSize: _baseConfig.batchSize,
      flushInterval: _baseConfig.flushInterval,
      maxLocalBufferBytes: _baseConfig.maxLocalBufferBytes,
    );
  }

  @override
  Stream<TelemetryConfig> get onConfigChanged => _configStreamController.stream;

  @override
  void updateRemoteConfig(Map<String, dynamic> remoteJson) {
    try {
      _baseConfig = TelemetryConfig.fromJson(remoteJson);
      _configStreamController.add(currentConfig);
    } catch (_) {
      // Retain existing configuration if remote payload is malformed
    }
  }

  @override
  void applyDebugOverride(
    TelemetryCategory category, {
    bool? enabled,
    double? sampleRate,
    bool? wifiOnly,
  }) {
    final existing =
        _debugOverrides[category] ??
        _baseConfig.categories[category] ??
        const CategoryConfig(enabled: true, sampleRate: 1.0);

    _debugOverrides[category] = existing.copyWith(
      enabled: enabled,
      sampleRate: sampleRate,
      wifiOnly: wifiOnly,
    );

    _configStreamController.add(currentConfig);
  }

  @override
  void clearDebugOverrides() {
    _debugOverrides.clear();
    _configStreamController.add(currentConfig);
  }

  @override
  bool shouldSample(TelemetryCategory category) {
    final config = currentConfig.categories[category];
    if (config == null || !config.enabled) {
      return false;
    }

    if (config.sampleRate >= 1.0) {
      return true;
    }

    if (config.sampleRate <= 0.0) {
      return false;
    }

    return _random.nextDouble() <= config.sampleRate;
  }

  void dispose() {
    _configStreamController.close();
  }
}
