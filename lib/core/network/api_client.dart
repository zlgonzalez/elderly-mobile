import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// Result of probing a candidate microservices base URL from the Settings panel.
class ConnectionTestResult {
  final bool isSuccess;
  final String normalizedUrl;
  final String message;
  final int? latencyMs;

  const ConnectionTestResult({
    required this.isSuccess,
    required this.normalizedUrl,
    required this.message,
    this.latencyMs,
  });
}

/// Central HTTP Client for backend microservices.
/// Provides standardized authentication headers, JSON encoding/decoding, and error handling.
class ApiClient {
  /// Shared session state preserved across base URL updates so signed-in users remain authenticated.
  static String? _sharedAuthToken;
  static String? _sharedInstitutionId = '00000000-0000-0000-0000-000000000001';
  static String? _resolvedLocalBaseUrl;

  final String baseUrl;
  String? _authToken;
  String? _activeInstitutionId;
  final Duration requestTimeout;
  final http.Client? _httpClient;

  ApiClient({
    required this.baseUrl,
    String? initialAuthToken,
    String? initialInstitutionId,
    this.requestTimeout = const Duration(seconds: 4),
    http.Client? httpClient,
  })  : _authToken = initialAuthToken ?? _sharedAuthToken,
        _activeInstitutionId = initialInstitutionId ?? _sharedInstitutionId,
        _httpClient = httpClient;

  String? get authToken => _authToken;
  String? get activeInstitutionId => _activeInstitutionId;
  String get _effectiveBaseUrl =>
      ((baseUrl == 'http://127.0.0.1:8080/api/v1' ||
                  baseUrl == 'http://10.0.2.2:8080/api/v1') &&
              _resolvedLocalBaseUrl != null)
          ? _resolvedLocalBaseUrl!
          : baseUrl;

  void setAuthToken(String token) {
    _authToken = token;
    _sharedAuthToken = token;
  }

  void clearAuthToken() {
    _authToken = null;
    _sharedAuthToken = null;
  }

