import 'dart:math' as math;

import 'package:a2ui_core/a2ui_core.dart';
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:a2ui_flutter/basic_catalog.dart';
import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../core/theme/app_colors.dart';
import 'step_text_formatter.dart';

/// Canonical Kubo A2UI v1.0 catalog ID for Montessori regimen review surfaces.
const String kuboRegimenCatalogId = 'https://kubo.care/a2ui/catalogs/regimen/v1';

/// Builds the Kubo Regimen A2UI v1.0 [CatalogImplementation], extending the
/// official [BasicComponents.all] catalog with rich clinical & Montessori
/// regimen review components.
CatalogImplementation kuboRegimenCatalog({
  String locale = 'en-US',
  OpenUrlCallback? openUrl,
}) {
  final base = basicCatalog(locale: locale, openUrl: openUrl);
  return CatalogImplementation(
    id: kuboRegimenCatalogId,
    components: [
      ...BasicComponents.all,
      KuboRegimenComponents.clinicalScorecard,
      KuboRegimenComponents.daySchedule,
      KuboRegimenComponents.activityCard,
    ],
    functions: base.functions.values.toList(),
    schemaId: base.schemaId,
    title: 'Kubo Montessori Regimen A2UI Catalog',
    description:
        'Custom A2UI v1.0 components for clinical scorecards, 7-day Montessori regimen schedules, and caregiver facilitation guides.',
    protocolVersion: A2uiProtocolVersion.v1_0,
    definitions: base.definitions,
  );
}

abstract final class KuboRegimenComponents {
  /// Visual clinical rubric scorecard with composite gauge, safety guidelines,
  /// and 5 Montessori evaluation pillars.
  static final ComponentImplementation clinicalScorecard =
      ComponentImplementation(
    name: 'RegimenClinicalScorecard',
    schema: Schema.fromMap(const <String, Object?>{
      'type': 'object',
      'properties': <String, Object?>{
        'component': <String, Object?>{'const': 'RegimenClinicalScorecard'},
        'generationSource': <String, Object?>{'type': 'string'},
        'compositeScore': <String, Object?>{'type': 'number'},
        'cognitiveScore': <String, Object?>{'type': 'number'},
        'physicalScore': <String, Object?>{'type': 'number'},
        'engagementScore': <String, Object?>{'type': 'number'},
        'safetyScore': <String, Object?>{'type': 'number'},
        'balanceScore': <String, Object?>{'type': 'number'},
        'feedback': <String, Object?>{'type': 'string'},
        'isLowScore': <String, Object?>{'type': 'boolean'},
        'isBlocked': <String, Object?>{'type': 'boolean'},
        'safetyFlags': <String, Object?>{
          'type': 'array',
          'items': <String, Object?>{'type': 'string'},
        },
      },
      'required': <Object?>['component'],
    }),
    builder: _buildClinicalScorecard,
  );

  /// Interactive 7-day schedule switcher with thumb-friendly day pills and an
  /// optional "All Days" view, rendering child [RegimenActivityCard] nodes.
  static final ComponentImplementation daySchedule = ComponentImplementation(
    name: 'RegimenDaySchedule',
    schema: Schema.fromMap(const <String, Object?>{
      'type': 'object',
      'properties': <String, Object?>{
        'component': <String, Object?>{'const': 'RegimenDaySchedule'},
        'dayNumbers': <String, Object?>{
          'type': 'array',
          'items': <String, Object?>{'type': 'number'},
        },
        'children': <String, Object?>{
          r'$ref': r'common_types.json#/$defs/ChildList',
        },
      },
      'required': <Object?>['component', 'children'],
    }),
    builder: _buildDaySchedule,
  );

