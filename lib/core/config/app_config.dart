import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Centralized application configuration.
/// Values can be overridden at compile time via `--dart-define` or injected during testing.
class AppConfig {
  final String apiBaseUrl;
  final String authServiceUrl;
  final String careServiceUrl;
  final String aiServiceUrl;
  final String geminiApiKey;
  final bool useMockData;
  final String environment;

  const AppConfig({
    required this.apiBaseUrl,
    required this.authServiceUrl,
    required this.careServiceUrl,
    required this.aiServiceUrl,
    required this.geminiApiKey,
    required this.useMockData,
    required this.environment,
  });

  /// Factory loading values from environment / compile-time definitions
  factory AppConfig.fromEnvironment() {
    const apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:8080/api/v1',
    );
    const authServiceUrl = String.fromEnvironment(
      'AUTH_SERVICE_URL',
      defaultValue: 'http://localhost:8081',
    );
    const careServiceUrl = String.fromEnvironment(
      'CARE_SERVICE_URL',
      defaultValue: 'http://localhost:8082',
    );
    const aiServiceUrl = String.fromEnvironment(
      'AI_SERVICE_URL',
      defaultValue: 'http://localhost:8083',
    );
    const geminiApiKey = String.fromEnvironment(
      'VITE_GEMINI_API_KEY',
      defaultValue: String.fromEnvironment('GEMINI_API_KEY', defaultValue: ''),
    );
    const useMockData = bool.fromEnvironment(
      'USE_MOCK_DATA',
      defaultValue: true,
    );
    const environment = String.fromEnvironment(
      'ENVIRONMENT',
      defaultValue: 'dev',
    );

    return const AppConfig(
      apiBaseUrl: apiBaseUrl,
      authServiceUrl: authServiceUrl,
      careServiceUrl: careServiceUrl,
      aiServiceUrl: aiServiceUrl,
      geminiApiKey: geminiApiKey,
      useMockData: useMockData,
      environment: environment,
    );
  }

  AppConfig copyWith({
    String? apiBaseUrl,
    String? authServiceUrl,
    String? careServiceUrl,
    String? aiServiceUrl,
    String? geminiApiKey,
    bool? useMockData,
    String? environment,
  }) {
    return AppConfig(
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      authServiceUrl: authServiceUrl ?? this.authServiceUrl,
      careServiceUrl: careServiceUrl ?? this.careServiceUrl,
      aiServiceUrl: aiServiceUrl ?? this.aiServiceUrl,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      useMockData: useMockData ?? this.useMockData,
      environment: environment ?? this.environment,
    );
  }
}

/// Global Riverpod provider for application configuration
final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.fromEnvironment();
});
