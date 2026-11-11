import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../config/telemetry_category.dart';
import '../config/telemetry_config_manager.dart';
import '../models/telemetry_event.dart';
import 'bounded_ring_buffer.dart';

class BatchDispatcher {
  final BoundedRingBuffer buffer;
  final ITelemetryConfigManager configManager;
  final String ingestionUrl;
  final String appKey;
  final String Function()? authTokenProvider;
  final http.Client _httpClient;
  final Random _random;

  Timer? _flushTimer;
  bool _isFlushing = false;
  bool isWifi = true;
  int _retryAttempt = 0;
  DateTime? _backoffUntil;

  BatchDispatcher({
    required this.buffer,
    required this.configManager,
    required this.ingestionUrl,
    this.appKey = 'dev-telemetry-app-key',
    this.authTokenProvider,
    http.Client? httpClient,
    Random? random,
  })  : _httpClient = httpClient ?? http.Client(),
        _random = random ?? Random();

  void start() {
    _schedulePeriodicFlush();
  }

  void stop() {
    _flushTimer?.cancel();
    _flushTimer = null;
  }

  void onEventEnqueued() {
    // If buffer count reaches batch threshold, trigger immediate flush
    if (buffer.length >= configManager.currentConfig.batchSize) {
      flush();
    }
  }

  void _schedulePeriodicFlush() {
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(
      configManager.currentConfig.flushInterval,
      (_) => flush(),
    );
  }

  Future<bool> flush() async {
    if (_isFlushing || buffer.isEmpty) {
      return false;
    }

    // Check backoff condition
    if (_backoffUntil != null && DateTime.now().isBefore(_backoffUntil!)) {
      return false;
    }

    _isFlushing = true;
    try {
      final wifiOnlyCategories = <TelemetryCategory>{};
      for (final cat in TelemetryCategory.values) {
        if (configManager.currentConfig.isWifiOnly(cat)) {
          wifiOnlyCategories.add(cat);
        }
      }

      final batch = buffer.peekBatch(
        maxCount: configManager.currentConfig.batchSize,
        isWifi: isWifi,
        wifiOnlyCategories: wifiOnlyCategories,
      );

      if (batch.isEmpty) {
        return false;
      }

      final success = await _dispatchBatch(batch);
      if (success) {
        buffer.dequeue(batch.map((e) => e.eventId).toList());
        _retryAttempt = 0;
        _backoffUntil = null;
        return true;
      } else {
        _applyBackoff();
        return false;
      }
    } catch (_) {
      _applyBackoff();
      return false;
    } finally {
      _isFlushing = false;
    }
  }

  Future<bool> _dispatchBatch(List<TelemetryEvent> events) async {
    final batchPayload = {
      'batch_id': TelemetryEvent.generateUuidV4(_random),
      'sent_at': DateTime.now().toUtc().toIso8601String(),
      'events': events.map((e) => e.toJson()).toList(),
    };

    final rawJson = jsonEncode(batchPayload);
    // GZIP payload compression
    final compressedBytes = gzip.encode(utf8.encode(rawJson));

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Content-Encoding': 'gzip',
      'X-App-Key': appKey,
    };

    final token = authTokenProvider?.call();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await _httpClient.post(
      Uri.parse(ingestionUrl),
      headers: headers,
      body: compressedBytes,
    );

    if (response.statusCode == 202) {
      return true;
    }

    if (response.statusCode == 429) {
      final retryAfterSec = int.tryParse(response.headers['retry-after'] ?? '');
      if (retryAfterSec != null && retryAfterSec > 0) {
        _backoffUntil = DateTime.now().add(Duration(seconds: retryAfterSec));
      }
    }

    return false;
  }

  void _applyBackoff() {
    _retryAttempt++;
    // Exponential backoff: base 2s, max 120s + random jitter up to 1000ms
    final baseSeconds = min(120, 2 * pow(2, min(_retryAttempt, 6)).toInt());
    final jitterMs = _random.nextInt(1000);
    _backoffUntil = DateTime.now().add(
      Duration(seconds: baseSeconds, milliseconds: jitterMs),
    );
  }
}
