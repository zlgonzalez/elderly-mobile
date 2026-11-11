import 'package:flutter/foundation.dart';
import 'config/telemetry_config_manager.dart';
import 'interceptors/crash_interceptor.dart';
import 'models/device_environment_info.dart';
import 'models/telemetry_event.dart';
import 'privacy/pii_sanitizer.dart';
import 'queue/batch_dispatcher.dart';
import 'queue/bounded_ring_buffer.dart';

class TelemetryService {
  static final TelemetryService instance = TelemetryService._internal();

  TelemetryService._internal() {
    configManager = TelemetryConfigManager();
    buffer = BoundedRingBuffer();
    sanitizer = PIISanitizer();
  }

  late final TelemetryConfigManager configManager;
  late final BoundedRingBuffer buffer;
  late final PIISanitizer sanitizer;
  BatchDispatcher? dispatcher;
  late final CrashInterceptor _crashInterceptor;
  bool _initialized = false;
  final List<TelemetryEvent> _stagedEvents = [];

  void initialize({
    String appVersion = '1.0.0+1',
    String ingestionUrl = 'http://127.0.0.1:8080/api/v1/telemetry/events',
    String appKey = 'dev-telemetry-app-key',
    String Function()? authTokenProvider,
    void Function(TelemetryEvent event)? onEventCaptured,
  }) {
    if (_initialized) return;
    _initialized = true;

    dispatcher = BatchDispatcher(
      buffer: buffer,
      configManager: configManager,
      ingestionUrl: ingestionUrl,
      appKey: appKey,
      authTokenProvider: authTokenProvider,
    );
    dispatcher?.start();

    _crashInterceptor = CrashInterceptor(
      appVersion: appVersion,
      deviceInfoProvider: () => DeviceEnvironmentInfo.collectCurrent(),
      onCrashCaptured: (event) {
        recordEvent(event);
        onEventCaptured?.call(event);
      },
    );

    _crashInterceptor.initialize();
  }

  bool recordEvent(TelemetryEvent event) {
    // 1. Evaluate sampling gate & category enablement
    if (!configManager.shouldSample(event.category)) {
      return false; // Throttled / disabled at source
    }

    // 2. Apply Zero-PII sanitization and pseudonymization to payload
    final sanitizedPayload = sanitizer.sanitizeMap(event.payload);
    final sanitizedEvent = TelemetryEvent(
      eventId: event.eventId,
      timestamp: event.timestamp,
      appVersion: event.appVersion,
      deviceInfo: event.deviceInfo,
      category: event.category,
      traceId: event.traceId,
      spanId: event.spanId,
      eventName: event.eventName,
      payload: sanitizedPayload,
    );

    if (kDebugMode) {
      debugPrint('[TELEMETRY] [${sanitizedEvent.category.value}] ${sanitizedEvent.eventName}');
    }

    _stagedEvents.add(sanitizedEvent);
    buffer.enqueue(sanitizedEvent);
    dispatcher?.onEventEnqueued();
    return true;
  }

  List<TelemetryEvent> get stagedEvents => List.unmodifiable(_stagedEvents);

  void clearStagedEvents() {
    _stagedEvents.clear();
    buffer.clear();
  }

  void dispose() {
    _crashInterceptor.dispose();
    dispatcher?.stop();
    configManager.dispose();
    _initialized = false;
  }
}
