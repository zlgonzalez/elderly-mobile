import 'care_task.dart';
import 'montessori_activity.dart';

enum RegimenGenerationPhase {
  idle('Idle', 'Ready to personalize your weekly Montessori plan'),
  retrieval('Clinical Retrieval', 'Gathering life history, hobbies, and prior participation memory...'),
  synthesis('Montessori Synthesis', 'Drafting safe 7-day activities adapted to capabilities...'),
  refinement('Regimen Refinement', 'Applying caregiver feedback to adapt schedule blocks...'),
  scoring('Clinical Scoring', 'Evaluating cognitive alignment, safety, and modality balance...'),
  completed('Ready', '7-day Montessori regimen ready for clinical review');

  final String title;
  final String description;
  const RegimenGenerationPhase(this.title, this.description);

  static RegimenGenerationPhase fromString(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'retrieval':
        return RegimenGenerationPhase.retrieval;
      case 'synthesis':
        return RegimenGenerationPhase.synthesis;
      case 'refinement':
        return RegimenGenerationPhase.refinement;
      case 'scoring':
        return RegimenGenerationPhase.scoring;
      case 'completed':
        return RegimenGenerationPhase.completed;
      case 'idle':
      default:
        return RegimenGenerationPhase.idle;
    }
  }
}

enum BatchJobType {
  generation('generation'),
  refinement('refinement');

  final String wireValue;
  const BatchJobType(this.wireValue);

  static BatchJobType fromString(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'refinement':
        return BatchJobType.refinement;
      case 'generation':
      default:
        return BatchJobType.generation;
    }
  }
}

enum BatchJobStatus {
  queued('queued'),
  inProgress('in_progress'),
  completed('completed'),
  failed('failed'),
  canceled('canceled');

  final String wireValue;
  const BatchJobStatus(this.wireValue);

  bool get isActive =>
      this == BatchJobStatus.queued || this == BatchJobStatus.inProgress;
  bool get isTerminal => !isActive;

  static BatchJobStatus fromString(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'queued':
        return BatchJobStatus.queued;
      case 'in_progress':
        return BatchJobStatus.inProgress;
      case 'completed':
        return BatchJobStatus.completed;
      case 'failed':
        return BatchJobStatus.failed;
      case 'canceled':
        return BatchJobStatus.canceled;
      default:
        return BatchJobStatus.queued;
    }
  }
}

class RegimenBatchJob {
  final String id;
  final String residentId;
  final String requestedBy;
  final BatchJobType jobType;
  final BatchJobStatus status;
  final RegimenGenerationPhase phase;
  final String? targetPlanId;
  final String? planId;
  final RegimenPlan? plan;
  final DateTime weekStartDate;
  final String? refinementInstruction;
  final bool autoApply;
  final int retryCount;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? dismissedAt;
  final DateTime updatedAt;

  const RegimenBatchJob({
    required this.id,
    required this.residentId,
    required this.requestedBy,
    required this.jobType,
    required this.status,
    required this.phase,
    this.targetPlanId,
    this.planId,
    this.plan,
    required this.weekStartDate,
    this.refinementInstruction,
    this.autoApply = false,
    this.retryCount = 0,
    this.errorMessage,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.dismissedAt,
    required this.updatedAt,
  });

  bool get isActive => status.isActive;
  bool get isCompleted => status == BatchJobStatus.completed;
  bool get isFailed => status == BatchJobStatus.failed;

