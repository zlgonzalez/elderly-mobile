import 'package:flutter/scheduler.dart';
import '../config/telemetry_category.dart';
import '../models/device_environment_info.dart';
import '../models/telemetry_event.dart';
import '../telemetry_service.dart';

class FrameTimingObserver {
  final TelemetryService telemetryService;
  final double jankThresholdMs;
  bool _active = false;

  FrameTimingObserver({
    TelemetryService? service,
    this.jankThresholdMs = 16.67, // 60 fps threshold
  }) : telemetryService = service ?? TelemetryService.instance;

  void start() {
    if (_active) return;
    _active = true;
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  void stop() {
    if (!_active) return;
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    _active = false;
  }

  void _onTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      final totalDurationMs = timing.totalSpan.inMicroseconds / 1000.0;
      if (totalDurationMs > jankThresholdMs) {
        final event = TelemetryEvent(
          eventId: TelemetryEvent.generateUuidV4(),
          timestamp: DateTime.now().toUtc(),
          appVersion: '1.0.0+1',
          deviceInfo: DeviceEnvironmentInfo.collectCurrent(),
          category: TelemetryCategory.uiInteractions,
          eventName: 'frame_jank',
          payload: {
            'total_duration_ms': totalDurationMs,
            'build_duration_ms': timing.buildDuration.inMicroseconds / 1000.0,
            'raster_duration_ms': timing.rasterDuration.inMicroseconds / 1000.0,
          },
        );

        telemetryService.recordEvent(event);
      }
    }
  }
}
