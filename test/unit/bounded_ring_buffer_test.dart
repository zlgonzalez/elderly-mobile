import 'package:flutter_test/flutter_test.dart';
import 'package:elderly_mobile/core/telemetry/config/telemetry_category.dart';
import 'package:elderly_mobile/core/telemetry/models/device_environment_info.dart';
import 'package:elderly_mobile/core/telemetry/models/telemetry_event.dart';
import 'package:elderly_mobile/core/telemetry/queue/bounded_ring_buffer.dart';

void main() {
  group('BoundedRingBuffer Unit Tests', () {
    TelemetryEvent makeEvent(TelemetryCategory category, String name) {
      return TelemetryEvent(
        eventId: '${name}_${DateTime.now().microsecondsSinceEpoch}',
        timestamp: DateTime.now().toUtc(),
        appVersion: '1.0.0',
        deviceInfo: const DeviceEnvironmentInfo(
          osName: 'iOS',
          osVersion: '17.0',
          deviceModel: 'iPhone 14',
          batteryLevel: 0.9,
          connectivityType: 'wifi',
        ),
        category: category,
        eventName: name,
        payload: {'data': 'test_payload'},
      );
    }

    test('enqueues events and calculates estimated byte size', () {
      final buffer = BoundedRingBuffer(maxBytes: 10000, maxEventCount: 100);
      final event1 = makeEvent(TelemetryCategory.businessEvents, 'screen_view');
      final event2 = makeEvent(TelemetryCategory.crashAndExceptions, 'crash');

      buffer.enqueue(event1);
      buffer.enqueue(event2);

      expect(buffer.length, equals(2));
      expect(buffer.currentBytes, greaterThan(0));
    });

    test('enforces priority shedding by dropping UI events before crashes when capacity is exceeded', () {
      // Small buffer holding ~3 events
      final buffer = BoundedRingBuffer(maxBytes: 10000, maxEventCount: 3);

      final uiEvent1 = makeEvent(TelemetryCategory.uiInteractions, 'jank_frame');
      final uiEvent2 = makeEvent(TelemetryCategory.uiInteractions, 'tap_breadcrumb');
      final crashEvent = makeEvent(TelemetryCategory.crashAndExceptions, 'unhandled_exception');

      buffer.enqueue(uiEvent1);
      buffer.enqueue(uiEvent2);
      buffer.enqueue(crashEvent);

      expect(buffer.length, equals(3));

      // Now enqueue a 4th event (business event)
      final businessEvent = makeEvent(TelemetryCategory.businessEvents, 'activity_completed');
      buffer.enqueue(businessEvent);

      // Buffer size must remain capped at 3
      expect(buffer.length, equals(3));

      final batch = buffer.peekBatch(maxCount: 10);
      final categories = batch.map((e) => e.category).toList();

      // UI event should have been evicted first, keeping crash and business event!
      expect(categories.contains(TelemetryCategory.crashAndExceptions), isTrue);
      expect(categories.contains(TelemetryCategory.businessEvents), isTrue);
      // At least one UI event was evicted
      expect(categories.where((c) => c == TelemetryCategory.uiInteractions).length, equals(1));
    });

    test('peekBatch respects wifiOnly constraint on cellular connection', () {
      final buffer = BoundedRingBuffer();
      final uiEvent = makeEvent(TelemetryCategory.uiInteractions, 'ui');
      final crashEvent = makeEvent(TelemetryCategory.crashAndExceptions, 'crash');

      buffer.enqueue(uiEvent);
      buffer.enqueue(crashEvent);

      // Peek when isWifi = false and UI is in wifiOnlyCategories
      final cellularBatch = buffer.peekBatch(
        isWifi: false,
        wifiOnlyCategories: {TelemetryCategory.uiInteractions},
      );

      // Only the crash event should be selected for cellular dispatch
      expect(cellularBatch.length, equals(1));
      expect(cellularBatch.first.category, equals(TelemetryCategory.crashAndExceptions));

      // Peek when isWifi = true
      final wifiBatch = buffer.peekBatch(
        isWifi: true,
        wifiOnlyCategories: {TelemetryCategory.uiInteractions},
      );

      expect(wifiBatch.length, equals(2));
    });

    test('dequeue removes acknowledged events and updates estimated byte size', () {
      final buffer = BoundedRingBuffer();
      final event1 = makeEvent(TelemetryCategory.businessEvents, 'event1');
      final event2 = makeEvent(TelemetryCategory.businessEvents, 'event2');

      buffer.enqueue(event1);
      buffer.enqueue(event2);

      buffer.dequeue([event1.eventId]);

      expect(buffer.length, equals(1));
      expect(buffer.peekBatch().first.eventId, equals(event2.eventId));
    });
  });
}
