import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Supported deployment environments
enum AppEnvironment {
  local,
  uat,
  production;

  static AppEnvironment fromString(String val) {
    switch (val.toLowerCase().trim()) {
      case 'uat':
      case 'staging':
        return AppEnvironment.uat;
      case 'prod':
      case 'production':
        return AppEnvironment.production;
      case 'local':
      case 'dev':
      case 'development':
      default:
        return AppEnvironment.local;
    }
  }

  String get displayName {
    switch (this) {
      case AppEnvironment.local:
        return 'Local Dev';
      case AppEnvironment.uat:
        return 'UAT / Staging';
      case AppEnvironment.production:
        return 'Production';
    }
  }
}

/// Centralized application configuration.
/// Values can be configured at compile time via `--dart-define` or dynamically switched.
class AppConfig {
  final AppEnvironment environment;
  final String apiBaseUrl;
  final String authServiceUrl;
  final String careServiceUrl;
  final String aiServiceUrl;
  final String geminiApiKey;
  final bool useMockData;

  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.authServiceUrl,
    required this.careServiceUrl,
    required this.aiServiceUrl,
    required this.geminiApiKey,
    required this.useMockData,
  });

  /// Resolves the default base URL for local environment based on platform:
  /// - Android emulator routes to host machine via `http://10.0.2.2:8080/api/v1`
  /// - iOS Simulator / macOS / Web routes to host via `http://localhost:8080/api/v1`
  static String defaultLocalHostUrl() {
    if (kIsWeb) {
      return 'http://localhost:8080/api/v1';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8080/api/v1';
      }
    } catch (_) {}
    return 'http://localhost:8080/api/v1';
  }

  /// Factory loading values from environment / compile-time definitions
  factory AppConfig.fromEnvironment([AppEnvironment? overrideEnv]) {
    const rawEnv = String.fromEnvironment('ENVIRONMENT', defaultValue: 'local');
    final activeEnv = overrideEnv ?? AppEnvironment.fromString(rawEnv);

    // Explicit override from --dart-define=API_BASE_URL=...
    const explicitBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');

    String resolvedBaseUrl;
    if (explicitBaseUrl.isNotEmpty) {
      resolvedBaseUrl = explicitBaseUrl;
    } else {
      switch (activeEnv) {
        case AppEnvironment.local:
          resolvedBaseUrl = defaultLocalHostUrl();
          break;
        case AppEnvironment.uat:
          resolvedBaseUrl = 'https://uat-api.kubocare.com/api/v1';
          break;
        case AppEnvironment.production:
          resolvedBaseUrl = 'https://api.kubocare.com/api/v1';
          break;
      }
    }

    const geminiApiKey = String.fromEnvironment(
      'VITE_GEMINI_API_KEY',
      defaultValue: String.fromEnvironment('GEMINI_API_KEY', defaultValue: ''),
    );

    const useMockData = bool.fromEnvironment(
      'USE_MOCK_DATA',
      defaultValue: false,
    );

    return AppConfig(
      environment: activeEnv,
      apiBaseUrl: resolvedBaseUrl,
      authServiceUrl: resolvedBaseUrl,
      careServiceUrl: resolvedBaseUrl,
      aiServiceUrl: resolvedBaseUrl,
      geminiApiKey: geminiApiKey,
      useMockData: useMockData,
    );
  }

  AppConfig copyWith({
    AppEnvironment? environment,
    String? apiBaseUrl,
    String? authServiceUrl,
    String? careServiceUrl,
    String? aiServiceUrl,
    String? geminiApiKey,
    bool? useMockData,
  }) {
    return AppConfig(
      environment: environment ?? this.environment,
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      authServiceUrl: authServiceUrl ?? this.authServiceUrl,
      careServiceUrl: careServiceUrl ?? this.careServiceUrl,
      aiServiceUrl: aiServiceUrl ?? this.aiServiceUrl,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      useMockData: useMockData ?? this.useMockData,
    );
  }
}

/// Dynamic StateNotifier to allow changing environment at runtime (e.g. for testing/QA)
class AppConfigNotifier extends StateNotifier<AppConfig> {
  AppConfigNotifier() : super(AppConfig.fromEnvironment());

  void setEnvironment(AppEnvironment env, {String? customBaseUrl}) {
    final newConfig = AppConfig.fromEnvironment(env);
    if (customBaseUrl != null && customBaseUrl.isNotEmpty) {
      state = newConfig.copyWith(apiBaseUrl: customBaseUrl);
    } else {
      state = newConfig;
    }
  }

  void setCustomBaseUrl(String url) {
    state = state.copyWith(apiBaseUrl: url);
  }

  void setUseMockData(bool useMock) {
    state = state.copyWith(useMockData: useMock);
  }
}

/// Global Riverpod provider for application configuration
final appConfigProvider = StateNotifierProvider<AppConfigNotifier, AppConfig>((ref) {
  return AppConfigNotifier();
});
