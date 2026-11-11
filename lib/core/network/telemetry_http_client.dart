import 'dart:math';
import 'package:http/http.dart' as http;
import '../telemetry/config/telemetry_category.dart';
import '../telemetry/models/device_environment_info.dart';
import '../telemetry/models/telemetry_event.dart';
import '../telemetry/telemetry_service.dart';

class TelemetryHttpClient extends http.BaseClient {
  final http.Client _inner;
  final TelemetryService _telemetryService;
  final Random _random;

  TelemetryHttpClient({
    http.Client? inner,
    TelemetryService? telemetryService,
    Random? random,
  })  : _inner = inner ?? http.Client(),
        _telemetryService = telemetryService ?? TelemetryService.instance,
        _random = random ?? Random();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // 1. Generate W3C Trace Context (traceparent: 00-traceId-spanId-01)
    final traceId = _generateTraceId();
    final spanId = _generateSpanId();

    if (!request.headers.containsKey('traceparent')) {
      request.headers['traceparent'] = '00-$traceId-$spanId-01';
    }

    final stopwatch = Stopwatch()..start();
    http.StreamedResponse? response;
    Object? error;

    try {
      response = await _inner.send(request);
      return response;
    } catch (e) {
      error = e;
      rethrow;
    } finally {
      stopwatch.stop();

      // 2. Emit Telemetry Event for NETWORK_TRACING
      _emitNetworkEvent(
        request: request,
        response: response,
        error: error,
        durationMs: stopwatch.elapsedMilliseconds,
        traceId: traceId,
        spanId: spanId,
      );
    }
  }

  void _emitNetworkEvent({
    required http.BaseRequest request,
    http.StreamedResponse? response,
    Object? error,
    required int durationMs,
    required String traceId,
    required String spanId,
  }) {
    final sanitizedRoute = _sanitizeRoute(request.url.path);

    final event = TelemetryEvent(
      eventId: TelemetryEvent.generateUuidV4(_random),
      timestamp: DateTime.now().toUtc(),
      appVersion: '1.0.0+1',
      deviceInfo: DeviceEnvironmentInfo.collectCurrent(),
      category: TelemetryCategory.networkTracing,
      traceId: traceId,
      spanId: spanId,
      eventName: 'http_request',
      payload: {
        'method': request.method,
        'route': sanitizedRoute,
        'http_status': response?.statusCode ?? (error != null ? 0 : 200),
        'duration_ms': durationMs,
        'content_length': response?.contentLength ?? 0,
        if (error != null) 'error': error.toString(),
      },
    );

    _telemetryService.recordEvent(event);
  }

  String _sanitizeRoute(String path) {
    // Replace UUIDs and numeric IDs with placeholders
    final uuidPattern = RegExp(r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}');
    final numericPattern = RegExp(r'/\d+(?=/|$)');

    return path
        .replaceAll(uuidPattern, '{id}')
        .replaceAll(numericPattern, '/{id}');
  }

  String _generateTraceId() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  String _generateSpanId() {
    final bytes = List<int>.generate(8, (_) => _random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
