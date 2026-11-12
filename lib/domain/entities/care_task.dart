enum TaskCategory {
  physical,
  activity,
  social,
  purposeful;

  String get displayName {
    switch (this) {
      case TaskCategory.physical:
        return 'Physical';
      case TaskCategory.activity:
        return 'Activity';
      case TaskCategory.social:
        return 'Social';
      case TaskCategory.purposeful:
        return 'Purposeful';
    }
  }

  static TaskCategory fromString(String val) {
    switch (val.toLowerCase()) {
      case 'physical':
        return TaskCategory.physical;
      case 'activity':
        return TaskCategory.activity;
      case 'social':
        return TaskCategory.social;
      case 'purposeful':
      default:
        return TaskCategory.purposeful;
    }
  }
}

enum TaskStatus {
  pending,
  inProgress,
  completed,
  skipped;

  static TaskStatus fromString(String val) {
    switch (val.toLowerCase()) {
      case 'inprogress':
        return TaskStatus.inProgress;
      case 'completed':
        return TaskStatus.completed;
      case 'skipped':
      case 'missed':
        return TaskStatus.skipped;
      case 'pending':
      default:
        return TaskStatus.pending;
    }
  }
}

class CareTask {
  final String id;
  final String residentId;
  final String? planId;
  final int? dayNumber;
  final String title;
  final String description;
  final String time;
  final TaskCategory category;
  final TaskStatus status;
  final String? completedBy;
  final String? completionNote;
  final String? skipReason;
  final List<String> materials;
  final String? materialsTraySetup;
  final List<String> steps;
  final String? scriptPrompt;
  final String? dignityTip;
  final String? historicalConnection;
  final String? safetyComfort;
  final String? montessoriDomain;
  final String? generationSource;

  const CareTask({
    required this.id,
    required this.residentId,
    this.planId,
    this.dayNumber,
    required this.title,
    required this.description,
    required this.time,
    required this.category,
    this.status = TaskStatus.pending,
    this.completedBy,
    this.completionNote,
    this.skipReason,
    this.materials = const [],
    this.materialsTraySetup,
    this.steps = const [],
    this.scriptPrompt,
    this.dignityTip,
    this.historicalConnection,
    this.safetyComfort,
    this.montessoriDomain,
    this.generationSource,
  });

  CareTask copyWith({
    String? id,
    String? residentId,
    String? planId,
    int? dayNumber,
    String? title,
    String? description,
    String? time,
    TaskCategory? category,
    TaskStatus? status,
    String? completedBy,
    String? completionNote,
    String? skipReason,
    List<String>? materials,
    String? materialsTraySetup,
    List<String>? steps,
    String? scriptPrompt,
    String? dignityTip,
    String? historicalConnection,
    String? safetyComfort,
    String? montessoriDomain,
    String? generationSource,
  }) {
    return CareTask(
      id: id ?? this.id,
      residentId: residentId ?? this.residentId,
      planId: planId ?? this.planId,
      dayNumber: dayNumber ?? this.dayNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      time: time ?? this.time,
      category: category ?? this.category,
      status: status ?? this.status,
      completedBy: completedBy ?? this.completedBy,
      completionNote: completionNote ?? this.completionNote,
      skipReason: skipReason ?? this.skipReason,
      materials: materials ?? this.materials,
      materialsTraySetup: materialsTraySetup ?? this.materialsTraySetup,
      steps: steps ?? this.steps,
      scriptPrompt: scriptPrompt ?? this.scriptPrompt,
      dignityTip: dignityTip ?? this.dignityTip,
      historicalConnection: historicalConnection ?? this.historicalConnection,
      safetyComfort: safetyComfort ?? this.safetyComfort,
      montessoriDomain: montessoriDomain ?? this.montessoriDomain,
      generationSource: generationSource ?? this.generationSource,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'residentId': residentId,
      'planId': planId,
      'dayNumber': dayNumber,
      'title': title,
      'description': description,
      'time': time,
      'category': category.name,
      'status': status.name,
      'completedBy': completedBy,
      'completionNote': completionNote,
      'skipReason': skipReason,
      'materials': materials,
      'materialsTraySetup': materialsTraySetup,
      'steps': steps,
      'scriptPrompt': scriptPrompt,
      'dignityTip': dignityTip,
      'historicalConnection': historicalConnection,
      'safetyComfort': safetyComfort,
      'montessoriDomain': montessoriDomain,
      'generationSource': generationSource,
    };
  }

  factory CareTask.fromJson(Map<String, dynamic> json) {
    return CareTask(
      id: json['id'] as String,
      residentId: json['residentId'] as String? ?? 'res_margaret',
      planId: json['planId'] as String? ?? json['plan_id'] as String?,
      dayNumber: (json['dayNumber'] as num?)?.toInt() ??
          ((json['day_offset'] as num?) != null
              ? (json['day_offset'] as num).toInt() + 1
              : null),
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      time: json['time'] as String,
      category: TaskCategory.fromString(json['category'] as String? ?? 'purposeful'),
      status: TaskStatus.fromString(json['status'] as String? ?? 'pending'),
      completedBy: json['completedBy'] as String?,
      completionNote:
          json['completionNote'] as String? ?? json['completion_note'] as String?,
      skipReason: json['skipReason'] as String? ?? json['skip_reason'] as String?,
      materials: (json['materials'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      materialsTraySetup: json['materialsTraySetup'] as String? ??
          json['materials_tray_setup'] as String?,
      steps: (json['steps'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      scriptPrompt:
          json['scriptPrompt'] as String? ?? json['script_prompt'] as String?,
      dignityTip:
          json['dignityTip'] as String? ?? json['dignity_tip'] as String?,
      historicalConnection: json['historicalConnection'] as String? ??
          json['historical_connection'] as String?,
      safetyComfort:
          json['safetyComfort'] as String? ?? json['safety_comfort'] as String?,
      montessoriDomain: json['montessoriDomain'] as String? ??
          json['montessori_domain'] as String?,
      generationSource: json['generationSource'] as String? ??
          json['generation_source'] as String?,
    );
  }
}
