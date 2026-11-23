import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_config.dart';
import '../../data/fixtures/resident_fixtures.dart';
import '../../data/repositories/care_tasks_repository.dart';
import '../../domain/entities/regimen_plan.dart';
import '../../domain/entities/resident.dart';
import 'care_tasks_provider.dart';

class RegimenBatchCompletionEvent {
  final int eventId;
  final String residentId;
  final RegimenBatchJob job;

  const RegimenBatchCompletionEvent({
    required this.eventId,
    required this.residentId,
    required this.job,
  });
}

class RegimenBatchState {
  final Map<String, RegimenBatchJob?> jobsByResident;
  final bool isSubmitting;
  final String? lastError;
  final RegimenBatchCompletionEvent? lastCompletionEvent;

  const RegimenBatchState({
    this.jobsByResident = const {},
    this.isSubmitting = false,
    this.lastError,
    this.lastCompletionEvent,
  });

  RegimenBatchJob? jobForResident(String residentId) {
    final key = ResidentFixtures.toFixtureId(residentId);
    return jobsByResident[key];
  }

  bool hasActiveJobFor(String residentId) =>
      jobForResident(residentId)?.isActive ?? false;

  bool get hasAnyActiveJob =>
      jobsByResident.values.any((job) => job != null && job.isActive);

  RegimenBatchState copyWith({
    Map<String, RegimenBatchJob?>? jobsByResident,
    bool? isSubmitting,
    String? lastError,
    bool clearError = false,
    RegimenBatchCompletionEvent? lastCompletionEvent,
  }) {
    return RegimenBatchState(
      jobsByResident: jobsByResident ?? this.jobsByResident,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      lastError: clearError ? null : (lastError ?? this.lastError),
      lastCompletionEvent: lastCompletionEvent ?? this.lastCompletionEvent,
    );
  }
}

class RegimenBatchNotifier extends StateNotifier<RegimenBatchState> {
  final CareTasksRepository _repository;
  final Ref _ref;
  final Duration _pollInterval;
  Timer? _pollTimer;
  int _eventSeq = 0;

