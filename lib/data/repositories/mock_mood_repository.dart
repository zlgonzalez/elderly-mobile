import '../../domain/entities/mood_entry.dart';
import 'mood_repository.dart';

// [MICROSERVICE_INTEGRATION_POINT]: MoodService - Mock Implementation
// Simulates /api/v1/residents/{residentId}/moods endpoints
class MockMoodRepository implements MoodRepository {
  final Map<String, List<MoodEntry>> _store = {};

  MockMoodRepository() {
    _initDefaultMoods();
  }

  void _initDefaultMoods() {
    _store['res_margaret'] = [
      MoodEntry(
        id: 'mood_1',
        residentId: 'res_margaret',
        mood: MoodType.happy,
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        recordedBy: 'Sarah Thompson',
        notes: 'Smiled warmly while browsing old wedding photos and listening to jazz.',
      ),
      MoodEntry(
        id: 'mood_2',
        residentId: 'res_margaret',
        mood: MoodType.content,
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
        recordedBy: 'Nurse Jane',
        notes: 'Calm and engaged after afternoon tea in the courtyard.',
      ),
      MoodEntry(
        id: 'mood_3',
        residentId: 'res_margaret',
        mood: MoodType.anxious,
        timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 6)),
        recordedBy: 'Sarah Thompson',
        notes: 'Slightly restless before dinner. Settled after listening to classical music.',
      ),
    ];

    // res_robert has empty mood entries to test empty state
    _store['res_robert'] = [];

    _store['res_dorothy'] = [
      MoodEntry(
        id: 'mood_dor_1',
        residentId: 'res_dorothy',
        mood: MoodType.happy,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        recordedBy: 'Nurse Jane',
        notes: 'Enjoyed gardening activity.',
      ),
    ];
  }

  void resetToDemo(String residentId) {
    _initDefaultMoods();
  }

  @override
  Future<List<MoodEntry>> getMoods(String residentId) async {
    return List.from(_store[residentId] ?? []);
  }

  @override
  Future<MoodEntry> logMood(String residentId, MoodEntry mood) async {
    final list = _store.putIfAbsent(residentId, () => []);
    final newEntry = MoodEntry(
      id: mood.id.isEmpty ? 'mood_${DateTime.now().millisecondsSinceEpoch}' : mood.id,
      residentId: residentId,
      mood: mood.mood,
      timestamp: mood.timestamp,
      recordedBy: mood.recordedBy,
      notes: mood.notes,
    );
    list.insert(0, newEntry);
    return newEntry;
  }
}
