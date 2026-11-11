import 'dart:convert';
import 'package:crypto/crypto.dart';

class PIISanitizer {
  final String appSalt;
  late final Hmac _hmac;

  static const Set<String> _redactedKeyPatterns = {
    'password',
    'pass',
    'token',
    'secret',
    'jwt',
    'auth',
    'authorization',
    'patient_name',
    'name',
    'first_name',
    'last_name',
    'full_name',
    'email',
    'phone',
    'phone_number',
    'ssn',
    'government_id',
    'notes',
    'clinical_notes',
    'diagnosis',
    'medical_history',
  };

  static const Set<String> _pseudonymizedKeys = {
    'user_id',
    'account_id',
    'caregiver_id',
    'admin_id',
  };

  PIISanitizer({this.appSalt = 'kubo-telemetry-privacy-salt-2026'}) {
    _hmac = Hmac(sha256, utf8.encode(appSalt));
  }

  /// Hashes user identifiers using HMAC-SHA256 for distinct metrics
  String hashIdentifier(String rawIdentifier) {
    if (rawIdentifier.isEmpty) return '';
    final digest = _hmac.convert(utf8.encode(rawIdentifier));
    return digest.toString();
  }

  /// Recursively scrubs sensitive keys and values from telemetry payloads
  Map<String, dynamic> sanitizeMap(Map<String, dynamic> map) {
    final sanitized = <String, dynamic>{};

    for (final entry in map.entries) {
      final keyLower = entry.key.toLowerCase();

      // 1. Pseudonymize user/account IDs
      if (_pseudonymizedKeys.contains(keyLower)) {
        sanitized[entry.key] = hashIdentifier(entry.value.toString());
        continue;
      }

      // 2. Redact passwords, PHI, names, tokens
      if (_redactedKeyPatterns.contains(keyLower) ||
          _redactedKeyPatterns.any((pat) => keyLower.contains(pat))) {
        sanitized[entry.key] = '[REDACTED]';
        continue;
      }

      // 3. Recurse nested objects
      final value = entry.value;
      if (value is Map<String, dynamic>) {
        sanitized[entry.key] = sanitizeMap(value);
      } else if (value is List) {
        sanitized[entry.key] = _sanitizeList(value);
      } else {
        sanitized[entry.key] = value;
      }
    }

    return sanitized;
  }

  List<dynamic> _sanitizeList(List<dynamic> list) {
    return list.map((item) {
      if (item is Map<String, dynamic>) {
        return sanitizeMap(item);
      } else if (item is List) {
        return _sanitizeList(item);
      }
      return item;
    }).toList();
  }

  /// Strips query parameters and normalizes route patterns
  String sanitizeUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final cleanPath = uri.path
          .replaceAll(
            RegExp(r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'),
            '{id}',
          )
          .replaceAll(RegExp(r'/\d+(?=/|$)'), '/{id}');
      return cleanPath;
    } catch (_) {
      return url;
    }
  }
}
