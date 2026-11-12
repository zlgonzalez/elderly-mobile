import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/care_tasks_repository.dart';
import '../../domain/entities/care_task.dart';
import '../../domain/entities/regimen_plan.dart';
import '../../domain/entities/resident.dart';
import '../family_portal/resident_provider.dart';

class CareTasksState {
  final List<CareTask> tasks;
  final bool isLoading;
  final TaskCategory? selectedCategory;
  final RegimenPlan? activePreviewPlan;
  final RegimenPlan? latestAppliedPlan;
  final RegimenGenerationPhase generationPhase;
  final bool isGenerating;
  final String? generationError;

  const CareTasksState({
    this.tasks = const [],
    this.isLoading = false,
    this.selectedCategory,
    this.activePreviewPlan,
    this.latestAppliedPlan,
    this.generationPhase = RegimenGenerationPhase.idle,
    this.isGenerating = false,
    this.generationError,
  });

  int get totalCount => tasks.length;
  int get completedCount =>
      tasks.where((t) => t.status == TaskStatus.completed).length;
  double get progress => totalCount == 0 ? 0.0 : (completedCount / totalCount);

  List<CareTask> get filteredTasks {
    if (selectedCategory == null) return tasks;
    return tasks.where((t) => t.category == selectedCategory).toList();
  }

  CareTasksState copyWith({
    List<CareTask>? tasks,
    bool? isLoading,
    TaskCategory? selectedCategory,
    bool clearCategory = false,
    RegimenPlan? activePreviewPlan,
    bool clearPreviewPlan = false,
    RegimenPlan? latestAppliedPlan,
    RegimenGenerationPhase? generationPhase,
    bool? isGenerating,
    String? generationError,
    bool clearError = false,
  }) {
    return CareTasksState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      selectedCategory:
          clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      activePreviewPlan:
          clearPreviewPlan ? null : (activePreviewPlan ?? this.activePreviewPlan),
      latestAppliedPlan: latestAppliedPlan ?? this.latestAppliedPlan,
      generationPhase: generationPhase ?? this.generationPhase,
      isGenerating: isGenerating ?? this.isGenerating,
      generationError:
          clearError ? null : (generationError ?? this.generationError),
    );
  }
}

class CareTasksNotifier extends StateNotifier<CareTasksState> {
  final CareTasksRepository _repository;
  final String _residentId;
  int _generationToken = 0;
  int _loadTasksToken = 0;
  Completer<RegimenPlan?>? _activeGenerationCompleter;

  CareTasksNotifier({
    required CareTasksRepository repository,
    required String residentId,
  })  : _repository = repository,
        _residentId = residentId,
        super(const CareTasksState(isLoading: true)) {
    loadTasks();
  }

  @override
  void dispose() {
    if (_activeGenerationCompleter != null &&
        !_activeGenerationCompleter!.isCompleted) {
      _activeGenerationCompleter!.complete(null);
    }
    super.dispose();
  }

  Future<void> loadTasks() async {
    final loadToken = ++_loadTasksToken;
    state = state.copyWith(isLoading: true);
    try {
      final items = await _repository.getTasks(_residentId);
      if (!mounted || loadToken != _loadTasksToken) return;
      state = state.copyWith(tasks: items, isLoading: false);
    } catch (e) {
      if (!mounted || loadToken != _loadTasksToken) return;
      state = state.copyWith(
        isLoading: false,
        generationError: e.toString(),
      );
    }
  }

