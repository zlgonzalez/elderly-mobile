import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// Central HTTP Client for backend microservices.
/// Provides standardized authentication headers, JSON encoding/decoding, and error handling.
class ApiClient {
  final String baseUrl;
  String? _authToken;
  String? _activeInstitutionId = '00000000-0000-0000-0000-000000000001';

  final Duration requestTimeout;

  ApiClient({
    required this.baseUrl,
    this.requestTimeout = const Duration(seconds: 4),
  });

  String? get authToken => _authToken;
  String? get activeInstitutionId => _activeInstitutionId;

  void setAuthToken(String token) {
    _authToken = token;
  }

  void clearAuthToken() {
    _authToken = null;
  }

  void setActiveInstitutionId(String? institutionId) {
    _activeInstitutionId = institutionId;
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
      final baseUri = Uri.parse(baseUrl);
      final cleanPath = pathOrUrl.startsWith('/') ? pathOrUrl : '/$pathOrUrl';
      final portSuffix = (baseUri.hasPort && baseUri.port != 80 && baseUri.port != 443) ? ':${baseUri.port}' : '';
      return '${baseUri.scheme}://${baseUri.host}$portSuffix$cleanPath';
    } catch (_) {
      return pathOrUrl;
    }
  }

  Uri _buildUri(String endpoint, [Map<String, dynamic>? queryParameters]) {
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final fullUrl = '$baseUrl$cleanEndpoint';
    final uri = Uri.parse(fullUrl);
    if (queryParameters != null && queryParameters.isNotEmpty) {
      final stringParams = queryParameters.map((k, v) => MapEntry(k, v.toString()));
      return uri.replace(queryParameters: {
        ...uri.queryParameters,
        ...stringParams,
      });
    }
    return uri;
  }


  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParameters}) async {
    final uri = _buildUri(endpoint, queryParameters);
    if (kDebugMode) {
      debugPrint('[ApiClient] GET $uri (token: ${_authToken != null ? "yes" : "no"})');
    }
    try {
      final response = await http.get(uri, headers: _headers).timeout(requestTimeout);
      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ApiClient] GET $uri failed: $e');
      }
      rethrow;
    }
  }

  Future<dynamic> post(String endpoint, {dynamic body, Map<String, dynamic>? queryParameters}) async {
    final uri = _buildUri(endpoint, queryParameters);
    if (kDebugMode) {
      debugPrint('[ApiClient] POST $uri (body: $body)');
    }
    try {
      final response = await http.post(
        uri,
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(requestTimeout);
      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ApiClient] POST $uri failed: $e');
      }
      rethrow;
    }
  }

  Future<dynamic> patch(String endpoint, {dynamic body, Map<String, dynamic>? queryParameters}) async {
    final uri = _buildUri(endpoint, queryParameters);
    if (kDebugMode) {
      debugPrint('[ApiClient] PATCH $uri (body: $body)');
    }
    try {
      final response = await http.patch(
        uri,
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(requestTimeout);
      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ApiClient] PATCH $uri failed: $e');
      }
      rethrow;
    }
  }

  Future<dynamic> put(String endpoint, {dynamic body, Map<String, dynamic>? queryParameters}) async {
    final uri = _buildUri(endpoint, queryParameters);
    if (kDebugMode) {
      debugPrint('[ApiClient] PUT $uri (body: $body)');
    }
    try {
      final response = await http.put(
        uri,
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(requestTimeout);
      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ApiClient] PUT $uri failed: $e');
      }
      rethrow;
    }
  }

  Future<dynamic> delete(String endpoint, {Map<String, dynamic>? queryParameters}) async {
    final uri = _buildUri(endpoint, queryParameters);
    if (kDebugMode) {
      debugPrint('[ApiClient] DELETE $uri');
    }
    try {
      final response = await http.delete(uri, headers: _headers).timeout(requestTimeout);
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
        message = response.body.isNotEmpty ? response.body : 'HTTP ${response.statusCode}';
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
