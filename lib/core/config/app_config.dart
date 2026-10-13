import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Persistent local storage for runtime server connection settings.
/// Uses Hive box `app_settings` on device and falls back to in-memory storage in test environments.
class AppConfigStorage {
  static const String _boxName = 'app_settings';
  static const String _customBaseUrlKey = 'custom_base_url';

  static String? _memoryCustomBaseUrl;

  /// Initializes Hive and opens the settings box prior to `runApp`.
  static Future<void> init() async {
    try {
      await Hive.initFlutter();
      final box = await Hive.openBox<dynamic>(_boxName);
      final saved = box.get(_customBaseUrlKey);
      if (saved is String && saved.trim().isNotEmpty) {
        _memoryCustomBaseUrl = AppConfig.normalizeBaseUrl(saved);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppConfigStorage] Hive init fallback to memory: $e');
      }
    }
  }

  /// Reads the currently persisted custom base URL override, if any.
  static String? getCustomBaseUrl() {
    try {
      if (Hive.isBoxOpen(_boxName)) {
        final box = Hive.box<dynamic>(_boxName);
        final val = box.get(_customBaseUrlKey);
        if (val is String && val.trim().isNotEmpty) {
          return val;
        }
        return _memoryCustomBaseUrl;
      }
    } catch (_) {}
    return _memoryCustomBaseUrl;
  }

  /// Persists or clears the custom base URL override on the device.
  static Future<void> saveCustomBaseUrl(String? url) async {
    final cleaned = (url != null && url.trim().isNotEmpty)
        ? AppConfig.normalizeBaseUrl(url)
        : null;
    _memoryCustomBaseUrl = cleaned;
    try {
      if (Hive.isBoxOpen(_boxName)) {
        final box = Hive.box<dynamic>(_boxName);
        if (cleaned == null) {
          await box.delete(_customBaseUrlKey);
        } else {
          await box.put(_customBaseUrlKey, cleaned);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppConfigStorage] Failed to persist custom base URL: $e');
      }
    }
  }

  /// Resets in-memory storage state for unit and widget tests.
  @visibleForTesting
  static void clearForTesting() {
    _memoryCustomBaseUrl = null;
  }
}

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
/// Values can be configured at compile time via `--dart-define` or dynamically switched at runtime.
class AppConfig {
  final AppEnvironment environment;
  final String apiBaseUrl;
  final String? customBaseUrl;
  final String authServiceUrl;
  final String careServiceUrl;
  final String aiServiceUrl;
  final String geminiApiKey;
  final bool useMockData;

  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    this.customBaseUrl,
    required this.authServiceUrl,
    required this.careServiceUrl,
    required this.aiServiceUrl,
    required this.geminiApiKey,
    required this.useMockData,
  });

  /// Whether a user-specified custom base URL override is currently active.
  bool get isCustomUrlActive =>
      customBaseUrl != null && customBaseUrl!.trim().isNotEmpty;

  /// The default platform base URL for the current environment (ignoring custom overrides).
  String get defaultBaseUrl => resolveDefaultBaseUrl(environment);

  /// Resolves the default base URL for local environment based on platform:
  /// - Android emulator routes to host machine via `http://10.0.2.2:8080/api/v1`
  /// - iOS Simulator / macOS / Web routes to host via `http://localhost:8080/api/v1`
  static String defaultLocalHostUrl() {
    if (kIsWeb) {
      return 'http://localhost:8080/api/v1';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://127.0.0.1:8080/api/v1';
      }
    } catch (_) {}
    return 'http://localhost:8080/api/v1';
  }

  /// Resolves the default base URL for a given environment before custom runtime overrides.
  static String resolveDefaultBaseUrl([AppEnvironment? env]) {
    const rawEnv = String.fromEnvironment('ENVIRONMENT', defaultValue: 'local');
    final activeEnv = env ?? AppEnvironment.fromString(rawEnv);
    const explicitBaseUrl =
        String.fromEnvironment('API_BASE_URL', defaultValue: '');

    if (explicitBaseUrl.isNotEmpty) {
      return normalizeBaseUrl(explicitBaseUrl);
    }
    switch (activeEnv) {
      case AppEnvironment.local:
        return defaultLocalHostUrl();
      case AppEnvironment.uat:
        return 'https://uat-api.kubocare.com/api/v1';
      case AppEnvironment.production:
        return 'https://api.kubocare.com/api/v1';
    }
  }

  /// Normalizes a user-provided URL or shorthand IP/hostname into a canonical base URL:
  /// - Prepends `http://` if no scheme is present
  /// - Defaults to port `:8080` for shorthand host/IP entries without an explicit port
  /// - Appends `/api/v1` if no path is provided
  /// - Removes trailing slashes
  static String normalizeBaseUrl(String rawInput) {
    final trimmed = rawInput.trim();
    if (trimmed.isEmpty) return '';

    final lower = trimmed.toLowerCase();
    final hasHttpScheme =
        lower.startsWith('http://') || lower.startsWith('https://');
    final hasAnyScheme = trimmed.contains('://');

    if (hasAnyScheme && !hasHttpScheme) {
      return trimmed;
    }

    final isShorthand = !hasHttpScheme;
    final candidate = isShorthand ? 'http://$trimmed' : trimmed;

    final uri = Uri.tryParse(candidate);
    if (uri == null || uri.host.isEmpty) {
      return trimmed;
    }

    final scheme = uri.scheme.toLowerCase();
    final host = uri.host;

    String portSegment = '';
    if (uri.hasPort) {
      if ((scheme == 'http' && uri.port != 80) ||
          (scheme == 'https' && uri.port != 443)) {
        portSegment = ':${uri.port}';
      }
    } else if (isShorthand) {
      portSegment = ':8080';
    }

    String cleanPath = uri.path.trim();
    while (cleanPath.endsWith('/')) {
      cleanPath = cleanPath.substring(0, cleanPath.length - 1);
    }
    if (cleanPath.isEmpty) {
      cleanPath = '/api/v1';
    } else if (!cleanPath.startsWith('/')) {
      cleanPath = '/$cleanPath';
    }

    return '$scheme://$host$portSegment$cleanPath';
  }

  /// Validates a user-provided base URL or shorthand IP/host.
  /// Returns `null` if valid, or a user-facing error message if invalid.
  static String? validateBaseUrl(String? rawInput) {
    if (rawInput == null || rawInput.trim().isEmpty) {
      return 'Please enter a server IP address or base URL';
    }

    final trimmed = rawInput.trim();
    if (trimmed.contains(' ')) {
      return 'Server URL cannot contain spaces';
    }

    final lower = trimmed.toLowerCase();
    final hasHttpScheme =
        lower.startsWith('http://') || lower.startsWith('https://');
    final hasAnyScheme = trimmed.contains('://');

    if (hasAnyScheme && !hasHttpScheme) {
      return 'URL must use http:// or https://';
    }

    final candidate = hasHttpScheme ? trimmed : 'http://$trimmed';
    final uri = Uri.tryParse(candidate);
    if (uri == null || !uri.hasAuthority || uri.host.isEmpty) {
      return 'Please enter a valid host or IP address (e.g. 192.168.1.50)';
    }

    final host = uri.host;
    final validHostPattern = RegExp(r'^[a-zA-Z0-9.-]+$');
    if (!validHostPattern.hasMatch(host) ||
        host.startsWith('.') ||
        host.endsWith('.') ||
        host.contains('..')) {
      return 'Invalid host or IP address format';
    }

    // If host looks like an IPv4 address (all numeric segments), validate 4 octets 0-255
    final ipv4Candidate = RegExp(r'^\d+(\.\d+)*$');
    if (ipv4Candidate.hasMatch(host)) {
      final parts = host.split('.');
      if (parts.length != 4) {
        return 'IPv4 address must have 4 numbers separated by dots (e.g. 192.168.1.50)';
      }
      for (final part in parts) {
        final octet = int.tryParse(part);
        if (octet == null || octet < 0 || octet > 255) {
          return 'Each IPv4 number must be between 0 and 255';
        }
      }
    }

    if (uri.hasPort && (uri.port <= 0 || uri.port > 65535)) {
      return 'Port must be between 1 and 65535';
    }

    return null;
  }

  /// Factory loading values from environment / compile-time definitions and persisted overrides
  factory AppConfig.fromEnvironment([
    AppEnvironment? overrideEnv,
    String? customBaseUrlOverride,
  ]) {
    const rawEnv = String.fromEnvironment('ENVIRONMENT', defaultValue: 'local');
    final activeEnv = overrideEnv ?? AppEnvironment.fromString(rawEnv);

    final persistedCustomUrl =
        customBaseUrlOverride ?? AppConfigStorage.getCustomBaseUrl();
    final hasCustom =
        persistedCustomUrl != null && persistedCustomUrl.trim().isNotEmpty;

    final resolvedBaseUrl = hasCustom
        ? normalizeBaseUrl(persistedCustomUrl)
        : resolveDefaultBaseUrl(activeEnv);

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
      customBaseUrl: hasCustom ? resolvedBaseUrl : null,
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
    String? customBaseUrl,
    bool clearCustomBaseUrl = false,
    String? authServiceUrl,
    String? careServiceUrl,
    String? aiServiceUrl,
    String? geminiApiKey,
    bool? useMockData,
  }) {
    return AppConfig(
      environment: environment ?? this.environment,
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      customBaseUrl:
          clearCustomBaseUrl ? null : (customBaseUrl ?? this.customBaseUrl),
      authServiceUrl: authServiceUrl ?? this.authServiceUrl,
      careServiceUrl: careServiceUrl ?? this.careServiceUrl,
      aiServiceUrl: aiServiceUrl ?? this.aiServiceUrl,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      useMockData: useMockData ?? this.useMockData,
    );
  }
}