  RegimenBatchNotifier(
    this._repository,
    this._ref, {
    Duration? pollInterval,
  })  : _pollInterval = pollInterval ?? AppConfig.batchPollInterval,
        super(const RegimenBatchState());

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _syncPollingTimer() {
    if (!mounted) return;
    if (state.hasAnyActiveJob) {
      _pollTimer ??= Timer.periodic(_pollInterval, (_) => pollActiveJobs());
    } else {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  Future<void> pollActiveJobs() async {
    if (!mounted) return;
    final activeResidentIds = state.jobsByResident.entries
        .where((e) => e.value != null && e.value!.isActive)
        .map((e) => e.key)
        .toList();
    for (final residentId in activeResidentIds) {
      await refreshActiveJob(residentId);
    }
  }

  Future<void> refreshActiveJob(String residentId) async {
    final key = ResidentFixtures.toFixtureId(residentId);
    final previous = state.jobsByResident[key];
    try {
      var fetched = await _repository.getActiveBatchJob(key);
      if (previous != null &&
          previous.isActive &&
          (fetched == null ||
              (fetched.isCompleted &&
                  fetched.plan == null &&
                  fetched.planId != null))) {
        try {
          fetched = await _repository.getBatchJob(key, previous.id);
        } catch (_) {
          // Preserve fetched (or null) if direct job lookup fails transiently.
        }
      }
      if (!mounted) return;
      _applyJobUpdate(key, previous, fetched);
    } catch (_) {
      // FR-007: Preserve last-known banner state on transient polling errors.
    }
  }

  void _applyJobUpdate(
    String key,
    RegimenBatchJob? previous,
    RegimenBatchJob? next,
  ) {
    final updatedMap = Map<String, RegimenBatchJob?>.from(state.jobsByResident);
    updatedMap[key] = next;

    RegimenBatchCompletionEvent? event;
    if (previous != null &&
        previous.isActive &&
        next != null &&
        next.id == previous.id &&
        (next.isCompleted || next.isFailed)) {
      event = RegimenBatchCompletionEvent(
        eventId: ++_eventSeq,
        residentId: key,
        job: next,
      );
      if (next.isCompleted && next.plan != null) {
        if (next.plan!.planStatus == 'applied') {
          _ref.read(careTasksProvider.notifier).loadTasks();
        } else {
          _ref
              .read(careTasksProvider.notifier)
              .setPreviewPlanFromBatch(next.plan!);
        }
      }
    }

    state = state.copyWith(
      jobsByResident: updatedMap,
      lastCompletionEvent: event,
    );
    _syncPollingTimer();
  }

  Future<RegimenBatchJob?> enqueueGeneration(
    Resident resident, {
    DateTime? weekStartDate,
  }) async {
    final key = ResidentFixtures.toFixtureId(resident.id);
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final job = await _repository.enqueueWeeklyRegimen(
        resident: resident,
        weekStartDate: weekStartDate,
        autoApply: false,
      );
      if (!mounted) return job;
      final updatedMap =
          Map<String, RegimenBatchJob?>.from(state.jobsByResident);
      updatedMap[key] = job;
      state = state.copyWith(
        jobsByResident: updatedMap,
        isSubmitting: false,
      );
      _syncPollingTimer();
      return job;
    } on RegimenBatchConflictException catch (e) {
      if (!mounted) return e.activeJob;
      final updatedMap =
          Map<String, RegimenBatchJob?>.from(state.jobsByResident);
      if (e.activeJob != null) {
        updatedMap[key] = e.activeJob;
      }
      state = state.copyWith(
        jobsByResident: updatedMap,
        isSubmitting: false,
        lastError: e.message,
      );
      _syncPollingTimer();
      return e.activeJob;
    } catch (e) {
      if (!mounted) rethrow;
      state = state.copyWith(
        isSubmitting: false,
        lastError: e.toString(),
      );
      rethrow;
    }
  }

  Future<RegimenBatchJob?> enqueueRefinement({
    required String residentId,
    required String planId,
    required String instruction,
    DateTime? weekStartDate,
  }) async {
    final key = ResidentFixtures.toFixtureId(residentId);
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final job = await _repository.enqueueRefinement(
        residentId: key,
        planId: planId,
        instruction: instruction,
        weekStartDate: weekStartDate,
      );
      if (!mounted) return job;
      final updatedMap =
          Map<String, RegimenBatchJob?>.from(state.jobsByResident);
      updatedMap[key] = job;
      state = state.copyWith(
        jobsByResident: updatedMap,
        isSubmitting: false,
      );
      _syncPollingTimer();
      return job;
    } on RegimenBatchConflictException catch (e) {
      if (!mounted) return e.activeJob;
      final updatedMap =
          Map<String, RegimenBatchJob?>.from(state.jobsByResident);
      if (e.activeJob != null) {
        updatedMap[key] = e.activeJob;
      }
      state = state.copyWith(
        jobsByResident: updatedMap,
        isSubmitting: false,
        lastError: e.message,
      );
      _syncPollingTimer();
      return e.activeJob;
    } catch (e) {
      if (!mounted) rethrow;
      state = state.copyWith(
        isSubmitting: false,
        lastError: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> cancelActiveJob(String residentId) async {
    final key = ResidentFixtures.toFixtureId(residentId);
    final current = state.jobsByResident[key];
    if (current == null || !current.isActive) return;

    try {
      await _repository.cancelBatchJob(key, current.id);
      if (!mounted) return;
      final updatedMap =
          Map<String, RegimenBatchJob?>.from(state.jobsByResident);
      updatedMap[key] = null;
      state = state.copyWith(jobsByResident: updatedMap, clearError: true);
      _syncPollingTimer();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(lastError: e.toString());
    }
  }

  Future<void> dismissJob(String residentId) async {
    final key = ResidentFixtures.toFixtureId(residentId);
    final current = state.jobsByResident[key];
    if (current == null || current.isActive) return;

    try {
      await _repository.dismissBatchJob(key, current.id);
      if (!mounted) return;
      final updatedMap =
          Map<String, RegimenBatchJob?>.from(state.jobsByResident);
      updatedMap[key] = null;
      state = state.copyWith(jobsByResident: updatedMap, clearError: true);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(lastError: e.toString());
    }
  }

  void clearResidentBannerLocally(String residentId) {
    final key = ResidentFixtures.toFixtureId(residentId);
    if (!state.jobsByResident.containsKey(key)) return;
    final updatedMap = Map<String, RegimenBatchJob?>.from(state.jobsByResident);
    updatedMap[key] = null;
    state = state.copyWith(jobsByResident: updatedMap);
    _syncPollingTimer();
  }

  Future<RegimenPlan?> applyImmediateBaseline(
    Resident resident, {
    DateTime? weekStartDate,
  }) async {
    final key = ResidentFixtures.toFixtureId(resident.id);
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final plan = await _repository.applyImmediateBaseline(
        resident: resident,
        weekStartDate: weekStartDate,
        autoApply: true,
      );
      if (!mounted) return plan;
      final updatedMap =
          Map<String, RegimenBatchJob?>.from(state.jobsByResident);
      updatedMap[key] = null;
      state = state.copyWith(
        jobsByResident: updatedMap,
        isSubmitting: false,
      );
      _syncPollingTimer();
      await _ref.read(careTasksProvider.notifier).loadTasks();
      return plan;
    } catch (e) {
      if (!mounted) rethrow;
      state = state.copyWith(
        isSubmitting: false,
        lastError: e.toString(),
      );
      rethrow;
    }
  }

  Future<RegimenBatchJob?> retryFailedJob(Resident resident) async {
    final key = ResidentFixtures.toFixtureId(resident.id);
    final failedJob = state.jobsByResident[key];
    if (failedJob != null && failedJob.isFailed) {
      try {
        await _repository.dismissBatchJob(key, failedJob.id);
      } catch (_) {}
    }
    if (failedJob != null &&
        failedJob.jobType == BatchJobType.refinement &&
        failedJob.targetPlanId != null &&
        (failedJob.refinementInstruction?.isNotEmpty ?? false)) {
      return enqueueRefinement(
        residentId: key,
        planId: failedJob.targetPlanId!,
        instruction: failedJob.refinementInstruction!,
        weekStartDate: failedJob.weekStartDate,
      );
    }
    return enqueueGeneration(
      resident,
      weekStartDate: failedJob?.weekStartDate,
    );
  }
}

final regimenBatchProvider =
    StateNotifierProvider<RegimenBatchNotifier, RegimenBatchState>((ref) {
  final repo = ref.watch(careTasksRepositoryProvider);
  return RegimenBatchNotifier(repo, ref);
});
