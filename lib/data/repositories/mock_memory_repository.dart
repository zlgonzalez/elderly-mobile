import '../../domain/entities/memory_item.dart';
import 'memory_repository.dart';

// [MICROSERVICE_INTEGRATION_POINT]: MemoryService - Mock Implementation
// Simulates /api/v1/residents/{residentId}/memories endpoints
class MockMemoryRepository implements MemoryRepository {
  final Map<String, List<MemoryItem>> _store = {};

  MockMemoryRepository() {
    _initDefaultMemories();
  }

  void _initDefaultMemories() {
    _store['res_margaret'] = [
      MemoryItem(
        id: 'mem_1',
        residentId: 'res_margaret',
        format: MemoryFormat.photo,
        title: 'Wedding Day 1965',
        content: 'Married Harold Thompson at First Congregational Church, Burlington. A bright June afternoon surrounded by family and wildflowers.',
        mediaUrl: '/api/v1/media/memories/wedding_1965.png',
        date: DateTime(1965, 6, 12),
        sharedBy: 'Harold Thompson',
        tags: ['#wedding', '#family', '#milestone'],
      ),
      MemoryItem(
        id: 'mem_2',
        residentId: 'res_margaret',
        format: MemoryFormat.story,
        title: 'Teaching Career',
        content: '35 years of teaching early elementary students at Oakridge. Margaret nurtured generations with gentle patience and a passion for nature walks.',
        mediaUrl: null,
        date: DateTime(1968, 9, 1),
        sharedBy: 'Margaret Thompson',
        tags: ['#teaching', '#career', '#school'],
      ),
      MemoryItem(
        id: 'mem_3',
        residentId: 'res_margaret',
        format: MemoryFormat.photo,
        title: 'Garden in Full Bloom',
        content: 'Summer hydrangeas, heirloom tomatoes, and sweet peas in the backyard garden that Arthur and Margaret tended for decades.',
        mediaUrl: '/api/v1/media/memories/garden_bloom.png',
        date: DateTime(1985, 7, 15),
        sharedBy: 'Sarah Thompson',
        tags: ['#garden', '#flowers', '#nature'],
      ),
      MemoryItem(
        id: 'mem_4',
        residentId: 'res_margaret',
        format: MemoryFormat.letter,
        title: 'Letter from Granddaughter',
        content: 'Dear Nana, thank you for reading Charlotte\'s Web with me every summer under the big willow tree. I love you so much!',
        mediaUrl: null,
        date: DateTime(2012, 5, 10),
        sharedBy: 'Emily (Granddaughter)',
        tags: ['#letter', '#family', '#love'],
      ),
      MemoryItem(
        id: 'mem_5',
        residentId: 'res_margaret',
        format: MemoryFormat.video,
        title: 'Summer at Lake Champlain',
        content: 'Short family clip of the 1978 family picnic by the lake shore with cousins skipping stones at sunset.',
        mediaUrl: '/api/v1/media/memories/autumn_walk.png',
        date: DateTime(1978, 8, 20),
        sharedBy: 'Harold Thompson',
        tags: ['#summer', '#lake', '#family'],
      ),
    ];

    _store['res_robert'] = [
      MemoryItem(
        id: 'mem_rob_1',
        residentId: 'res_robert',
        format: MemoryFormat.photo,
        title: 'First Solo Flight 1968',
        content: 'Standing proudly beside the Cessna after earning pilot certificate.',
        mediaUrl: '/api/v1/media/memories/teaching_1968.png',
        date: DateTime(1968, 5, 14),
        sharedBy: 'Robert Chen',
        tags: ['#aviation', '#milestone'],
      ),
    ];

    _store['res_dorothy'] = [
      MemoryItem(
        id: 'mem_dor_1',
        residentId: 'res_dorothy',
        format: MemoryFormat.photo,
        title: 'Spring Garden Harvest',
        content: 'Basket of fresh raspberries and mint from the community allotment.',
        mediaUrl: '/api/v1/media/memories/garden_bloom.png',
        date: DateTime(1995, 6, 20),
        sharedBy: 'Dorothy Williams',
        tags: ['#gardening', '#harvest'],
      ),
    ];
  }

  void resetToDemo(String residentId) {
    _initDefaultMemories();
  }

  @override
  Future<List<MemoryItem>> getMemories(String residentId) async {
    // Return copies to avoid external mutation
    return List.from(_store[residentId] ?? []);
  }

  @override
  Future<MemoryItem> createMemory(String residentId, MemoryItem memory) async {
    final list = _store.putIfAbsent(residentId, () => []);
    final newMemory = memory.copyWith(
      id: memory.id.isEmpty ? 'mem_${DateTime.now().millisecondsSinceEpoch}' : memory.id,
      residentId: residentId,
    );
    list.insert(0, newMemory);
    return newMemory;
  }

  @override
  Future<bool> deleteMemory(String residentId, String memoryId) async {
    final list = _store[residentId];
    if (list == null) return false;
    list.removeWhere((item) => item.id == memoryId);
    return true;
  }
}