/// Dynamic StateNotifier to allow changing environment and base URL at runtime
class AppConfigNotifier extends StateNotifier<AppConfig> {
  AppConfigNotifier([AppConfig? initialConfig])
      : super(initialConfig ?? AppConfig.fromEnvironment());

  void setEnvironment(AppEnvironment env, {String? customBaseUrl}) {
    if (customBaseUrl != null && customBaseUrl.trim().isNotEmpty) {
      final normalized = AppConfig.normalizeBaseUrl(customBaseUrl);
      AppConfigStorage.saveCustomBaseUrl(normalized);
      final newConfig = AppConfig.fromEnvironment(env, normalized);
      state = newConfig.copyWith(
        apiBaseUrl: normalized,
        customBaseUrl: normalized,
        authServiceUrl: normalized,
        careServiceUrl: normalized,
        aiServiceUrl: normalized,
      );
    } else {
      state = AppConfig.fromEnvironment(env);
    }
  }

  Future<void> setCustomBaseUrl(String url) async {
    final normalized = AppConfig.normalizeBaseUrl(url);
    await AppConfigStorage.saveCustomBaseUrl(normalized);
    state = state.copyWith(
      apiBaseUrl: normalized,
      customBaseUrl: normalized,
      authServiceUrl: normalized,
      careServiceUrl: normalized,
      aiServiceUrl: normalized,
    );
  }

  Future<void> resetBaseUrl() async {
    await AppConfigStorage.saveCustomBaseUrl(null);
    final defaultUrl = AppConfig.resolveDefaultBaseUrl(state.environment);
    state = state.copyWith(
      apiBaseUrl: defaultUrl,
      clearCustomBaseUrl: true,
      authServiceUrl: defaultUrl,
      careServiceUrl: defaultUrl,
      aiServiceUrl: defaultUrl,
    );
  }

  void setUseMockData(bool useMock) {
    state = state.copyWith(useMockData: useMock);
  }
}

/// Global Riverpod provider for application configuration
final appConfigProvider =
    StateNotifierProvider<AppConfigNotifier, AppConfig>((ref) {
  return AppConfigNotifier();
});