  void setActiveInstitutionId(String? institutionId) {
    _activeInstitutionId = institutionId;
    _sharedInstitutionId = institutionId;
  }

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    if (_activeInstitutionId != null && _activeInstitutionId!.isNotEmpty) {
      headers['X-Institution-ID'] = _activeInstitutionId!;
    }
    return headers;
  }

  String resolveMediaUrl(String? pathOrUrl) {
    if (pathOrUrl == null || pathOrUrl.isEmpty) {
      return '';
    }
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return pathOrUrl;
    }
    if (pathOrUrl.startsWith('assets/')) {
      return pathOrUrl;
    }
    try {
      final baseUri = Uri.parse(_effectiveBaseUrl);
      final cleanPath = pathOrUrl.startsWith('/') ? pathOrUrl : '/$pathOrUrl';
      final portSuffix =
          (baseUri.hasPort && baseUri.port != 80 && baseUri.port != 443)
              ? ':${baseUri.port}'
              : '';
      return '${baseUri.scheme}://${baseUri.host}$portSuffix$cleanPath';
    } catch (_) {
      return pathOrUrl;
    }
  }

  Uri _buildUri(String endpoint,
      [Map<String, dynamic>? queryParameters, String? overrideBaseUrl]) {
    final targetBase = overrideBaseUrl ?? _effectiveBaseUrl;
    final cleanBase = targetBase.endsWith('/')
        ? targetBase.substring(0, targetBase.length - 1)
        : targetBase;
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final fullUrl = '$cleanBase$cleanEndpoint';
    final uri = Uri.parse(fullUrl);
    if (queryParameters != null && queryParameters.isNotEmpty) {
      final stringParams =
          queryParameters.map((k, v) => MapEntry(k, v.toString()));
      return uri.replace(queryParameters: {
        ...uri.queryParameters,
        ...stringParams,
      });
    }
    return uri;
  }

  List<String> _candidateFallbackBases() {
    const candidates = <String>[
      'http://127.0.0.1:8080/api/v1',
      'http://10.0.2.2:8080/api/v1',
      'http://localhost:8080/api/v1',
    ];
    return candidates.where((c) => c != _effectiveBaseUrl).toList();
  }

  /// Tests reachability of a candidate base URL (or this client's `baseUrl`)
  /// by sending a GET request to `/auth/demo-accounts` within the request timeout.
  Future<ConnectionTestResult> testConnection([String? candidateBaseUrl]) async {
    final rawTarget = candidateBaseUrl ?? baseUrl;
    final validationError = AppConfig.validateBaseUrl(rawTarget);
    if (validationError != null) {
      return ConnectionTestResult(
        isSuccess: false,
        normalizedUrl: rawTarget.trim(),
        message: validationError,
      );
    }

    final normalized = AppConfig.normalizeBaseUrl(rawTarget);
    final probeUri = Uri.parse('$normalized/auth/demo-accounts');
    final stopwatch = Stopwatch()..start();

    try {
      final response = _httpClient != null
          ? await _httpClient
              .get(probeUri, headers: _headers)
              .timeout(requestTimeout)
          : await http
              .get(probeUri, headers: _headers)
              .timeout(requestTimeout);
      stopwatch.stop();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ConnectionTestResult(
          isSuccess: true,
          normalizedUrl: normalized,
          latencyMs: stopwatch.elapsedMilliseconds,
          message:
              'Connected to microservices gateway (${stopwatch.elapsedMilliseconds} ms)',
        );
      } else {
        return ConnectionTestResult(
          isSuccess: false,
          normalizedUrl: normalized,
          latencyMs: stopwatch.elapsedMilliseconds,
          message:
              'Server responded with HTTP ${response.statusCode} at $normalized',
        );
      }
    } catch (e) {
      stopwatch.stop();
      return ConnectionTestResult(
        isSuccess: false,
        normalizedUrl: normalized,
        message:
            'Unable to reach server at $normalized. Verify both devices are on the same Wi-Fi and microservices are running.',
      );
    }
  }

  Future<dynamic> get(String endpoint,
      {Map<String, dynamic>? queryParameters}) async {
    final uri = _buildUri(endpoint, queryParameters);
    if (kDebugMode) {
      debugPrint(
          '[ApiClient] GET $uri (token: ${_authToken != null ? "yes" : "no"})');
    }
    try {
      final response = _httpClient != null
          ? await _httpClient
              .get(uri, headers: _headers)
              .timeout(requestTimeout)
          : await http.get(uri, headers: _headers).timeout(requestTimeout);
      return _handleResponse(response);
    } catch (e) {
      if (_httpClient == null && e is! ApiException) {
        for (final fallbackBase in _candidateFallbackBases()) {
          try {
            final fallbackUri =
                _buildUri(endpoint, queryParameters, fallbackBase);
            final response = await http
                .get(fallbackUri, headers: _headers)
                .timeout(const Duration(seconds: 2));
            _resolvedLocalBaseUrl = fallbackBase;
            return _handleResponse(response);
          } catch (_) {}
        }
      }
      if (kDebugMode) {
        debugPrint('[ApiClient] GET $uri failed: $e');
      }
      rethrow;
    }
  }

  Future<dynamic> post(String endpoint,
      {dynamic body, Map<String, dynamic>? queryParameters}) async {
    final uri = _buildUri(endpoint, queryParameters);
    if (kDebugMode) {
      debugPrint('[ApiClient] POST $uri (body: $body)');
    }
    final encodedBody = body != null ? jsonEncode(body) : null;
    try {
      final response = _httpClient != null
          ? await _httpClient
              .post(uri, headers: _headers, body: encodedBody)
              .timeout(requestTimeout)
          : await http
              .post(uri, headers: _headers, body: encodedBody)
              .timeout(requestTimeout);
      return _handleResponse(response);
    } catch (e) {
      if (_httpClient == null && e is! ApiException) {
        for (final fallbackBase in _candidateFallbackBases()) {
          try {
            final fallbackUri =
                _buildUri(endpoint, queryParameters, fallbackBase);
            final response = await http
                .post(fallbackUri, headers: _headers, body: encodedBody)
                .timeout(const Duration(seconds: 2));
            _resolvedLocalBaseUrl = fallbackBase;
            return _handleResponse(response);
          } catch (_) {}
        }
      }
      if (kDebugMode) {
        debugPrint('[ApiClient] POST $uri failed: $e');
      }
      rethrow;
    }
  }

  Future<dynamic> patch(String endpoint,
      {dynamic body, Map<String, dynamic>? queryParameters}) async {
    final uri = _buildUri(endpoint, queryParameters);
    if (kDebugMode) {
      debugPrint('[ApiClient] PATCH $uri (body: $body)');
    }
    final encodedBody = body != null ? jsonEncode(body) : null;
    try {
      final response = _httpClient != null
          ? await _httpClient
              .patch(uri, headers: _headers, body: encodedBody)
              .timeout(requestTimeout)
          : await http
              .patch(uri, headers: _headers, body: encodedBody)
              .timeout(requestTimeout);
      return _handleResponse(response);
    } catch (e) {
      if (_httpClient == null && e is! ApiException) {
        for (final fallbackBase in _candidateFallbackBases()) {
          try {
            final fallbackUri =
                _buildUri(endpoint, queryParameters, fallbackBase);
            final response = await http
                .patch(fallbackUri, headers: _headers, body: encodedBody)
                .timeout(const Duration(seconds: 2));
            _resolvedLocalBaseUrl = fallbackBase;
            return _handleResponse(response);
          } catch (_) {}
        }
      }
      if (kDebugMode) {
        debugPrint('[ApiClient] PATCH $uri failed: $e');
      }
      rethrow;
    }
  }

  Future<dynamic> put(String endpoint,
      {dynamic body, Map<String, dynamic>? queryParameters}) async {
    final uri = _buildUri(endpoint, queryParameters);
    if (kDebugMode) {
      debugPrint('[ApiClient] PUT $uri (body: $body)');
    }
    try {
      final encodedBody = body != null ? jsonEncode(body) : null;
      final response = _httpClient != null
          ? await _httpClient
              .put(uri, headers: _headers, body: encodedBody)
              .timeout(requestTimeout)
          : await http
              .put(uri, headers: _headers, body: encodedBody)
              .timeout(requestTimeout);
      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ApiClient] PUT $uri failed: $e');
      }
      rethrow;
    }
  }

  Future<dynamic> delete(String endpoint,
      {Map<String, dynamic>? queryParameters}) async {
    final uri = _buildUri(endpoint, queryParameters);
    if (kDebugMode) {
      debugPrint('[ApiClient] DELETE $uri');
    }
    try {
      final response = _httpClient != null
          ? await _httpClient
              .delete(uri, headers: _headers)
              .timeout(requestTimeout)
          : await http.delete(uri, headers: _headers).timeout(requestTimeout);
      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ApiClient] DELETE $uri failed: $e');
      }
      rethrow;
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        return jsonDecode(response.body);
      }
      return null;
    } else {
      String message = 'HTTP ${response.statusCode}';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          message = decoded['error'] ?? decoded['message'] ?? response.body;
        }
      } catch (_) {
        message = response.body.isNotEmpty
            ? response.body
            : 'HTTP ${response.statusCode}';
      }
      throw ApiException(
        statusCode: response.statusCode,
        message: message,
      );
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException: $statusCode ($message)';
}

/// Riverpod provider for ApiClient configured with AppConfig.apiBaseUrl
final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(appConfigProvider);
  return ApiClient(baseUrl: config.apiBaseUrl);
});
