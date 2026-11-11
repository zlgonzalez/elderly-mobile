enum TelemetryCategory {
  crashAndExceptions('CRASH_AND_EXCEPTIONS'),
  networkTracing('NETWORK_TRACING'),
  uiInteractions('UI_INTERACTIONS'),
  localDataOps('LOCAL_DATA_OPS'),
  businessEvents('BUSINESS_EVENTS');

  final String value;
  const TelemetryCategory(this.value);

  static TelemetryCategory fromString(String val) {
    return TelemetryCategory.values.firstWhere(
      (e) => e.value == val,
      orElse: () => TelemetryCategory.businessEvents,
    );
  }
}