  RegimenBatchJob copyWith({
    BatchJobStatus? status,
    RegimenGenerationPhase? phase,
    String? planId,
    RegimenPlan? plan,
    int? retryCount,
    String? errorMessage,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? dismissedAt,
    DateTime? updatedAt,
  }) {
    return RegimenBatchJob(
      id: id,
      residentId: residentId,
      requestedBy: requestedBy,
      jobType: jobType,
      status: status ?? this.status,
      phase: phase ?? this.phase,
      targetPlanId: targetPlanId,
      planId: planId ?? this.planId,
      plan: plan ?? this.plan,
      weekStartDate: weekStartDate,
      refinementInstruction: refinementInstruction,
      autoApply: autoApply,
      retryCount: retryCount ?? this.retryCount,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      dismissedAt: dismissedAt ?? this.dismissedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory RegimenBatchJob.fromJson(
    Map<String, dynamic> json, {
    required String residentId,
    RegimenPlan? mappedPlan,
  }) {
    final startStr = json['week_start_date']?.toString();
    final createdStr = json['created_at']?.toString();
    final startedStr = json['started_at']?.toString();
    final completedStr = json['completed_at']?.toString();
    final dismissedStr = json['dismissed_at']?.toString();
    final updatedStr = json['updated_at']?.toString();
    return RegimenBatchJob(
      id: json['id']?.toString() ?? '',
      residentId: residentId,
      requestedBy: json['requested_by']?.toString() ?? '',
      jobType: BatchJobType.fromString(json['job_type'] as String?),
      status: BatchJobStatus.fromString(json['status'] as String?),
      phase: RegimenGenerationPhase.fromString(json['phase'] as String?),
      targetPlanId: json['target_plan_id'] as String?,
      planId: json['plan_id'] as String?,
      plan: mappedPlan,
      weekStartDate: startStr != null
          ? (DateTime.tryParse(startStr) ?? DateTime.now().toUtc())
          : DateTime.now().toUtc(),
      refinementInstruction: json['refinement_instruction'] as String?,
      autoApply: json['auto_apply'] as bool? ?? false,
      retryCount: (json['retry_count'] as num?)?.toInt() ?? 0,
      errorMessage: json['error_message'] as String?,
      createdAt: createdStr != null
          ? (DateTime.tryParse(createdStr) ?? DateTime.now().toUtc())
          : DateTime.now().toUtc(),
      startedAt: startedStr != null ? DateTime.tryParse(startedStr) : null,
      completedAt: completedStr != null ? DateTime.tryParse(completedStr) : null,
      dismissedAt: dismissedStr != null ? DateTime.tryParse(dismissedStr) : null,
      updatedAt: updatedStr != null
          ? (DateTime.tryParse(updatedStr) ?? DateTime.now().toUtc())
          : DateTime.now().toUtc(),
    );
  }
}

class RegimenBatchConflictException implements Exception {
  final String message;
  final RegimenBatchJob? activeJob;

  const RegimenBatchConflictException(this.message, {this.activeJob});

  @override
  String toString() => message;
}

enum RegimenGenerationSource {
  kuboAgent('kubo_agent', 'Kubo Agent'),
  geminiAi('gemini_ai', 'Gemini AI'),
  baselineFallback('baseline_fallback', 'Clinical Baseline'),
  manual('manual', 'Manual');

  final String wireValue;
  final String displayName;
  const RegimenGenerationSource(this.wireValue, this.displayName);

  static RegimenGenerationSource fromString(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'kubo_agent':
        return RegimenGenerationSource.kuboAgent;
      case 'gemini_ai':
        return RegimenGenerationSource.geminiAi;
      case 'manual':
        return RegimenGenerationSource.manual;
      case 'baseline_fallback':
      default:
        return RegimenGenerationSource.baselineFallback;
    }
  }
}

class ClinicalScorecard {
  final int compositeScore;
  final int cognitiveAlignmentScore;
  final int physicalAccessibilityScore;
  final int purposefulEngagementScore;
  final int safetyControlOfErrorScore;
  final int modalityBalanceScore;
  final String feedback;

  const ClinicalScorecard({
    required this.compositeScore,
    required this.cognitiveAlignmentScore,
    required this.physicalAccessibilityScore,
    required this.purposefulEngagementScore,
    required this.safetyControlOfErrorScore,
    required this.modalityBalanceScore,
    required this.feedback,
  });

  bool get isLowScore => compositeScore < 70;

