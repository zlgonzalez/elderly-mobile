import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/care_tasks_repository.dart';
import '../../domain/entities/care_task.dart';
import '../family_portal/resident_provider.dart';

class CareTasksState {
  final List<CareTask> tasks;
  final bool isLoading;
  final TaskCategory? selectedCategory;

  const CareTasksState({
    this.tasks = const [],
    this.isLoading = false,
    this.selectedCategory,
  });

  int get totalCount => tasks.length;
  int get completedCount => tasks.where((t) => t.status == TaskStatus.completed).length;
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
  }) {
    return CareTasksState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      selectedCategory: clearCategory ? null : (selectedCategory ?? this.selectedCategory),
    );
  }
}

class CareTasksNotifier extends StateNotifier<CareTasksState> {
  final CareTasksRepository _repository;
  final String _residentId;

  CareTasksNotifier({
    required CareTasksRepository repository,
    required String residentId,
  })  : _repository = repository,
        _residentId = residentId,
        super(const CareTasksState(isLoading: true)) {
    loadTasks();
  }

  Future<void> loadTasks() async {
    state = state.copyWith(isLoading: true);
    final items = await _repository.getTasks(_residentId);
    state = state.copyWith(tasks: items, isLoading: false);
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
    state = state.copyWith(tasks: [...state.tasks, created]);
  }

  Future<void> updateStatus({
    required String taskId,
    required TaskStatus status,
    String? completedBy,
    String? note,
  }) async {
    final updated = await _repository.updateTaskStatus(
      residentId: _residentId,
      taskId: taskId,
      status: status,
      completedBy: completedBy,
      note: note,
    );
    final newTasks = state.tasks.map((t) => t.id == taskId ? updated : t).toList();
    state = state.copyWith(tasks: newTasks);
  }
}

final careTasksProvider = StateNotifierProvider<CareTasksNotifier, CareTasksState>((ref) {
  final repo = ref.watch(careTasksRepositoryProvider);
  final resident = ref.watch(residentProvider);
  return CareTasksNotifier(repository: repo, residentId: resident.id);
});
