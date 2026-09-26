class VitalSign {
  final String id;
  final String residentId;
  final DateTime timestamp;
  final String bloodPressure;
  final int heartRate;
  final double temperature;
  final double? weight;
  final String? mobilityLevel;
  final int painLevel;
  final String recordedBy;
  final String? clinicalNotes;

  const VitalSign({
    required this.id,
    required this.residentId,
    required this.timestamp,
    required this.bloodPressure,
    required this.heartRate,
    required this.temperature,
    this.weight,
    this.mobilityLevel,
    this.painLevel = 0,
    required this.recordedBy,
    this.clinicalNotes,
  });

  bool get isAbnormal {
    // Basic clinical thresholds
    final parts = bloodPressure.split('/');
    if (parts.length == 2) {
      final systolic = int.tryParse(parts[0]) ?? 120;
      final diastolic = int.tryParse(parts[1]) ?? 80;
      if (systolic >= 140 || diastolic >= 90) return true;
    }
    if (heartRate > 100 || heartRate < 55) return true;
    if (temperature > 100.4 || temperature < 96.0) return true;
    if (painLevel >= 7) return true;
    return false;
  }

  VitalSign copyWith({
    String? id,
    String? residentId,
    DateTime? timestamp,
    String? bloodPressure,
    int? heartRate,
    double? temperature,
    double? weight,
    String? mobilityLevel,
    int? painLevel,
    String? recordedBy,
    String? clinicalNotes,
  }) {
    return VitalSign(
      id: id ?? this.id,
      residentId: residentId ?? this.residentId,
      timestamp: timestamp ?? this.timestamp,
      bloodPressure: bloodPressure ?? this.bloodPressure,
      heartRate: heartRate ?? this.heartRate,
      temperature: temperature ?? this.temperature,
      weight: weight ?? this.weight,
      mobilityLevel: mobilityLevel ?? this.mobilityLevel,
      painLevel: painLevel ?? this.painLevel,
      recordedBy: recordedBy ?? this.recordedBy,
      clinicalNotes: clinicalNotes ?? this.clinicalNotes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'residentId': residentId,
      'timestamp': timestamp.toIso8601String(),
      'bloodPressure': bloodPressure,
      'heartRate': heartRate,
      'temperature': temperature,
      'weight': weight,
      'mobilityLevel': mobilityLevel,
      'painLevel': painLevel,
      'recordedBy': recordedBy,
      'clinicalNotes': clinicalNotes,
    };
  }

  factory VitalSign.fromJson(Map<String, dynamic> json) {
    return VitalSign(
      id: json['id'] as String,
      residentId: json['residentId'] as String? ?? 'res_margaret',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      bloodPressure: json['bloodPressure'] as String? ?? '120/80',
      heartRate: (json['heartRate'] as num?)?.toInt() ?? 72,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 98.6,
      weight: (json['weight'] as num?)?.toDouble(),
      mobilityLevel: json['mobilityLevel'] as String?,
      painLevel: (json['painLevel'] as num?)?.toInt() ?? 0,
      recordedBy: json['recordedBy'] as String? ?? 'Nurse Jane',
      clinicalNotes: json['clinicalNotes'] as String?,
    );
  }
}
