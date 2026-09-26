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
  final String title;
  final String description;
  final String time;
  final TaskCategory category;
  final TaskStatus status;
  final String? completedBy;
  final String? completionNote;

  const CareTask({
    required this.id,
    required this.residentId,
    required this.title,
    required this.description,
    required this.time,
    required this.category,
    this.status = TaskStatus.pending,
    this.completedBy,
    this.completionNote,
  });

  CareTask copyWith({
    String? id,
    String? residentId,
    String? title,
    String? description,
    String? time,
    TaskCategory? category,
    TaskStatus? status,
    String? completedBy,
    String? completionNote,
  }) {
    return CareTask(
      id: id ?? this.id,
      residentId: residentId ?? this.residentId,
      title: title ?? this.title,
      description: description ?? this.description,
      time: time ?? this.time,
      category: category ?? this.category,
      status: status ?? this.status,
      completedBy: completedBy ?? this.completedBy,
      completionNote: completionNote ?? this.completionNote,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'residentId': residentId,
      'title': title,
      'description': description,
      'time': time,
      'category': category.name,
      'status': status.name,
      'completedBy': completedBy,
      'completionNote': completionNote,
    };
  }

  factory CareTask.fromJson(Map<String, dynamic> json) {
    return CareTask(
      id: json['id'] as String,
      residentId: json['residentId'] as String? ?? 'res_margaret',
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      time: json['time'] as String,
      category: TaskCategory.fromString(json['category'] as String? ?? 'purposeful'),
      status: TaskStatus.fromString(json['status'] as String? ?? 'pending'),
      completedBy: json['completedBy'] as String?,
      completionNote: json['completionNote'] as String?,
    );
  }
}
