import 'package:a2ui_core/a2ui_core.dart';
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:a2ui_flutter/basic_catalog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/care_task.dart';
import '../../domain/entities/regimen_plan.dart';
import 'kubo_regimen_catalog.dart';

/// Translates Kubo domain models ([RegimenPlan], [CareTask]) into A2UI v1.0
/// message payloads targeting [kuboRegimenCatalogId].
abstract final class RegimenA2uiBlueprintBuilder {
  /// Builds an A2UI v1.0 `createSurface` payload for reviewing a generated
  /// 7-day [RegimenPlan] before applying it.
  static List<Map<String, Object?>> buildPlanPreviewMessages(
    RegimenPlan plan, {
    String surfaceId = 'regimen_preview',
  }) {
    final components = <Map<String, Object?>>[];
    final rootChildren = <String>[];

    // 1. Clinical scorecard + safety callout component
    final scorecard = plan.scorecard;
    if (scorecard != null ||
        plan.safetyFlags.isNotEmpty ||
        plan.hasCriticalSafetyBlock) {
      rootChildren.add('scorecard');
      components.add(<String, Object?>{
        'id': 'scorecard',
        'component': 'RegimenClinicalScorecard',
        'generationSource': plan.generationSource.displayName,
        if (scorecard != null) ...<String, Object?>{
          'compositeScore': scorecard.compositeScore,
          'cognitiveScore': scorecard.cognitiveAlignmentScore,
          'physicalScore': scorecard.physicalAccessibilityScore,
          'engagementScore': scorecard.purposefulEngagementScore,
          'safetyScore': scorecard.safetyControlOfErrorScore,
          'balanceScore': scorecard.modalityBalanceScore,
          'feedback': scorecard.feedback,
          'isLowScore': scorecard.isLowScore,
        },
        'isBlocked': plan.hasCriticalSafetyBlock,
        'safetyFlags': plan.safetyFlags,
      });
    }

    // 2. 7-day schedule + activity cards
    final grouped = plan.itemsGroupedByDay;
    final dayKeys = grouped.keys.toList()..sort();
    final activityIds = <String>[];
    var cardIndex = 0;

    for (final dayNum in dayKeys) {
      final dayItems = grouped[dayNum] ?? const <CareTask>[];
      for (var i = 0; i < dayItems.length; i++) {
        final task = dayItems[i];
        final compId = 'activity_${dayNum}_${cardIndex++}';
        activityIds.add(compId);
        components.add(
          _activityCardComponent(
            id: compId,
            task: task,
            dayNumber: dayNum,
            mode: 'preview',
            // Expand all activities on the first day so caregivers immediately
            // see full tray setup, materials, steps, and clinical guidance.
            initiallyExpanded: dayNum == dayKeys.first || i == 0,
          ),
        );
      }
    }

    if (activityIds.isNotEmpty) {
      rootChildren.add('schedule');
      components.add(<String, Object?>{
        'id': 'schedule',
        'component': 'RegimenDaySchedule',
        'dayNumbers': dayKeys,
        'children': activityIds,
      });
    }

    components.insert(0, <String, Object?>{
      'id': 'root',
      'component': 'Column',
      'align': 'stretch',
      'children': rootChildren,
    });

    return <Map<String, Object?>>[
      <String, Object?>{
        'version': A2uiProtocolVersion.v1_0.jsonValue,
        'createSurface': <String, Object?>{
          'surfaceId': surfaceId,
          'catalogId': kuboRegimenCatalogId,
          'components': components,
        },
      },
    ];
  }

  /// Builds an A2UI v1.0 `createSurface` payload for reviewing a single applied
  /// [CareTask] from the Care Tasks list.
  static List<Map<String, Object?>> buildTaskDetailMessages(
    CareTask task, {
    String surfaceId = 'task_detail',
    bool showActions = true,
  }) {
    final isPending = task.status == TaskStatus.pending;
    final rootCard = _activityCardComponent(
      id: 'root',
      task: task,
      dayNumber: task.dayNumber,
      mode: 'detail',
      initiallyExpanded: true,
      includeActions: showActions && isPending,
    );

    return <Map<String, Object?>>[
      <String, Object?>{
        'version': A2uiProtocolVersion.v1_0.jsonValue,
        'createSurface': <String, Object?>{
          'surfaceId': surfaceId,
          'catalogId': kuboRegimenCatalogId,
          'components': <Map<String, Object?>>[rootCard],
        },
      },
    ];
  }