  void setCategoryFilter(TaskCategory? category) {
    if (state.selectedCategory == category) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategory: category);
    }
  }

  Future<void> addTask(CareTask task) async {
    final created = await _repository.createTask(_residentId, task);
    if (!mounted) return;
    state = state.copyWith(tasks: [...state.tasks, created]);
  }

  Future<void> updateStatus({
    required String taskId,
    required TaskStatus status,
    String? completedBy,
    String? note,
    String? skipReason,
  }) async {
    final updated = await _repository.updateTaskStatus(
      residentId: _residentId,
      taskId: taskId,
      status: status,
      completedBy: completedBy,
      note: note,
      skipReason: skipReason,
    );
    if (!mounted) return;
    final newTasks =
        state.tasks.map((t) => t.id == taskId ? updated : t).toList();
    state = state.copyWith(tasks: newTasks);
  }

  Future<RegimenPlan?> generateRegimen({
    required Resident resident,
    DateTime? weekStartDate,
    bool autoApply = false,
    bool forceBaseline = false,
  }) async {
    final completer = Completer<RegimenPlan?>();
    if (_activeGenerationCompleter != null &&
        !_activeGenerationCompleter!.isCompleted) {
      _activeGenerationCompleter!.complete(null);
    }
    _activeGenerationCompleter = completer;

    final token = ++_generationToken;
    _runGeneration(
      token: token,
      completer: completer,
      resident: resident,
      weekStartDate: weekStartDate,
      autoApply: autoApply,
      forceBaseline: forceBaseline,
    );
    return completer.future;
  }

  Future<void> _runGeneration({
    required int token,
    required Completer<RegimenPlan?> completer,
    required Resident resident,
    DateTime? weekStartDate,
    required bool autoApply,
    required bool forceBaseline,
  }) async {
    state = state.copyWith(
      isGenerating: true,
      generationPhase: RegimenGenerationPhase.retrieval,
      clearError: true,
    );

    try {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted || token != _generationToken) {
        if (!mounted && !completer.isCompleted) completer.complete(null);
        return;
      }
      state = state.copyWith(generationPhase: RegimenGenerationPhase.synthesis);

      final plan = await _repository.generateWeeklyRegimen(
        resident: resident,
        weekStartDate: weekStartDate,
        autoApply: autoApply,
        forceBaseline: forceBaseline,
      );
      if (!mounted || token != _generationToken) {
        if (!mounted && !completer.isCompleted) completer.complete(null);
        return;
      }

      state = state.copyWith(generationPhase: RegimenGenerationPhase.scoring);
      await Future.delayed(const Duration(milliseconds: 40));
      if (!mounted || token != _generationToken) {
        if (!mounted && !completer.isCompleted) completer.complete(null);
        return;
      }

      state = state.copyWith(
        isGenerating: false,
        generationPhase: RegimenGenerationPhase.completed,
        activePreviewPlan: autoApply ? null : plan,
        latestAppliedPlan: autoApply ? plan : state.latestAppliedPlan,
        clearPreviewPlan: autoApply,
      );
      if (autoApply) {
        await loadTasks();
      }
      if (!completer.isCompleted) completer.complete(plan);
    } catch (e, st) {
      if (!mounted || token != _generationToken) {
        if (!mounted && !completer.isCompleted) completer.complete(null);
        return;
      }
      state = state.copyWith(
        isGenerating: false,
        generationPhase: RegimenGenerationPhase.idle,
        generationError: e.toString(),
      );
      if (!completer.isCompleted) completer.completeError(e, st);
    }
  }

  Future<RegimenPlan?> cancelAndSwitchToBaseline(Resident resident) async {
    final sharedCompleter = _activeGenerationCompleter;
    final token = ++_generationToken;
    final baselineCompleter = Completer<RegimenPlan?>();
    _activeGenerationCompleter = baselineCompleter;
    unawaited(_runGeneration(
      token: token,
      completer: baselineCompleter,
      resident: resident,
      autoApply: false,
      forceBaseline: true,
    ));
    try {
      final plan = await baselineCompleter.future;
      if (sharedCompleter != null && !sharedCompleter.isCompleted) {
        sharedCompleter.complete(plan);
      }
      return plan;
    } catch (e, st) {
      if (sharedCompleter != null && !sharedCompleter.isCompleted) {
        sharedCompleter.completeError(e, st);
      }
      rethrow;
    }
  }

  Future<RegimenPlan?> refineRegimen(
    String planId,
    String instruction, {
    DateTime? weekStartDate,
  }) async {
    if (_activeGenerationCompleter != null &&
        !_activeGenerationCompleter!.isCompleted) {
      _activeGenerationCompleter!.complete(null);
    }
    final token = ++_generationToken;
    state = state.copyWith(
      isGenerating: true,
      generationPhase: RegimenGenerationPhase.refinement,
      clearError: true,
    );

    try {
      final refined = await _repository.refineRegimen(
        residentId: _residentId,
        planId: planId,
        instruction: instruction,
        weekStartDate: weekStartDate,
      );
      if (!mounted || token != _generationToken) return null;

      state = state.copyWith(
        isGenerating: false,
        generationPhase: RegimenGenerationPhase.completed,
        activePreviewPlan: refined,
      );
      return refined;
    } catch (e) {
      if (!mounted || token != _generationToken) return null;
      state = state.copyWith(
        isGenerating: false,
        generationPhase: RegimenGenerationPhase.idle,
        generationError: e.toString(),
      );
      rethrow;
    }
  }

  Future<RegimenPlan?> applyRegimen(
    String planId, {
    DateTime? weekStartDate,
    bool acknowledgeLowScore = false,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final applied = await _repository.applyRegimen(
        residentId: _residentId,
        planId: planId,
        weekStartDate: weekStartDate,
        acknowledgeLowScore: acknowledgeLowScore,
      );
      if (!mounted) return null;
      state = state.copyWith(
        isLoading: false,
        clearPreviewPlan: true,
        latestAppliedPlan: applied,
        generationPhase: RegimenGenerationPhase.idle,
      );
      await loadTasks();
      return applied;
    } catch (e) {
      if (!mounted) return null;
      state = state.copyWith(
        isLoading: false,
        generationError: e.toString(),
      );
      rethrow;
    }
  }

  void clearPreview() {
    state = state.copyWith(
      clearPreviewPlan: true,
      generationPhase: RegimenGenerationPhase.idle,
      clearError: true,
    );
  }
}

final careTasksProvider =
    StateNotifierProvider<CareTasksNotifier, CareTasksState>((ref) {
  final repo = ref.watch(careTasksRepositoryProvider);
  final residentId = ref.watch(residentProvider.select((r) => r.id));
  return CareTasksNotifier(repository: repo, residentId: residentId);
});
