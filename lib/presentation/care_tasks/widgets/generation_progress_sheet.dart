import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/regimen_plan.dart';
import '../../../domain/entities/resident.dart';
import '../care_tasks_provider.dart';

class GenerationProgressSheet extends ConsumerStatefulWidget {
  final Resident resident;

  const GenerationProgressSheet({super.key, required this.resident});

  @override
  ConsumerState<GenerationProgressSheet> createState() =>
      _GenerationProgressSheetState();
}

class _GenerationProgressSheetState
    extends ConsumerState<GenerationProgressSheet> {
  static const _steps = [
    RegimenGenerationPhase.retrieval,
    RegimenGenerationPhase.synthesis,
    RegimenGenerationPhase.scoring,
  ];

  Timer? _elapsedTimer;
  int _elapsedSeconds = 0;
  bool _switchingToBaseline = false;

  @override
  void initState() {
    super.initState();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsedSeconds++);
      }
    });
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    super.dispose();
  }

  Future<void> _switchToBaseline() async {
    if (_switchingToBaseline) return;
    setState(() => _switchingToBaseline = true);
    try {
      await ref
          .read(careTasksProvider.notifier)
          .cancelAndSwitchToBaseline(widget.resident);
    } finally {
      if (mounted) {
        setState(() => _switchingToBaseline = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(careTasksProvider);
    final phase = taskState.generationPhase;
    final activeIdx = _steps.indexOf(phase);
    final remaining = (75 - _elapsedSeconds).clamp(0, 75);

    return PopScope(
      canPop: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Kubo is building a 7-day regimen',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Text(
                  '${_elapsedSeconds}s (${remaining}s left)',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              phase.description,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(_steps.length, (idx) {
              final step = _steps[idx];
              final isDone = phase == RegimenGenerationPhase.completed ||
                  (activeIdx != -1 && idx < activeIdx);
              final isCurrent = idx == activeIdx;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Icon(
                      isDone
                          ? Icons.check_circle
                          : isCurrent
                              ? Icons.pending_outlined
                              : Icons.radio_button_unchecked,
                      size: 18,
                      color: (isDone || isCurrent)
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      step.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.w500,
                        color: (isDone || isCurrent)
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _switchingToBaseline ? null : _switchToBaseline,
                icon: const Icon(Icons.flash_on_outlined, size: 18),
                label: Text(_switchingToBaseline
                    ? 'Switching to Baseline...'
                    : 'Use Clinical Baseline Instead'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
