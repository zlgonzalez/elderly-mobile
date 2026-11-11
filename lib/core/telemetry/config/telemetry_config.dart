import 'telemetry_category.dart';

class CategoryConfig {
  final bool enabled;
  final double sampleRate; // 0.0 to 1.0
  final bool wifiOnly;

  const CategoryConfig({
    required this.enabled,
    required this.sampleRate,
    this.wifiOnly = false,
  });

  factory CategoryConfig.fromJson(Map<String, dynamic> json) {
    return CategoryConfig(
      enabled: json['enabled'] as bool? ?? false,
      sampleRate: ((json['sample_rate'] as num?)?.toDouble() ?? 1.0)
          .clamp(0.0, 1.0),
      wifiOnly: json['wifi_only'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'sample_rate': sampleRate,
    'wifi_only': wifiOnly,
  };

  CategoryConfig copyWith({
    bool? enabled,
    double? sampleRate,
    bool? wifiOnly,
  }) {
    return CategoryConfig(
      enabled: enabled ?? this.enabled,
      sampleRate: (sampleRate ?? this.sampleRate).clamp(0.0, 1.0),
      wifiOnly: wifiOnly ?? this.wifiOnly,
    );
  }
}

class TelemetryConfig {
  final Map<TelemetryCategory, CategoryConfig> categories;
  final int batchSize;
  final Duration flushInterval;
  final int maxLocalBufferBytes;

  const TelemetryConfig({
    required this.categories,
    this.batchSize = 50,
    this.flushInterval = const Duration(seconds: 30),
    this.maxLocalBufferBytes = 5 * 1024 * 1024, // 5 MB hard limit
  });

  factory TelemetryConfig.defaultConfig() {
    return TelemetryConfig(
      categories: {
        TelemetryCategory.crashAndExceptions: const CategoryConfig(
          enabled: true,
          sampleRate: 1.0,
          wifiOnly: false,
        ),
        TelemetryCategory.businessEvents: const CategoryConfig(
          enabled: true,
          sampleRate: 1.0,
          wifiOnly: false,
        ),
        TelemetryCategory.networkTracing: const CategoryConfig(
          enabled: true,
          sampleRate: 0.2,
          wifiOnly: false,
        ),
        TelemetryCategory.localDataOps: const CategoryConfig(
          enabled: false,
          sampleRate: 0.1,
          wifiOnly: true,
        ),
        TelemetryCategory.uiInteractions: const CategoryConfig(
          enabled: false,
          sampleRate: 0.1,
          wifiOnly: true,
        ),
      },
    );
  }

  factory TelemetryConfig.fromJson(Map<String, dynamic> json) {
    final defaultCfg = TelemetryConfig.defaultConfig();
    final categoriesMap = Map<TelemetryCategory, CategoryConfig>.from(
      defaultCfg.categories,
    );

    if (json['categories'] is Map<String, dynamic>) {
      final rawCat = json['categories'] as Map<String, dynamic>;
      for (final entry in rawCat.entries) {
        final cat = TelemetryCategory.values.firstWhere(
          (c) => c.value == entry.key,
          orElse: () => TelemetryCategory.businessEvents,
        );
        if (entry.value is Map<String, dynamic>) {
          categoriesMap[cat] = CategoryConfig.fromJson(
            entry.value as Map<String, dynamic>,
          );
        }
      }
    }

    return TelemetryConfig(
      categories: categoriesMap,
      batchSize: json['batch_size'] as int? ?? defaultCfg.batchSize,
      flushInterval: Duration(
        seconds: json['flush_interval_seconds'] as int? ?? 30,
      ),
      maxLocalBufferBytes:
          json['max_local_buffer_bytes'] as int? ??
          defaultCfg.maxLocalBufferBytes,
    );
  }

  bool isCategoryEnabled(TelemetryCategory category) {
    return categories[category]?.enabled ?? false;
  }

  double getSampleRate(TelemetryCategory category) {
    return categories[category]?.sampleRate ?? 0.0;
  }

  bool isWifiOnly(TelemetryCategory category) {
    return categories[category]?.wifiOnly ?? false;
  }
}
