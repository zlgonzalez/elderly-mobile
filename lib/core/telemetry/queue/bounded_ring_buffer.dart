import 'dart:convert';
import '../config/telemetry_category.dart';
import '../models/telemetry_event.dart';

class BoundedRingBuffer {
  final int maxBytes;
  final int maxEventCount;
  final List<TelemetryEvent> _events = [];
  int _currentEstimatedBytes = 0;

  BoundedRingBuffer({
    this.maxBytes = 5 * 1024 * 1024, // 5 MB hard cap
    this.maxEventCount = 1000,
  });

  int get length => _events.length;
  int get currentBytes => _currentEstimatedBytes;
  bool get isEmpty => _events.isEmpty;
  bool get isNotEmpty => _events.isNotEmpty;

  void enqueue(TelemetryEvent event) {
    final eventBytes = _estimateEventBytes(event);

    // If a single event exceeds the max buffer size (abnormal), reject
    if (eventBytes > maxBytes) {
      return;
    }

    // Evict lower-priority events if adding this exceeds capacity
    while ((_currentEstimatedBytes + eventBytes > maxBytes ||
            _events.length >= maxEventCount) &&
        _events.isNotEmpty) {
      final evicted = _evictLowestPriorityEvent();
      if (!evicted) {
        // If nothing can be evicted (e.g. only crashes left and buffer full)
        break;
      }
    }

    _events.add(event);
    _currentEstimatedBytes += eventBytes;
  }

  /// Returns up to [maxCount] events, excluding wifiOnly events if [isWifi] is false.
  List<TelemetryEvent> peekBatch({
    int maxCount = 50,
    bool isWifi = true,
    Set<TelemetryCategory>? wifiOnlyCategories,
  }) {
    final batch = <TelemetryEvent>[];

    for (final event in _events) {
      if (!isWifi &&
          wifiOnlyCategories != null &&
          wifiOnlyCategories.contains(event.category)) {
        continue; // Defer wifi-only events during cellular use
      }

      batch.add(event);
      if (batch.length >= maxCount) {
        break;
      }
    }

    return batch;
  }

  /// Removes acknowledged events after successful dispatch
  void dequeue(List<String> eventIds) {
    final idSet = eventIds.toSet();
    _events.removeWhere((event) {
      if (idSet.contains(event.eventId)) {
        _currentEstimatedBytes -= _estimateEventBytes(event);
        return true;
      }
      return false;
    });

    if (_currentEstimatedBytes < 0) {
      _currentEstimatedBytes = 0;
    }
  }

  void clear() {
    _events.clear();
    _currentEstimatedBytes = 0;
  }

  /// Priority shedding order:
  /// 1. UI_INTERACTIONS (lowest priority)
  /// 2. LOCAL_DATA_OPS
  /// 3. NETWORK_TRACING
  /// 4. BUSINESS_EVENTS
  /// 5. CRASH_AND_EXCEPTIONS (highest priority)
  bool _evictLowestPriorityEvent() {
    const sheddingOrder = [
      TelemetryCategory.uiInteractions,
      TelemetryCategory.localDataOps,
      TelemetryCategory.networkTracing,
      TelemetryCategory.businessEvents,
      TelemetryCategory.crashAndExceptions,
    ];

    for (final category in sheddingOrder) {
      final index = _events.indexWhere((e) => e.category == category);
      if (index != -1) {
        final removed = _events.removeAt(index);
        _currentEstimatedBytes -= _estimateEventBytes(removed);
        return true;
      }
    }

    return false;
  }

  int _estimateEventBytes(TelemetryEvent event) {
    try {
      final jsonString = jsonEncode(event.toJson());
      return utf8.encode(jsonString).length;
    } catch (_) {
      return 256; // Fallback approximate byte count
    }
  }
}