  /// Tactile Montessori activity card used both in 7-day regimen previews and
  /// in applied Care Task detail reviews.
  static final ComponentImplementation activityCard = ComponentImplementation(
    name: 'RegimenActivityCard',
    schema: Schema.fromMap(const <String, Object?>{
      'type': 'object',
      'properties': <String, Object?>{
        'component': <String, Object?>{'const': 'RegimenActivityCard'},
        'activityId': <String, Object?>{'type': 'string'},
        'dayNumber': <String, Object?>{'type': 'number'},
        'time': <String, Object?>{'type': 'string'},
        'title': <String, Object?>{'type': 'string'},
        'description': <String, Object?>{'type': 'string'},
        'domain': <String, Object?>{'type': 'string'},
        'category': <String, Object?>{'type': 'string'},
        'status': <String, Object?>{'type': 'string'},
        'mode': <String, Object?>{
          'type': 'string',
          'enum': <Object?>['preview', 'detail'],
          'default': 'preview',
        },
        'initiallyExpanded': <String, Object?>{'type': 'boolean'},
        'traySetup': <String, Object?>{'type': 'string'},
        'materials': <String, Object?>{
          'type': 'array',
          'items': <String, Object?>{'type': 'string'},
        },
        'steps': <String, Object?>{
          'type': 'array',
          'items': <String, Object?>{'type': 'string'},
        },
        'scriptPrompt': <String, Object?>{'type': 'string'},
        'dignityTip': <String, Object?>{'type': 'string'},
        'safetyComfort': <String, Object?>{'type': 'string'},
        'historicalConnection': <String, Object?>{'type': 'string'},
        'completeAction': <String, Object?>{
          r'$ref': r'common_types.json#/$defs/Action',
        },
        'skipAction': <String, Object?>{
          r'$ref': r'common_types.json#/$defs/Action',
        },
      },
      'required': <Object?>['component', 'title'],
    }),
    builder: _buildActivityCard,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Component 1: RegimenClinicalScorecard
// ─────────────────────────────────────────────────────────────────────────────

Widget _buildClinicalScorecard(
  BuildContext context,
  ComponentNode<ComponentImplementation> node,
  ComponentProps props,
  ChildWidgetBuilder buildChild,
) {
  final composite = props.number('compositeScore')?.round();
  final cognitive = props.number('cognitiveScore')?.round() ?? 0;
  final physical = props.number('physicalScore')?.round() ?? 0;
  final engagement = props.number('engagementScore')?.round() ?? 0;
  final safety = props.number('safetyScore')?.round() ?? 0;
  final balance = props.number('balanceScore')?.round() ?? 0;
  final feedback = props.string('feedback') ?? '';
  final source = props.string('generationSource') ?? '';
  final isLowScore = props.boolean('isLowScore') ?? (composite != null && composite < 70);
  final isBlocked = props.boolean('isBlocked') ?? false;
  final safetyFlags = props
      .list('safetyFlags')
      .map(ComponentProps.asString)
      .whereType<String>()
      .where((s) => s.trim().isNotEmpty)
      .toList(growable: false);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (safetyFlags.isNotEmpty || isBlocked) ...[
        _SafetyCalloutCard(
          isBlocked: isBlocked,
          safetyFlags: safetyFlags,
        ),
        const SizedBox(height: 12),
      ],
      if (composite != null)
        Container(
          key: const Key('a2ui_clinical_scorecard'),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isLowScore
                  ? Colors.orange.shade300
                  : AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _ScoreRingGauge(
                    score: composite,
                    isLowScore: isLowScore,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Clinical Quality Score',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (source.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    source,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isLowScore
                              ? 'Below 70/100 — review carefully and confirm supervision before applying.'
                              : 'Clinically aligned across Montessori domains and resident capabilities.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            color: isLowScore
                                ? Colors.orange.shade900
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _RubricMetricChip(
                    label: 'Cognitive: $cognitive',
                    ratio: cognitive / 25.0,
                    icon: Icons.psychology_outlined,
                  ),
                  _RubricMetricChip(
                    label: 'Physical: $physical',
                    ratio: physical / 20.0,
                    icon: Icons.accessibility_new_outlined,
                  ),
                  _RubricMetricChip(
                    label: 'Engagement: $engagement',
                    ratio: engagement / 20.0,
                    icon: Icons.auto_awesome_outlined,
                  ),
                  _RubricMetricChip(
                    label: 'Safety: $safety',
                    ratio: safety / 15.0,
                    icon: Icons.shield_outlined,
                  ),
                  _RubricMetricChip(
                    label: 'Balance: $balance',
                    ratio: balance / 20.0,
                    icon: Icons.balance_outlined,
                  ),
                ],
              ),
              if (feedback.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.medical_information_outlined,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feedback,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
    ],
  );
}

class _SafetyCalloutCard extends StatelessWidget {
  final bool isBlocked;
  final List<String> safetyFlags;

