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
