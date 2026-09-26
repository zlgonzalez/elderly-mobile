import 'package:flutter_test/flutter_test.dart';
import 'package:elderly_mobile/data/repositories/mock_care_tasks_repository.dart';
import 'package:elderly_mobile/domain/entities/care_task.dart';

void main() {
  group('MockCareTasksRepository Tests', () {
    late MockCareTasksRepository repository;

    setUp(() {
      repository = MockCareTasksRepository();
    });

    test('getTasks returns initial tasks for Margaret', () async {
      final tasks = await repository.getTasks('res_margaret');
      expect(tasks.length, 3);

      final morningWalk = tasks.firstWhere((t) => t.title == 'Morning Garden Walk');
      expect(morningWalk.status, TaskStatus.completed);
      expect(morningWalk.completedBy, 'Nurse Jane');
      expect(morningWalk.category, TaskCategory.physical);

      final foldingLaundry = tasks.firstWhere((t) => t.title == 'Folding Laundry');
      expect(foldingLaundry.status, TaskStatus.pending);
      expect(foldingLaundry.category, TaskCategory.purposeful);
    });

    test('updateTaskStatus marks task completed with attribution and notes', () async {
      final updated = await repository.updateTaskStatus(
        residentId: 'res_margaret',
        taskId: 'task_2',
        status: TaskStatus.completed,
        completedBy: 'Sarah Thompson',
        note: 'Folded 8 towels together happily',
      );

      expect(updated.status, TaskStatus.completed);
      expect(updated.completedBy, 'Sarah Thompson');
      expect(updated.completionNote, 'Folded 8 towels together happily');

      final tasks = await repository.getTasks('res_margaret');
      final saved = tasks.firstWhere((t) => t.id == 'task_2');
      expect(saved.status, TaskStatus.completed);
      expect(saved.completedBy, 'Sarah Thompson');
    });

    test('createTask adds new activity to the schedule', () async {
      const newTask = CareTask(
        id: 'task_new',
        residentId: 'res_margaret',
        title: 'Afternoon Tea & Poetry',
        description: 'Reading Emily Dickinson poems while enjoying herbal tea.',
        time: '03:30 PM',
        category: TaskCategory.activity,
      );

      final created = await repository.createTask('res_margaret', newTask);
      expect(created.title, 'Afternoon Tea & Poetry');

      final tasks = await repository.getTasks('res_margaret');
      expect(tasks.length, 4);
      expect(tasks.any((t) => t.title == 'Afternoon Tea & Poetry'), isTrue);
    });
  });
}
