import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:elderly_mobile/core/telemetry/config/telemetry_category.dart';
import 'package:elderly_mobile/core/telemetry/config/telemetry_config_manager.dart';
import 'package:elderly_mobile/core/telemetry/models/device_environment_info.dart';
import 'package:elderly_mobile/core/telemetry/models/telemetry_event.dart';
import 'package:elderly_mobile/core/telemetry/queue/batch_dispatcher.dart';
import 'package:elderly_mobile/core/telemetry/queue/bounded_ring_buffer.dart';

void main() {
  group('BatchDispatcher Unit Tests', () {
    TelemetryEvent makeEvent(String id) {
      return TelemetryEvent(
        eventId: id,
        timestamp: DateTime.now().toUtc(),
        appVersion: '1.0.0',
        deviceInfo: const DeviceEnvironmentInfo(
          osName: 'iOS',
          osVersion: '17.0',
          deviceModel: 'iPhone 15',
          batteryLevel: 0.9,
          connectivityType: 'wifi',
        ),
        category: TelemetryCategory.crashAndExceptions,
        eventName: 'unhandled_crash',
        payload: {'error': 'crash_test'},
      );
    }

    test('flushes GZIP-compressed batch to ingestion endpoint and dequeues on 202', () async {
      final buffer = BoundedRingBuffer();
      final configManager = TelemetryConfigManager();
      buffer.enqueue(makeEvent('event-1'));
      buffer.enqueue(makeEvent('event-2'));

      bool gzipHeaderPresent = false;
      String? sentAppKey;
      Map<String, dynamic>? decodedBody;

      final mockClient = MockClient((request) async {
        gzipHeaderPresent = request.headers['content-encoding'] == 'gzip';
        sentAppKey = request.headers['x-app-key'];

        // Decompress GZIP payload
        final unzippedBytes = gzip.decode(request.bodyBytes);
        decodedBody = jsonDecode(utf8.decode(unzippedBytes)) as Map<String, dynamic>;

        return http.Response(
          jsonEncode({'status': 'accepted', 'accepted_count': 2}),
          202,
          headers: {'content-type': 'application/json'},
        );
      });

      final dispatcher = BatchDispatcher(
        buffer: buffer,
        configManager: configManager,
        ingestionUrl: 'https://api.kubo.care/api/v1/telemetry/events',
        appKey: 'test-app-key',
        httpClient: mockClient,
      );

      final success = await dispatcher.flush();

      expect(success, isTrue);
      expect(gzipHeaderPresent, isTrue);
      expect(sentAppKey, equals('test-app-key'));
      expect(decodedBody, isNotNull);
      expect(decodedBody!['events'], isA<List>());
      expect((decodedBody!['events'] as List).length, equals(2));

      // Buffer should be empty after successful 202 response
      expect(buffer.isEmpty, isTrue);
    });

    test('retains events in buffer when ingestion endpoint returns HTTP 429', () async {
      final buffer = BoundedRingBuffer();
      final configManager = TelemetryConfigManager();
      buffer.enqueue(makeEvent('event-1'));

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'rate limit exceeded'}),
          429,
          headers: {'retry-after': '60'},
        );
      });

      final dispatcher = BatchDispatcher(
        buffer: buffer,
        configManager: configManager,
        ingestionUrl: 'https://api.kubo.care/api/v1/telemetry/events',
        httpClient: mockClient,
      );

      final success = await dispatcher.flush();

      expect(success, isFalse);
      // Event must be retained in buffer!
      expect(buffer.length, equals(1));
    });
  });
}
