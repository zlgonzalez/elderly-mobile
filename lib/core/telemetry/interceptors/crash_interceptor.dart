import 'dart:ui';
import 'package:flutter/foundation.dart';
import '../config/telemetry_category.dart';
import '../models/device_environment_info.dart';
import '../models/telemetry_event.dart';

typedef EventDispatcherCallback = void Function(TelemetryEvent event);

class CrashInterceptor {
  final EventDispatcherCallback onCrashCaptured;
  final String appVersion;
  final DeviceEnvironmentInfo Function()? deviceInfoProvider;

  FlutterExceptionHandler? _previousFlutterOnError;
  ErrorCallback? _previousPlatformOnError;
  bool _initialized = false;

  CrashInterceptor({
    required this.onCrashCaptured,
    this.appVersion = '1.0.0+1',
    this.deviceInfoProvider,
  });

  void initialize() {
    if (_initialized) return;
    _initialized = true;

    // 1. Hook Flutter synchronous framework and rendering errors
    _previousFlutterOnError = FlutterError.onError;
    FlutterError.onError = handleFlutterError;

    // 2. Hook PlatformDispatcher asynchronous Dart VM and isolate errors
    _previousPlatformOnError = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = handlePlatformError;
  }

  void dispose() {
    if (!_initialized) return;
    FlutterError.onError = _previousFlutterOnError;
    PlatformDispatcher.instance.onError = _previousPlatformOnError;
    _initialized = false;
  }

  void handleFlutterError(FlutterErrorDetails details) {
    try {
      final event = createCrashEvent(
        eventName: 'flutter_framework_error',
        exception: details.exception,
        stackTrace: details.stack ?? StackTrace.current,
        extraContext: {
          'library': details.library ?? 'unknown',
          'context': details.context?.toDescription() ?? details.context?.toString() ?? '',
          'silent': details.silent,
        },
      );
      onCrashCaptured(event);
    } catch (_) {
      // Never allow error interceptor to throw
    }

    _previousFlutterOnError?.call(details);
  }

  bool handlePlatformError(Object error, StackTrace stack) {
    try {
      final event = createCrashEvent(
        eventName: 'unhandled_dart_exception',
        exception: error,
        stackTrace: stack,
      );
      onCrashCaptured(event);
    } catch (_) {
      // Never allow error interceptor to throw
    }

    if (_previousPlatformOnError != null) {
      return _previousPlatformOnError!(error, stack);
    }
    return false; // Error not completely handled, allows normal VM logging
  }

  TelemetryEvent createCrashEvent({
    required String eventName,
    required Object exception,
    required StackTrace stackTrace,
    Map<String, dynamic>? extraContext,
  }) {
    final devInfo = deviceInfoProvider != null
        ? deviceInfoProvider!()
        : const DeviceEnvironmentInfo(
            osName: 'Flutter',
            osVersion: 'Unknown',
            deviceModel: 'Generic Device',
            batteryLevel: 1.0,
            connectivityType: 'none',
          );

    final eventId = TelemetryEvent.generateUuidV4();

    return TelemetryEvent(
      eventId: eventId,
      timestamp: DateTime.now().toUtc(),
      appVersion: appVersion,
      deviceInfo: devInfo,
      category: TelemetryCategory.crashAndExceptions,
      eventName: eventName,
      payload: {
        'exception_type': exception.runtimeType.toString(),
        'message': exception.toString(),
        'stack_trace': stackTrace.toString(),
        ...?extraContext,
      },
    );
  }
}
