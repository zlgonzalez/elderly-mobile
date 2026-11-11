import '../config/telemetry_category.dart';
import '../models/device_environment_info.dart';
import '../models/telemetry_event.dart';
import '../telemetry_service.dart';

class LocalStorageObserver {
  final TelemetryService telemetryService;

  LocalStorageObserver({TelemetryService? service})
      : telemetryService = service ?? TelemetryService.instance;

  Future<T> trackOperation<T>({
    required String operation,
    required String storageTarget,
    required Future<T> Function() action,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await action();
      return result;
    } finally {
      stopwatch.stop();

      final event = TelemetryEvent(
        eventId: TelemetryEvent.generateUuidV4(),
        timestamp: DateTime.now().toUtc(),
        appVersion: '1.0.0+1',
        deviceInfo: DeviceEnvironmentInfo.collectCurrent(),
        category: TelemetryCategory.localDataOps,
        eventName: 'storage_op',
        payload: {
          'operation': operation,
          'target': storageTarget,
          'duration_ms': stopwatch.elapsedMilliseconds,
        },
      );

      telemetryService.recordEvent(event);
    }
  }
}
