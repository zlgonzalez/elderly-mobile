import 'package:flutter_test/flutter_test.dart';
import 'package:elderly_mobile/core/telemetry/privacy/pii_sanitizer.dart';

void main() {
  group('URL Sanitizer Unit Tests', () {
    late PIISanitizer sanitizer;

    setUp(() {
      sanitizer = PIISanitizer();
    });

    test('replaces UUIDs in URL paths with {id} placeholder', () {
      const url = 'https://api.kubo.care/api/v1/patients/3fa85f64-5717-4562-b3fc-2c963f66afa6/care-plans';
      final clean = sanitizer.sanitizeUrl(url);

      expect(clean, equals('/api/v1/patients/{id}/care-plans'));
    });

    test('strips query parameters from sanitized URL paths', () {
      const url = 'https://api.kubo.care/api/v1/search?token=secret123&patient_name=John';
      final clean = sanitizer.sanitizeUrl(url);

      expect(clean, equals('/api/v1/search'));
      expect(clean.contains('token'), isFalse);
      expect(clean.contains('John'), isFalse);
    });
  });
}
