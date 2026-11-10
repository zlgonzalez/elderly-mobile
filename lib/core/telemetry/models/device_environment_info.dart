import 'package:flutter/foundation.dart';

class DeviceEnvironmentInfo {
  final String osName;
  final String osVersion;
  final String deviceModel;
  final double batteryLevel;
  final String connectivityType; // wifi, cellular, none

  const DeviceEnvironmentInfo({
    required this.osName,
    required this.osVersion,
    required this.deviceModel,
    required this.batteryLevel,
    required this.connectivityType,
  });

  static DeviceEnvironmentInfo collectCurrent({
    String connectivity = 'wifi',
    double battery = 1.0,
  }) {
    return DeviceEnvironmentInfo(
      osName: defaultTargetPlatform.name,
      osVersion: '17.0',
      deviceModel: kIsWeb ? 'Web Browser' : 'Mobile Client',
      batteryLevel: battery,
      connectivityType: connectivity,
    );
  }

  factory DeviceEnvironmentInfo.fromJson(Map<String, dynamic> json) {
    return DeviceEnvironmentInfo(
      osName: json['os_name'] as String? ?? 'Unknown',
      osVersion: json['os_version'] as String? ?? 'Unknown',
      deviceModel: json['device_model'] as String? ?? 'Unknown',
      batteryLevel: (json['battery_level'] as num?)?.toDouble() ?? 1.0,
      connectivityType: json['connectivity_type'] as String? ?? 'none',
    );
  }

  Map<String, dynamic> toJson() => {
    'os_name': osName,
    'os_version': osVersion,
    'device_model': deviceModel,
    'battery_level': batteryLevel,
    'connectivity_type': connectivityType,
  };
}
