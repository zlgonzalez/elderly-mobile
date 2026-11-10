import '../config/telemetry_category.dart';
import 'device_environment_info.dart';

class TelemetryEvent {
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
