import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:elderly_mobile/core/telemetry/config/telemetry_category.dart';
import 'package:elderly_mobile/core/telemetry/interceptors/crash_interceptor.dart';
import 'package:elderly_mobile/core/telemetry/models/device_environment_info.dart';
import 'package:elderly_mobile/core/telemetry/models/telemetry_event.dart';

void main() {
  group('CrashInterceptor Unit Tests', () {
    late List<TelemetryEvent> capturedEvents;
    late CrashInterceptor interceptor;

    setUp(() {
      capturedEvents = [];
      interceptor = CrashInterceptor(
        appVersion: '1.4.2+15',
        deviceInfoProvider: () => const DeviceEnvironmentInfo(
          osName: 'iOS',
          osVersion: '17.5',
          deviceModel: 'iPhone 15 Pro',
          batteryLevel: 0.88,
          connectivityType: 'wifi',
        ),
        onCrashCaptured: (event) {
          capturedEvents.add(event);
        },
      );
      interceptor.initialize();
    });

    tearDown(() {
      interceptor.dispose();
    });

    test('captures synchronous Flutter framework errors with stack traces', () {
      final details = FlutterErrorDetails(
        exception: const FormatException('Invalid JSON payload in widget tree'),
        stack: StackTrace.current,
        library: 'widgets',
        context: ErrorDescription('building CaregiverHomeScreen'),
      );

      interceptor.handleFlutterError(details);

      expect(capturedEvents.length, equals(1));
      final event = capturedEvents.first;
      expect(event.category, equals(TelemetryCategory.crashAndExceptions));
      expect(event.eventName, equals('flutter_framework_error'));
      expect(event.appVersion, equals('1.4.2+15'));
      expect(event.deviceInfo.deviceModel, equals('iPhone 15 Pro'));
      expect(event.payload['exception_type'], equals('FormatException'));
      expect(
        event.payload['message'],
        contains('Invalid JSON payload in widget tree'),
      );
      expect(event.payload['stack_trace'], isNotEmpty);
      expect(event.payload['library'], equals('widgets'));
    });

    test('captures unhandled asynchronous Dart exceptions via PlatformDispatcher', () {
      final stateError = StateError('Stream controller already closed');
      final stack = StackTrace.current;

      interceptor.handlePlatformError(stateError, stack);

      expect(capturedEvents.length, equals(1));
      final event = capturedEvents.first;
      expect(event.category, equals(TelemetryCategory.crashAndExceptions));
      expect(event.eventName, equals('unhandled_dart_exception'));
      expect(event.payload['exception_type'], equals('StateError'));
      expect(
        event.payload['message'],
        contains('Stream controller already closed'),
      );
      expect(event.payload['stack_trace'], isNotEmpty);
      expect(event.eventId, isNotEmpty);
    });

    test('dispose correctly unhooks FlutterError and PlatformDispatcher', () {
      interceptor.dispose();

      expect(FlutterError.onError != interceptor.handleFlutterError, isTrue);
      expect(
        PlatformDispatcher.instance.onError != interceptor.handlePlatformError,
        isTrue,
      );
    });
  });
}
