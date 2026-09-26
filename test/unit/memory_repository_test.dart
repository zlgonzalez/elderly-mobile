import 'package:flutter_test/flutter_test.dart';
import 'package:elderly_mobile/data/repositories/mock_memory_repository.dart';
import 'package:elderly_mobile/domain/entities/memory_item.dart';

void main() {
  group('MockMemoryRepository Tests', () {
    late MockMemoryRepository repository;

    setUp(() {
      repository = MockMemoryRepository();
    });

    test('getMemories returns pre-loaded memories for Margaret', () async {
      final memories = await repository.getMemories('res_margaret');
      expect(memories.length, greaterThanOrEqualTo(5));

      final titles = memories.map((m) => m.title).toList();
      expect(titles, contains('Wedding Day 1965'));
      expect(titles, contains('Teaching Career'));
      expect(titles, contains('Garden in Full Bloom'));
      expect(titles, contains('Letter from Granddaughter'));
      expect(titles, contains('Summer at Lake Champlain'));
    });

    test('createMemory adds a new memory item and persists in store', () async {
      final newMemory = MemoryItem(
        id: 'mem_test',
        residentId: 'res_margaret',
        format: MemoryFormat.photo,
        title: 'New Family Trip',
        date: DateTime(2023, 1, 1),
        sharedBy: 'Sarah Thompson',
        tags: ['#trip', '#family'],
      );

      final created = await repository.createMemory('res_margaret', newMemory);
      expect(created.title, 'New Family Trip');

      final updated = await repository.getMemories('res_margaret');
      expect(updated.first.title, 'New Family Trip');
    });

    test('deleteMemory removes existing item', () async {
      final memoriesBefore = await repository.getMemories('res_margaret');
      final firstId = memoriesBefore.first.id;

      final deleted = await repository.deleteMemory('res_margaret', firstId);
      expect(deleted, isTrue);

      final memoriesAfter = await repository.getMemories('res_margaret');
      expect(memoriesAfter.any((m) => m.id == firstId), isFalse);
    });

    test('resetToDemo restores default memories', () async {
      await repository.deleteMemory('res_margaret', 'mem_1');
      repository.resetToDemo('res_margaret');

      final restored = await repository.getMemories('res_margaret');
      expect(restored.any((m) => m.id == 'mem_1'), isTrue);
    });
  });
}
