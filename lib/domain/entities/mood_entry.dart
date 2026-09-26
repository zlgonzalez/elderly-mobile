enum MoodType {
  happy('Happy', '😊'),
  content('Content', '😌'),
  neutral('Neutral', '😐'),
  sad('Sad', '😢'),
  anxious('Anxious', '😰'),
  upset('Upset', '😠');

  final String label;
  final String emoji;

  const MoodType(this.label, this.emoji);

  static MoodType fromString(String val) {
    switch (val.toLowerCase()) {
      case 'content':
        return MoodType.content;
      case 'neutral':
        return MoodType.neutral;
      case 'sad':
        return MoodType.sad;
      case 'anxious':
        return MoodType.anxious;
      case 'upset':
        return MoodType.upset;
      case 'happy':
      default:
        return MoodType.happy;
    }
  }
}

class MoodEntry {
  final String id;
  final String residentId;
  final MoodType mood;
  final DateTime timestamp;
  final String recordedBy;
  final String? notes;

  const MoodEntry({
    required this.id,
    required this.residentId,
    required this.mood,
    required this.timestamp,
    required this.recordedBy,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'residentId': residentId,
      'mood': mood.name,
      'timestamp': timestamp.toIso8601String(),
      'recordedBy': recordedBy,
      'notes': notes,
    };
  }

  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      id: json['id'] as String,
      residentId: json['residentId'] as String? ?? 'res_margaret',
      mood: MoodType.fromString(json['mood'] as String? ?? 'happy'),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      recordedBy: json['recordedBy'] as String? ?? 'Family Member',
      notes: json['notes'] as String?,
    );
  }
}