  factory ClinicalScorecard.fromJson(Map<String, dynamic> json) {
    return ClinicalScorecard(
      compositeScore: (json['composite_score'] as num?)?.toInt() ?? 0,
      cognitiveAlignmentScore:
          (json['cognitive_alignment_score'] as num?)?.toInt() ?? 0,
      physicalAccessibilityScore:
          (json['physical_accessibility_score'] as num?)?.toInt() ?? 0,
      purposefulEngagementScore:
          (json['purposeful_engagement_score'] as num?)?.toInt() ?? 0,
      safetyControlOfErrorScore:
          (json['safety_control_of_error_score'] as num?)?.toInt() ?? 0,
      modalityBalanceScore:
          (json['modality_balance_score'] as num?)?.toInt() ?? 0,
      feedback: json['feedback'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'composite_score': compositeScore,
        'cognitive_alignment_score': cognitiveAlignmentScore,
        'physical_accessibility_score': physicalAccessibilityScore,
        'purposeful_engagement_score': purposefulEngagementScore,
        'safety_control_of_error_score': safetyControlOfErrorScore,
        'modality_balance_score': modalityBalanceScore,
        'feedback': feedback,
      };
}

class RegimenPlan {
  final String id;
  final String? externalRegimenId;
  final String residentId;
  final DateTime weekStartDate;
  final RegimenGenerationSource generationSource;
  final String planStatus;
  final String synthesisNotes;
  final String? refinementInstruction;
  final List<String> safetyFlags;
  final bool emergencyEscalationRequired;
  final ClinicalScorecard? scorecard;
  final DateTime generatedAt;
  final List<CareTask> items;

  const RegimenPlan({
    required this.id,
    this.externalRegimenId,
    required this.residentId,
    required this.weekStartDate,
    required this.generationSource,
    this.planStatus = 'preview',
    this.synthesisNotes = '',
    this.refinementInstruction,
    this.safetyFlags = const [],
    this.emergencyEscalationRequired = false,
    this.scorecard,
    required this.generatedAt,
    this.items = const [],
  });

  bool get hasCriticalSafetyBlock =>
      emergencyEscalationRequired ||
      safetyFlags.any((f) {
        final upper = f.toUpperCase();
        return upper.contains('CRITICAL') ||
            upper.contains('EMERGENCY') ||
            upper.contains('ESCALAT');
      });

  bool get requiresLowScoreConfirmation =>
      scorecard != null && scorecard!.isLowScore;

  Map<int, List<CareTask>> get itemsGroupedByDay {
    final grouped = <int, List<CareTask>>{};
    for (final item in items) {
      final day = item.dayNumber ?? 1;
      grouped.putIfAbsent(day, () => []).add(item);
    }
    return grouped;
  }

  factory RegimenPlan.fromJson(
    Map<String, dynamic> json, {
    required String residentId,
    required List<CareTask> mappedItems,
  }) {
    final startStr = json['week_start_date']?.toString();
    final genStr = json['generated_at']?.toString();
    return RegimenPlan(
      id: json['id']?.toString() ?? '',
      externalRegimenId: json['external_regimen_id'] as String?,
      residentId: residentId,
      weekStartDate:
          startStr != null ? (DateTime.tryParse(startStr) ?? DateTime.now()) : DateTime.now(),
      generationSource:
          RegimenGenerationSource.fromString(json['generation_source'] as String?),
      planStatus: json['plan_status'] as String? ?? 'applied',
      synthesisNotes: json['synthesis_notes'] as String? ?? '',
      refinementInstruction: json['refinement_instruction'] as String?,
      safetyFlags: (json['safety_flags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      emergencyEscalationRequired:
          json['emergency_escalation_required'] as bool? ?? false,
      scorecard: json['scorecard'] is Map<String, dynamic>
          ? ClinicalScorecard.fromJson(json['scorecard'] as Map<String, dynamic>)
          : null,
      generatedAt:
          genStr != null ? (DateTime.tryParse(genStr) ?? DateTime.now()) : DateTime.now(),
      items: mappedItems,
    );
  }
}

class MontessoriTaxonomyMapper {
  MontessoriTaxonomyMapper._();

  static MontessoriCategory toMontessoriCategory(String? areaOrDomain) {
    final norm = (areaOrDomain ?? '').toLowerCase().replaceAll(' ', '');
    switch (norm) {
      case 'practicallife':
      case 'functional':
        return MontessoriCategory.practicalLife;
      case 'sensorial':
      case 'sensory':
      case 'physical':
        return MontessoriCategory.sensory;
      case 'language':
      case 'math':
      case 'cognitive':
        return MontessoriCategory.cognitive;
      case 'creative':
        return MontessoriCategory.creative;
      case 'cultural':
      case 'social':
        return MontessoriCategory.social;
      default:
        return MontessoriCategory.practicalLife;
    }
  }

  static TaskCategory toTaskCategory(String? areaOrDomain) {
    final norm = (areaOrDomain ?? '').toLowerCase().replaceAll(' ', '');
    switch (norm) {
      case 'sensorial':
      case 'sensory':
      case 'physical':
        return TaskCategory.physical;
      case 'cultural':
      case 'social':
        return TaskCategory.social;
      case 'language':
      case 'math':
      case 'cognitive':
      case 'creative':
        return TaskCategory.activity;
      case 'practicallife':
      case 'functional':
      default:
        return TaskCategory.purposeful;
    }
  }
}
