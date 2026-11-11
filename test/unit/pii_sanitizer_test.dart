import 'package:flutter_test/flutter_test.dart';
import 'package:elderly_mobile/core/telemetry/privacy/pii_sanitizer.dart';

void main() {
  group('PIISanitizer Unit Tests', () {
    late PIISanitizer sanitizer;

    setUp(() {
      sanitizer = PIISanitizer(appSalt: 'test-salt-12345');
    });

    test('pseudonymizes user and account identifiers with HMAC-SHA256', () {
      const rawUserId = 'caregiver-uuid-42';
      final hash1 = sanitizer.hashIdentifier(rawUserId);
      final hash2 = sanitizer.hashIdentifier(rawUserId);

      // 1. Must be deterministic
      expect(hash1, equals(hash2));

      // 2. Must be 64-character hex string (SHA256)
      expect(hash1.length, equals(64));
      expect(RegExp(r'^[a-f0-9]{64}$').hasMatch(hash1), isTrue);

      // 3. Must not leak the raw identifier
      expect(hash1.contains('caregiver'), isFalse);
    });

    test('replaces sensitive PHI and credentials with [REDACTED]', () {
      final input = {
        'user_id': 'user_99',
        'patient_name': 'Eleanor Vance',
        'email': 'eleanor@example.com',
        'auth_token': 'eyJh...super-secret-jwt',
        'password': 'PlainTextPassword!',
        'clinical_notes': 'Patient exhibited mild cognitive disorientation',
        'regular_metric': 42.5,
        'nested_object': {
          'phone_number': '+1-555-0199',
          'diagnosis': 'Dementia Type 2',
          'safe_flag': true,
        },
      };

      final sanitized = sanitizer.sanitizeMap(input);

      // Pseudonymized
      expect(sanitized['user_id'], isNot(equals('user_99')));
      expect(sanitized['user_id'].length, equals(64));

      // Redacted
      expect(sanitized['patient_name'], equals('[REDACTED]'));
      expect(sanitized['email'], equals('[REDACTED]'));
      expect(sanitized['auth_token'], equals('[REDACTED]'));
      expect(sanitized['password'], equals('[REDACTED]'));
      expect(sanitized['clinical_notes'], equals('[REDACTED]'));

      // Safe metric preserved
      expect(sanitized['regular_metric'], equals(42.5));

      // Nested object sanitized
      final nested = sanitized['nested_object'] as Map<String, dynamic>;
      expect(nested['phone_number'], equals('[REDACTED]'));
      expect(nested['diagnosis'], equals('[REDACTED]'));
      expect(nested['safe_flag'], isTrue);
    });
  });
}