  const _SafetyCalloutCard({
    required this.isBlocked,
    required this.safetyFlags,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isBlocked ? AppColors.allergyRedBg : const Color(0xFFFFF8E6);
    final borderColor =
        isBlocked ? Colors.red.shade300 : const Color(0xFFF3CF7A);
    final accentColor =
        isBlocked ? AppColors.statusRed : const Color(0xFF946200);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isBlocked
                    ? Icons.gpp_bad_outlined
                    : Icons.health_and_safety_outlined,
                size: 18,
                color: accentColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isBlocked
                      ? 'Clinical Safety Hold: Escalation Required'
                      : 'Safety & Comfort Guidelines',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          if (safetyFlags.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...safetyFlags.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScoreRingGauge extends StatelessWidget {
  final int score;
  final bool isLowScore;

  const _ScoreRingGauge({
    required this.score,
    required this.isLowScore,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = score.clamp(0, 100);
    final ringColor = isLowScore ? Colors.orange.shade700 : AppColors.primary;
    return SizedBox(
      width: 58,
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 58,
            height: 58,
            child: CircularProgressIndicator(
              value: clamped / 100.0,
              strokeWidth: 5.5,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(ringColor),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$clamped',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: ringColor,
                  height: 1.0,
                ),
              ),
              const Text(
                '/100',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RubricMetricChip extends StatelessWidget {
  final String label;
  final double ratio;
  final IconData icon;

  const _RubricMetricChip({
    required this.label,
    required this.ratio,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final clampedRatio = ratio.clamp(0.0, 1.0);
    final accent = clampedRatio < 0.65
        ? Colors.orange.shade700
        : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Component 2: RegimenDaySchedule
// ─────────────────────────────────────────────────────────────────────────────

Widget _buildDaySchedule(
  BuildContext context,
  ComponentNode<ComponentImplementation> node,
  ComponentProps props,
  ChildWidgetBuilder buildChild,
) {
  final children = props.children('children');
  final declaredDays = props
      .list('dayNumbers')
      .map(ComponentProps.asNumber)
      .whereType<double>()
      .map((d) => d.round())
      .toList(growable: false);

  return _RegimenDayScheduleWidget(
    declaredDays: declaredDays,
    children: children,
    buildChild: buildChild,
  );
}

class _RegimenDayScheduleWidget extends StatefulWidget {
  final List<int> declaredDays;
  final List<ComponentNode<ComponentImplementation>> children;
  final ChildWidgetBuilder buildChild;

  const _RegimenDayScheduleWidget({
    required this.declaredDays,
    required this.children,
    required this.buildChild,
  });

  @override
  State<_RegimenDayScheduleWidget> createState() =>
      _RegimenDayScheduleWidgetState();
}

class _RegimenDayScheduleWidgetState extends State<_RegimenDayScheduleWidget> {
  int? _selectedDay; // null means "All Days"

  @override
  void initState() {
    super.initState();
    final days = _availableDays();
    _selectedDay = days.isNotEmpty ? days.first : null;
  }

  List<int> _availableDays() {
    if (widget.declaredDays.isNotEmpty) {
      final sorted = widget.declaredDays.toSet().toList()..sort();
      return sorted;
    }
    final days = <int>{};
    for (final child in widget.children) {
      final day = _dayOf(child);
      if (day != null) days.add(day);
    }
    final sorted = days.toList()..sort();
    return sorted;
  }

  int? _dayOf(ComponentNode<ComponentImplementation> child) {
    final raw = ComponentProps(child.props.peek()).number('dayNumber');
    return raw?.round();
  }

  @override
  Widget build(BuildContext context) {
    final days = _availableDays();
    if (_selectedDay != null && days.isNotEmpty && !days.contains(_selectedDay)) {
      _selectedDay = days.first;
    }

    final countsByDay = <int, int>{};
    for (final child in widget.children) {
      final d = _dayOf(child) ?? 1;
      countsByDay[d] = (countsByDay[d] ?? 0) + 1;
    }

    final visibleChildren = _selectedDay == null
        ? widget.children
        : widget.children
            .where((c) => (_dayOf(c) ?? 1) == _selectedDay)
            .toList(growable: false);

    return Column(
      key: const Key('a2ui_regimen_day_schedule'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (days.length > 1) ...[
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: days.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                if (idx == days.length) {
                  final isAll = _selectedDay == null;
                  return ChoiceChip(
                    key: const Key('a2ui_day_pill_all'),
                    label: Text('All (${widget.children.length})'),
                    selected: isAll,
                    onSelected: (_) => setState(() => _selectedDay = null),
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    side: BorderSide(
                      color: isAll ? AppColors.primary : AppColors.border,
                    ),
                    labelStyle: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isAll ? Colors.white : AppColors.textPrimary,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                  );
                }
                final dayNum = days[idx];
                final count = countsByDay[dayNum] ?? 0;
                final isSelected = _selectedDay == dayNum;
                return ChoiceChip(
                  key: Key('a2ui_day_pill_$dayNum'),
                  label: Text('Day $dayNum ($count)'),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedDay = dayNum),
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                  labelStyle: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                );
              },
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (_selectedDay != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text(
                  'Day $_selectedDay',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${visibleChildren.length} ${visibleChildren.length == 1 ? 'activity' : 'activities'}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ...visibleChildren.map(
          (child) => KeyedSubtree(
            key: NodeKey(child.instanceId),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: widget.buildChild(child),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Component 3: RegimenActivityCard
// ─────────────────────────────────────────────────────────────────────────────

Widget _buildActivityCard(
  BuildContext context,
  ComponentNode<ComponentImplementation> node,
  ComponentProps props,
  ChildWidgetBuilder buildChild,
) {
  final title = props.string('title') ?? 'Montessori Activity';
  final description = props.string('description') ?? '';
  final time = props.string('time') ?? '';
  final domain = props.string('domain') ?? 'Montessori';
  final category = props.string('category') ?? '';
  final status = props.string('status') ?? '';
  final dayNumber = props.number('dayNumber')?.round();
  final mode = props.string('mode') ?? 'preview';
  final isDetail = mode == 'detail';
  final initiallyExpanded = props.boolean('initiallyExpanded') ?? isDetail;
  final traySetup = props.string('traySetup') ?? '';
  final materials = props
      .list('materials')
      .map(ComponentProps.asString)
      .whereType<String>()
      .where((s) => s.trim().isNotEmpty)
      .toList(growable: false);
  final steps = props
      .list('steps')
      .map(ComponentProps.asString)
      .whereType<String>()
      .where((s) => s.trim().isNotEmpty)
      .toList(growable: false);
  final scriptPrompt = props.string('scriptPrompt') ?? '';
  final dignityTip = props.string('dignityTip') ?? '';
  final safetyComfort = props.string('safetyComfort') ?? '';
  final historicalConnection = props.string('historicalConnection') ?? '';
  final completeAction = props.action('completeAction');
  final skipAction = props.action('skipAction');

  return _RegimenActivityCardWidget(
    title: title,
    description: description,
    time: time,
    domain: domain,
    category: category,
    status: status,
    dayNumber: dayNumber,
    isDetail: isDetail,
    initiallyExpanded: initiallyExpanded,
    traySetup: traySetup,
    materials: materials,
    steps: steps,
    scriptPrompt: scriptPrompt,
    dignityTip: dignityTip,
    safetyComfort: safetyComfort,
    historicalConnection: historicalConnection,
    completeAction: completeAction,
    skipAction: skipAction,
  );
}

class _RegimenActivityCardWidget extends StatefulWidget {
  final String title;
  final String description;
  final String time;
  final String domain;
  final String category;
  final String status;
  final int? dayNumber;
  final bool isDetail;
  final bool initiallyExpanded;
  final String traySetup;
  final List<String> materials;
  final List<String> steps;
  final String scriptPrompt;
  final String dignityTip;
  final String safetyComfort;
  final String historicalConnection;
  final NodeAction? completeAction;
  final NodeAction? skipAction;

  const _RegimenActivityCardWidget({
    required this.title,
    required this.description,
    required this.time,
    required this.domain,
    required this.category,
    required this.status,
    required this.dayNumber,
    required this.isDetail,
    required this.initiallyExpanded,
    required this.traySetup,
    required this.materials,
    required this.steps,
    required this.scriptPrompt,
    required this.dignityTip,
    required this.safetyComfort,
    required this.historicalConnection,
    required this.completeAction,
    required this.skipAction,
  });

  @override
  State<_RegimenActivityCardWidget> createState() =>
      _RegimenActivityCardWidgetState();
}

class _RegimenActivityCardWidgetState
    extends State<_RegimenActivityCardWidget> {
  late bool _expanded;
  final Set<int> _checkedMaterials = <int>{};

  @override
  void initState() {
    super.initState();
    _expanded = widget.isDetail || widget.initiallyExpanded;
  }

  ({Color bg, Color fg, IconData icon}) _domainPalette() {
    final norm = '${widget.domain} ${widget.category}'.toLowerCase();
    if (norm.contains('physical') || norm.contains('practical')) {
      return (
        bg: AppColors.badgePhysical,
        fg: AppColors.badgePhysicalText,
        icon: Icons.handyman_outlined,
      );
    }
    if (norm.contains('sensor')) {
      return (
        bg: AppColors.badgeActivity,
        fg: AppColors.badgeActivityText,
        icon: Icons.spa_outlined,
      );
    }
    if (norm.contains('social') || norm.contains('cultural')) {
      return (
        bg: AppColors.badgeSocial,
        fg: AppColors.badgeSocialText,
        icon: Icons.groups_outlined,
      );
    }
    return (
      bg: AppColors.surfaceVariant,
      fg: AppColors.primary,
      icon: Icons.psychology_alt_outlined,
    );
  }

  Widget _buildStatusPill() {
    final norm = widget.status.toLowerCase();
    if (norm.isEmpty) return const SizedBox.shrink();
    final (Color bg, Color fg, IconData icon, String text) = switch (norm) {
      'completed' => (
          AppColors.primaryLight,
          AppColors.primary,
          Icons.check_circle_outline,
          'Completed',
        ),
      'skipped' => (
          const Color(0xFFFFF2CC),
          const Color(0xFF7F6000),
          Icons.fast_forward_outlined,
          'Skipped',
        ),
      _ => (
          AppColors.surfaceContainerLow,
          AppColors.textSecondary,
          Icons.schedule,
          'Scheduled',
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = _domainPalette();
    final parsedSteps =
        widget.steps.map(parseFacilitationStep).toList(growable: false);

    final hasGuidance = widget.scriptPrompt.isNotEmpty ||
        widget.dignityTip.isNotEmpty ||
        widget.safetyComfort.isNotEmpty ||
        widget.historicalConnection.isNotEmpty;

    final showDescription = widget.description.isNotEmpty &&
        widget.description.trim().toLowerCase() !=
            widget.title.trim().toLowerCase();

    return Container(
      key: Key(
        widget.isDetail
            ? 'a2ui_activity_detail_card'
            : 'a2ui_activity_preview_card',
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          InkWell(
            onTap: widget.isDetail
                ? null
                : () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (widget.time.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 13,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.time,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: palette.bg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(palette.icon, size: 13, color: palette.fg),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  widget.domain,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: palette.fg,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (widget.isDetail) _buildStatusPill(),
                      if (!widget.isDetail) ...[
                        const Spacer(),
                        Icon(
                          _expanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: widget.isDetail ? 18 : 15.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.25,
                    ),
                  ),
                  if (showDescription) ...[
                    const SizedBox(height: 6),
                    Text(
                      widget.description,
                      maxLines: _expanded ? null : 2,
                      overflow:
                          _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  if (!_expanded) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        if (widget.materials.isNotEmpty)
                          _CompactCountBadge(
                            icon: Icons.inventory_2_outlined,
                            label: '${widget.materials.length} materials',
                          ),
                        if (parsedSteps.isNotEmpty)
                          _CompactCountBadge(
                            icon: Icons.format_list_numbered,
                            label: '${parsedSteps.length} steps',
                          ),
                        if (widget.historicalConnection.isNotEmpty)
                          const _CompactCountBadge(
                            icon: Icons.favorite_outline,
                            label: 'Memory link',
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          if (_expanded) ...[
            const Divider(height: 1, color: AppColors.borderLight),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tray Setup & Materials Section
                  if (widget.traySetup.isNotEmpty ||
                      widget.materials.isNotEmpty) ...[
                    _SectionContainer(
                      icon: Icons.inventory_2_outlined,
                      title: 'Tray & Materials',
                      backgroundColor: AppColors.surfaceContainerLow,
                      borderColor: AppColors.borderLight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.traySetup.isNotEmpty) ...[
                            Text(
                              'Tray setup: ${widget.traySetup}',
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (widget.materials.isNotEmpty)
                              const SizedBox(height: 10),
                          ],
                          if (widget.materials.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: widget.materials
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                final checked =
                                    _checkedMaterials.contains(entry.key);
                                return InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    setState(() {
                                      if (checked) {
                                        _checkedMaterials.remove(entry.key);
                                      } else {
                                        _checkedMaterials.add(entry.key);
                                      }
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: checked
                                          ? AppColors.primaryLight
                                          : AppColors.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: checked
                                            ? AppColors.primary
                                            : AppColors.border,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          checked
                                              ? Icons.check_box
                                              : Icons.check_box_outline_blank,
                                          size: 16,
                                          color: checked
                                              ? AppColors.primary
                                              : AppColors.textMuted,
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            entry.value,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              height: 1.25,
                                              color: AppColors.textPrimary,
                                              decoration: checked
                                                  ? TextDecoration.lineThrough
                                                  : TextDecoration.none,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(growable: false),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Facilitation Steps Stepper
                  if (parsedSteps.isNotEmpty) ...[
                    const Row(
                      children: [
                        Icon(
                          Icons.route_outlined,
                          size: 17,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Facilitation Steps',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...parsedSteps.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final step = entry.value;
                      final isLast = idx == parsedSteps.length - 1;
                      return _FacilitationStepRow(
                        stepNumber: idx + 1,
                        step: step,
                        isLast: isLast,
                      );
                    }),
                  ],

                  // Caregiver Guidance Callouts
                  if (hasGuidance) ...[
                    const SizedBox(height: 12),
                    if (widget.scriptPrompt.isNotEmpty) ...[
                      _GuidanceCallout(
                        icon: Icons.format_quote_rounded,
                        label: 'Warm Invitation',
                        content: 'Prompt: "${widget.scriptPrompt}"',
                        bgColor: const Color(0xFFF0F7F4),
                        borderColor: AppColors.primaryLight,
                        accentColor: AppColors.primary,
                        italic: true,
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (widget.dignityTip.isNotEmpty) ...[
                      _GuidanceCallout(
                        icon: Icons.volunteer_activism_outlined,
                        label: 'Dignity Approach',
                        content: 'Dignity tip: ${widget.dignityTip}',
                        bgColor: const Color(0xFFF6F9FC),
                        borderColor: const Color(0xFFD5E4F0),
                        accentColor: AppColors.badgeSocialText,
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (widget.safetyComfort.isNotEmpty) ...[
                      _GuidanceCallout(
                        icon: Icons.health_and_safety_outlined,
                        label: 'Safety & Comfort',
                        content: 'Safety & comfort: ${widget.safetyComfort}',
                        bgColor: const Color(0xFFFFFBF0),
                        borderColor: const Color(0xFFF2DFB0),
                        accentColor: const Color(0xFF8A5A00),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (widget.historicalConnection.isNotEmpty) ...[
                      _GuidanceCallout(
                        icon: Icons.auto_stories_outlined,
                        label: 'Personal Memory Link',
                        content: 'Memory link: ${widget.historicalConnection}',
                        bgColor: AppColors.surfaceContainerLow,
                        borderColor: AppColors.borderLight,
                        accentColor: AppColors.secondary,
                        italic: true,
                      ),
                    ],
                  ],

                  // Action Bar (Applied Task Detail mode)
                  if (widget.completeAction != null ||
                      widget.skipAction != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (widget.skipAction != null)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => widget.skipAction!.call(),
                              icon: const Icon(Icons.fast_forward, size: 18),
                              label: const Text('Skip'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 46),
                              ),
                            ),
                          ),
                        if (widget.skipAction != null &&
                            widget.completeAction != null)
                          const SizedBox(width: 12),
                        if (widget.completeAction != null)
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () => widget.completeAction!.call(),
                              icon: const Icon(
                                Icons.check_circle_outline,
                                size: 18,
                              ),
                              label: const Text('Mark Completed'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 46),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompactCountBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _CompactCountBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _SectionContainer extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color backgroundColor;
  final Color borderColor;
  final Widget child;

  const _SectionContainer({
    required this.icon,
    required this.title,
    required this.backgroundColor,
    required this.borderColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _FacilitationStepRow extends StatelessWidget {
  final int stepNumber;
  final ParsedFacilitationStep step;
  final bool isLast;

  const _FacilitationStepRow({
    required this.stepNumber,
    required this.step,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$stepNumber',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      color: AppColors.primaryLight,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (step.heading != null) ...[
                    Text(
                      step.heading!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    step.body,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuidanceCallout extends StatelessWidget {
  final IconData icon;
  final String label;
  final String content;
  final Color bgColor;
  final Color borderColor;
  final Color accentColor;
  final bool italic;

  const _GuidanceCallout({
    required this.icon,
    required this.label,
    required this.content,
    required this.bgColor,
    required this.borderColor,
    required this.accentColor,
    this.italic = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 16, color: accentColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Keep dart:math referenced if needed for future gauge arcs.
double clampRatio(num value, num maxValue) =>
    maxValue <= 0 ? 0.0 : math.min(1.0, math.max(0.0, value / maxValue));
