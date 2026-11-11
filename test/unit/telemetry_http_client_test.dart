import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:elderly_mobile/core/network/telemetry_http_client.dart';
import 'package:elderly_mobile/core/telemetry/config/telemetry_category.dart';
import 'package:elderly_mobile/core/telemetry/telemetry_service.dart';

void main() {
  group('TelemetryHttpClient Unit Tests', () {
    setUp(() {
      TelemetryService.instance.configManager.applyDebugOverride(
        TelemetryCategory.networkTracing,
        enabled: true,
        sampleRate: 1.0,
      );
    });

    tearDown(() {
      TelemetryService.instance.configManager.clearDebugOverrides();
      TelemetryService.instance.clearStagedEvents();
    });

    test('injects W3C traceparent header and emits NETWORK_TRACING event', () async {
      String? sentTraceparent;

      final mockInner = MockClient((request) async {
        sentTraceparent = request.headers['traceparent'];
        return http.Response(
          jsonEncode({'status': 'ok'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = TelemetryHttpClient(inner: mockInner);
      final response = await client.get(
        Uri.parse('https://api.kubo.care/api/v1/patients/00000000-0000-0000-0000-000000000001/vitals'),
      );

      expect(response.statusCode, equals(200));

      // 1. Verify W3C traceparent format: 00-32hex-16hex-01
      expect(sentTraceparent, isNotNull);
      final parts = sentTraceparent!.split('-');
      expect(parts.length, equals(4));
      expect(parts[0], equals('00'));
      expect(parts[1].length, equals(32)); // 16 bytes hex trace_id
      expect(parts[2].length, equals(16)); // 8 bytes hex span_id
      expect(parts[3], equals('01'));     // sampled flag

      // 2. Verify Telemetry Event was recorded
      final staged = TelemetryService.instance.stagedEvents;
      expect(staged.isNotEmpty, isTrue);
      final networkEvent = staged.last;

      expect(networkEvent.category, equals(TelemetryCategory.networkTracing));
      expect(networkEvent.eventName, equals('http_request'));
      expect(networkEvent.traceId, equals(parts[1]));
      expect(networkEvent.spanId, equals(parts[2]));
      expect(networkEvent.payload['http_status'], equals(200));
      expect(networkEvent.payload['method'], equals('GET'));
      expect(networkEvent.payload['route'], equals('/api/v1/patients/{id}/vitals'));
      expect(networkEvent.payload['duration_ms'], isA<int>());
    });
  });
}
