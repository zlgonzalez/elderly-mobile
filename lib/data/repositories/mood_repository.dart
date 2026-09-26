import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/mood_entry.dart';
import 'mock_mood_repository.dart';

// [MICROSERVICE_INTEGRATION_POINT]: MoodService - History API
// Contract: GET /api/v1/residents/{residentId}/moods
// Contract: POST /api/v1/residents/{residentId}/moods
abstract class MoodRepository {
  Future<List<MoodEntry>> getMoods(String residentId);
  Future<MoodEntry> logMood(String residentId, MoodEntry mood);
}

final moodRepositoryProvider = Provider<MoodRepository>((ref) {
  // In production, when USE_MOCK_DATA is false, connect to real microservice
  return MockMoodRepository();
});
