import 'dart:math';
import '../config/telemetry_category.dart';
import 'device_environment_info.dart';

class TelemetryEvent {
  static final Random _defaultRandom = _createRandom();

  static Random _createRandom() {
    try {
      return Random.secure();
    } catch (_) {
      return Random();
    }
  }

  /// Generates an RFC-4122 version 4 UUID string for event and batch IDs.
  static String generateUuidV4([Random? random]) {
    final rng = random ?? _defaultRandom;
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }
  final String eventId;
  final DateTime timestamp;
  final String appVersion;
  final DeviceEnvironmentInfo deviceInfo;
  final TelemetryCategory category;
  final String? traceId;
  final String? spanId;
  final String eventName;
  final Map<String, dynamic> payload;

  const TelemetryEvent({
    required this.eventId,
    required this.timestamp,
    required this.appVersion,
    required this.deviceInfo,
    required this.category,
    this.traceId,
    this.spanId,
    required this.eventName,
    required this.payload,
  });

  factory TelemetryEvent.fromJson(Map<String, dynamic> json) {
    return TelemetryEvent(
      eventId: json['event_id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      appVersion: json['app_version'] as String,
      deviceInfo: DeviceEnvironmentInfo.fromJson(
        json['device_info'] as Map<String, dynamic>,
      ),
      category: TelemetryCategory.fromString(json['category'] as String),
      traceId: json['trace_id'] as String?,
      spanId: json['span_id'] as String?,
      eventName: json['event_name'] as String,
      payload: (json['payload'] as Map<String, dynamic>?) ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
    'event_id': eventId,
    'timestamp': timestamp.toUtc().toIso8601String(),
    'app_version': appVersion,
    'device_info': deviceInfo.toJson(),
    'category': category.value,
    if (traceId != null) 'trace_id': traceId,
    if (spanId != null) 'span_id': spanId,
    'event_name': eventName,
    'payload': payload,
  };
}
