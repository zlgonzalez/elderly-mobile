import '../../domain/entities/care_task.dart';
import 'care_tasks_repository.dart';

// [MICROSERVICE_INTEGRATION_POINT]: CareService - Mock Implementation
// Simulates /api/v1/residents/{residentId}/tasks endpoints
class MockCareTasksRepository implements CareTasksRepository {
  final Map<String, List<CareTask>> _store = {};

  MockCareTasksRepository() {
    _initDefaultTasks();
  }

  void _initDefaultTasks() {
    _store['res_margaret'] = [
      const CareTask(
        id: 'task_1',
        residentId: 'res_margaret',
        title: 'Morning Garden Walk',
        description: 'Gentle walk in the sensory courtyard. Focus on touch, scent of herbs, and bird sounds.',
        time: '09:00 AM',
        category: TaskCategory.physical,
        status: TaskStatus.completed,
        completedBy: 'Nurse Jane',
        completionNote: 'Enjoyed the sunshine, watered tomatoes and roses',
      ),
      const CareTask(
        id: 'task_2',
        residentId: 'res_margaret',
        title: 'Folding Laundry',
        description: 'Folding towels and napkins together. Provides purposeful, tactile coordination and sense of contribution.',
        time: '02:00 PM',
        category: TaskCategory.purposeful,
        status: TaskStatus.pending,
      ),
      const CareTask(
        id: 'task_3',
        residentId: 'res_margaret',
        title: 'Music Reminiscence Session',
        description: 'Listening to 1950s Big Band and jazz records in the sunroom. Sparking reminiscence and emotional ease.',
        time: '04:00 PM',
        category: TaskCategory.social,
        status: TaskStatus.pending,
      ),
    ];

    _store['res_robert'] = [
      const CareTask(
        id: 'task_rob_1',
        residentId: 'res_robert',
        title: 'Model Airplane Assembly',
        description: 'Tactile assembly of wooden model wings.',
        time: '10:30 AM',
        category: TaskCategory.purposeful,
        status: TaskStatus.pending,
      ),
    ];

    _store['res_dorothy'] = [
      const CareTask(
        id: 'task_dor_1',
        residentId: 'res_dorothy',
        title: 'Herbal Tea Preparation',
        description: 'Selecting dried chamomile and lavender leaves.',
        time: '03:00 PM',
        category: TaskCategory.activity,
        status: TaskStatus.pending,
      ),
    ];
  }

  void resetToDemo(String residentId) {
    _initDefaultTasks();
  }

  @override
  Future<List<CareTask>> getTasks(String residentId) async {
    return List.from(_store[residentId] ?? []);
  }

  @override
  Future<CareTask> createTask(String residentId, CareTask task) async {
    final list = _store.putIfAbsent(residentId, () => []);
    final newTask = task.copyWith(
      id: task.id.isEmpty ? 'task_${DateTime.now().millisecondsSinceEpoch}' : task.id,
      residentId: residentId,
    );
    list.add(newTask);
    return newTask;
  }

  @override
  Future<CareTask> updateTaskStatus({
    required String residentId,
    required String taskId,
    required TaskStatus status,
    String? completedBy,
    String? note,
  }) async {
    final list = _store[residentId];
    if (list == null) {
      throw Exception('Resident tasks not found');
    }
    final index = list.indexWhere((t) => t.id == taskId);
    if (index == -1) {
      throw Exception('Task not found: $taskId');
    }

    final updated = list[index].copyWith(
      status: status,
      completedBy: completedBy ?? list[index].completedBy,
      completionNote: note ?? list[index].completionNote,
    );
    list[index] = updated;
    return updated;
  }
}