  static Map<String, Object?> _activityCardComponent({
    required String id,
    required CareTask task,
    required int? dayNumber,
    required String mode,
    required bool initiallyExpanded,
    bool includeActions = false,
  }) {
    final domain = (task.montessoriDomain != null &&
            task.montessoriDomain!.trim().isNotEmpty)
        ? task.montessoriDomain!.trim()
        : task.category.displayName;

    return <String, Object?>{
      'id': id,
      'component': 'RegimenActivityCard',
      'activityId': task.id,
      'dayNumber': ?dayNumber,
      'time': task.time,
      'title': task.title,
      'description': task.description,
      'domain': domain,
      'category': task.category.displayName,
      'status': task.status.name,
      'mode': mode,
      'initiallyExpanded': initiallyExpanded,
      if (task.materialsTraySetup != null &&
          task.materialsTraySetup!.trim().isNotEmpty)
        'traySetup': task.materialsTraySetup!.trim(),
      'materials': task.materials,
      'steps': task.steps,
      if (task.scriptPrompt != null && task.scriptPrompt!.trim().isNotEmpty)
        'scriptPrompt': task.scriptPrompt!.trim(),
      if (task.dignityTip != null && task.dignityTip!.trim().isNotEmpty)
        'dignityTip': task.dignityTip!.trim(),
      if (task.safetyComfort != null && task.safetyComfort!.trim().isNotEmpty)
        'safetyComfort': task.safetyComfort!.trim(),
      if (task.historicalConnection != null &&
          task.historicalConnection!.trim().isNotEmpty)
        'historicalConnection': task.historicalConnection!.trim(),
      if (includeActions) ...<String, Object?>{
        'completeAction': <String, Object?>{
          'event': <String, Object?>{
            'name': 'mark_completed',
            'context': <String, Object?>{'taskId': task.id},
          },
        },
        'skipAction': <String, Object?>{
          'event': <String, Object?>{
            'name': 'skip_activity',
            'context': <String, Object?>{'taskId': task.id},
          },
        },
      },
    };
  }
}

/// Renders a Kubo Regimen A2UI v1.0 surface using the official `a2ui_flutter`
/// [A2uiSurface] renderer and [MessageProcessor].
class RegimenA2uiSurface extends StatefulWidget {
  final String surfaceId;
  final String contentKey;
  final List<Map<String, Object?>> messages;
  final void Function(A2uiRendererAction action)? onAction;

  const RegimenA2uiSurface({
    super.key,
    required this.surfaceId,
    required this.contentKey,
    required this.messages,
    this.onAction,
  });

  factory RegimenA2uiSurface.forPlan({
    Key? key,
    required RegimenPlan plan,
    void Function(A2uiRendererAction action)? onAction,
  }) {
    final surfaceId = 'regimen_preview_${plan.id}';
    return RegimenA2uiSurface(
      key: key,
      surfaceId: surfaceId,
      contentKey:
          '${plan.id}:${plan.items.length}:${plan.scorecard?.compositeScore}:${plan.safetyFlags.length}',
      messages: RegimenA2uiBlueprintBuilder.buildPlanPreviewMessages(
        plan,
        surfaceId: surfaceId,
      ),
      onAction: onAction,
    );
  }

  factory RegimenA2uiSurface.forTask({
    Key? key,
    required CareTask task,
    bool showActions = true,
    void Function(A2uiRendererAction action)? onAction,
  }) {
    final surfaceId = 'task_detail_${task.id}';
    return RegimenA2uiSurface(
      key: key,
      surfaceId: surfaceId,
      contentKey: '${task.id}:${task.status.name}:${task.steps.length}',
      messages: RegimenA2uiBlueprintBuilder.buildTaskDetailMessages(
        task,
        surfaceId: surfaceId,
        showActions: showActions,
      ),
      onAction: onAction,
    );
  }

  @override
  State<RegimenA2uiSurface> createState() => _RegimenA2uiSurfaceState();
}

class _RegimenA2uiSurfaceState extends State<RegimenA2uiSurface> {
  late MessageProcessor<ComponentImplementation> _processor;
  SurfaceModel<ComponentImplementation>? _surface;

  @override
  void initState() {
    super.initState();
    _initProcessor();
  }

  void _initProcessor() {
    _processor = MessageProcessor<ComponentImplementation>(
      catalogs: [
        kuboRegimenCatalog(),
        basicCatalog(),
      ],
      defaultVersion: A2uiProtocolVersion.v1_0,
      onAction: (action) {
        widget.onAction?.call(action);
      },
      onError: (error) {
        if (kDebugMode) {
          debugPrint('[RegimenA2uiSurface] A2UI error: $error');
        }
      },
    );
    _processor.processMessages(widget.messages);
    _surface = _processor.model.getSurface(widget.surfaceId);
  }

  @override
  void didUpdateWidget(covariant RegimenA2uiSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.surfaceId != widget.surfaceId ||
        oldWidget.contentKey != widget.contentKey) {
      _processor.dispose();
      _initProcessor();
    }
  }

  @override
  void dispose() {
    _processor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surface = _surface;
    if (surface == null) {
      return const SizedBox.shrink();
    }
    return A2uiSurface(surface: surface);
  }
}
