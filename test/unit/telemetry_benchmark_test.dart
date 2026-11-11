import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:elderly_mobile/core/telemetry/models/telemetry_event.dart';
import 'package:elderly_mobile/core/telemetry/models/device_environment_info.dart';
import 'package:elderly_mobile/core/telemetry/config/telemetry_category.dart';
import 'package:elderly_mobile/core/telemetry/privacy/pii_sanitizer.dart';

void main() {
  group('Telemetry Performance & Benchmark Tests', () {
    late DeviceEnvironmentInfo testDeviceInfo;
    late PIISanitizer sanitizer;

    setUp(() {
      sanitizer = PIISanitizer();
      testDeviceInfo = const DeviceEnvironmentInfo(
        osName: 'Android',
        osVersion: '14',
        deviceModel: 'Pixel 8 Pro',
        batteryLevel: 0.92,
        connectivityType: 'wifi',
      );
    });

    test('50-event batch JSON serialization and GZIP compression finishes within UI frame budget (<16.6ms)', () {
      final events = List.generate(50, (index) {
        final category = TelemetryCategory.values[index % TelemetryCategory.values.length];
        return TelemetryEvent(
          eventId: '7621c172-2374-42b7-a37a-428456209b55',
          timestamp: DateTime.now().toUtc(),
          appVersion: '1.0.0+1',
          deviceInfo: testDeviceInfo,
          category: category,
          eventName: 'benchmark_event_$index',
          traceId: '4bf92f3577b34da6a3ce929d0e0e4736',
          spanId: '00f067aa0ba902b7',
          payload: {
            'index': index,
            'user_id': 'user_benchmark_$index',
            'duration_ms': 42.5 + index,
            'route': '/api/v1/patients/123e4567-e89b-12d3-a456-426614174000/vitals',
            'status_code': 200,
            'auth_token': 'secret-auth-token-$index',
            'notes': 'Regular diagnostic operation in benchmark execution loop',
          },
        );
      });

      // Warm up JIT
      final warmupJson = jsonEncode({
        'batch_id': 'warmup-batch',
        'sent_at': DateTime.now().toUtc().toIso8601String(),
        'events': events.take(5).map((e) => e.toJson()).toList(),
      });
      gzip.encode(utf8.encode(warmupJson));

      // Execution benchmark
      final stopwatch = Stopwatch()..start();

      final sanitizedEvents = events.map((event) {
        return TelemetryEvent(
          eventId: event.eventId,
          timestamp: event.timestamp,
          appVersion: event.appVersion,
          deviceInfo: event.deviceInfo,
          category: event.category,
          traceId: event.traceId,
          spanId: event.spanId,
          eventName: event.eventName,
          payload: sanitizer.sanitizeMap(event.payload),
        );
      }).toList();

      final batchPayload = {
        'batch_id': 'a50c822e-13c5-4cb2-85e6-7b4d1b81622f',
        'sent_at': DateTime.now().toUtc().toIso8601String(),
        'events': sanitizedEvents.map((e) => e.toJson()).toList(),
      };

      final jsonBytes = utf8.encode(jsonEncode(batchPayload));
      final compressedBytes = gzip.encode(jsonBytes);

      stopwatch.stop();

      final elapsedMs = stopwatch.elapsedMicroseconds / 1000.0;

      // Must execute well within a single 60 FPS frame (16.66ms) to prevent UI frame drops
      expect(elapsedMs, lessThan(16.66));
      expect(compressedBytes.length, lessThan(jsonBytes.length));
      expect(sanitizedEvents.length, equals(50));
      expect(sanitizedEvents.first.payload['auth_token'], equals('[REDACTED]'));
      expect(sanitizedEvents.first.payload['notes'], equals('[REDACTED]'));
    });

    test('1,000 rapid event sanitizations consume minimal memory and complete under 100ms', () {
      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < 1000; i++) {
        final hashed = sanitizer.hashIdentifier('user_$i');
        final sanitized = sanitizer.sanitizeMap({
          'user_id': 'user_$i',
          'auth_token': 'secret_$i',
          'notes': 'Normal health vitals assessment',
          'nested': {'password': 'pass', 'safe': 'value'},
        });
        expect(hashed, hasLength(64));
        expect(sanitized['auth_token'], equals('[REDACTED]'));
        expect((sanitized['nested'] as Map)['password'], equals('[REDACTED]'));
      }

      stopwatch.stop();
      final totalElapsedMs = stopwatch.elapsedMilliseconds;
      expect(totalElapsedMs, lessThan(100));
    });

    test('TelemetryEvent.generateUuidV4 returns valid unique RFC-4122 v4 UUIDs', () {
      final uuidV4Pattern = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      );
      final generated = <String>{};
      for (var i = 0; i < 100; i++) {
        final id = TelemetryEvent.generateUuidV4();
        expect(uuidV4Pattern.hasMatch(id), isTrue);
        generated.add(id);
      }
      expect(generated, hasLength(100));
    });
  });
}
